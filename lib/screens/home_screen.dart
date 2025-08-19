import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/permission_service.dart';
import '../services/ad_service.dart';
import '../widgets/loading_overlay.dart';
import '../utils/app_theme.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final AdService _adService = AdService();
  bool _isProcessing = false;
  int _processCount = 0;

  @override
  void initState() {
    super.initState();
    // 배너 광고 로드 및 상태 업데이트
    _loadAds();
  }

  Future<void> _loadAds() async {
    // 잠시 기다린 후 광고 로드 상태 확인
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {});
    }

    // 광고 로드 상태를 주기적으로 확인
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromFilePicker() async {
    try {
      // 파일 선택
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final File imageFile = File(result.files.single.path!);

        setState(() {
          _isProcessing = true;
        });

        // API 호출
        final apiService = ApiService();
        final processedImage = await apiService.removeBackground(imageFile);

        if (processedImage != null && mounted) {
          // 전면 광고 표시 (3번에 1번)
          _processCount++;
          if (_processCount % 3 == 0) {
            await _adService.showInterstitialAd();
          }

          // 결과 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditorScreen(
                originalImage: imageFile,
                processedImage: processedImage,
              ),
            ),
          );
        } else if (mounted) {
          _showErrorSnackBar('배경 제거에 실패했습니다');
        }

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showErrorSnackBar('오류가 발생했습니다: ${e.toString()}');
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // 권한 체크
      bool hasPermission = false;

      if (source == ImageSource.camera) {
        // 카메라 권한 체크
        hasPermission = await PermissionService.checkAndRequestPermissions(
          context: context,
          permissions: [Permission.camera],
        );
      } else {
        // 갤러리 권한 체크
        if (Platform.isAndroid) {
          final sdkInt = await _getAndroidSdkInt();
          if (sdkInt >= 33) {
            hasPermission = await PermissionService.checkAndRequestPermissions(
              context: context,
              permissions: [Permission.photos],
            );
          } else {
            hasPermission = await PermissionService.checkAndRequestPermissions(
              context: context,
              permissions: [Permission.storage],
            );
          }
        } else {
          hasPermission = await PermissionService.checkAndRequestPermissions(
            context: context,
            permissions: [Permission.photos],
          );
        }
      }

      if (!hasPermission) {
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 100,
        requestFullMetadata: true, // 전체 메타데이터 요청
      );

      if (image != null) {
        setState(() {
          _isProcessing = true;
        });

        // 이미지 크기 체크 및 리사이징
        File imageFile = File(image.path);
        
        try {
          // 이미지 읽기
          final bytes = await imageFile.readAsBytes();
          final decodedImage = await decodeImageFromList(bytes);
          
          // 최소 크기 체크
          if (decodedImage.width < AppConfig.minImageSize || 
              decodedImage.height < AppConfig.minImageSize) {
            setState(() {
              _isProcessing = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('이미지가 너무 작습니다 (최소 ${AppConfig.minImageSize}x${AppConfig.minImageSize}px)'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          
          // 크기가 너무 크면 리사이징
          if (decodedImage.width > AppConfig.maxImageWidth || 
              decodedImage.height > AppConfig.maxImageHeight) {
            // 리사이징 필요
            final img.Image? originalImage = img.decodeImage(bytes);
            if (originalImage != null) {
              // 비율 유지하면서 리사이징
              img.Image resized;
              if (originalImage.width > originalImage.height) {
                resized = img.copyResize(originalImage, width: AppConfig.targetImageSize);
              } else {
                resized = img.copyResize(originalImage, height: AppConfig.targetImageSize);
              }
              
              // 임시 파일로 저장
              final tempFile = File('${imageFile.path}_resized.jpg');
              await tempFile.writeAsBytes(img.encodeJpg(resized, quality: 95));
              imageFile = tempFile;
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('큰 이미지를 자동으로 조정했습니다'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          }
        } catch (e) {
          setState(() {
            _isProcessing = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('이미지 처리 실패: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // API 호출하여 배경 제거
        final apiService = ApiService();
        final processedImage = await apiService.removeBackground(imageFile);

        setState(() {
          _isProcessing = false;
        });

        if (mounted && processedImage != null) {
          // 전면 광고 표시 (3번에 1번)
          _processCount++;
          if (_processCount % 3 == 0 && _adService.isInterstitialAdReady) {
            await _adService.showInterstitialAd();
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditorScreen(
                originalImage: File(image.path),
                processedImage: processedImage,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<int> _getAndroidSdkInt() async {
    if (Platform.isAndroid) {
      try {
        final ProcessResult result = await Process.run('getprop', [
          'ro.build.version.sdk',
        ]);
        return int.tryParse(result.stdout.toString().trim()) ?? 0;
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: LoadingOverlay(
        isLoading: _isProcessing,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // 상단 타이틀
                      const SizedBox(height: 20),
                      Text(
                        'CleanCut',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),

                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 메인 업로드 카드
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/icons/app_icon_square.svg',
                                      width: 80,
                                      height: 80,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    '완벽한 배경 제거',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '자동으로 배경을 제거해드려요',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // 갤러리 버튼
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _pickImage(ImageSource.gallery),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.photo_library_outlined,
                                            size: 22,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            '사진 선택하기',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // 카메라 버튼
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _pickImage(ImageSource.camera),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.camera_alt_outlined,
                                            size: 24,
                                            color: AppTheme.primaryColor,
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            '카메라로 촬영',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // 파일 탐색기 버튼 (더 많은 폴더 접근)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: OutlinedButton(
                                      onPressed: _pickImageFromFilePicker,
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.folder_open_outlined,
                                            size: 22,
                                            color: AppTheme.primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '모든 폴더에서 선택',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 하단 특징 표시
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildFeatureChip(Icons.bolt, '빠른 처리'),
                                const SizedBox(width: 16),
                                _buildFeatureChip(Icons.auto_awesome, '높은 정확도'),
                                const SizedBox(width: 16),
                                _buildFeatureChip(Icons.download, '무료 저장'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 배너 광고 영역
              if (_adService.isBannerAdReady)
                Container(
                  alignment: Alignment.center,
                  color: Colors.white,
                  width: MediaQuery.of(context).size.width,
                  height: 60,
                  child:
                      _adService.getBannerAdWidget() ?? const SizedBox.shrink(),
                )
              else
                Container(
                  height: 60,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text(
                      '광고 로딩 중...',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
