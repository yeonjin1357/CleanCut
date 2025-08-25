import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_view/photo_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import '../services/permission_service.dart';
import '../services/ad_service.dart';
import '../utils/app_theme.dart';

class EditorScreen extends StatefulWidget {
  final File originalImage;
  final Uint8List processedImage;

  const EditorScreen({
    super.key,
    required this.originalImage,
    required this.processedImage,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  bool _showOriginal = false;
  bool _isSaving = false;
  final AdService _adService = AdService();
  int _rotationAngle = 0; // 0, 90, 180, 270
  Uint8List? _rotatedImage;
  Uint8List? _rotatedOriginalImage;
  bool _isRotating = false;
  
  @override
  void initState() {
    super.initState();
    // 초기 이미지 설정
    _rotatedImage = widget.processedImage;
    _loadOriginalImageBytes();
    // 배너 광고 로드
    _loadAds();
  }

  Future<void> _loadOriginalImageBytes() async {
    try {
      final bytes = await widget.originalImage.readAsBytes();
      setState(() {
        _rotatedOriginalImage = bytes;
      });
    } catch (e) {
      print('Error loading original image bytes: $e');
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 적응형 배너 크기 업데이트
    _adService.updateAdaptiveBannerSize(context);
  }
  
  Future<void> _loadAds() async {
    // 적응형 배너 크기 설정 후 광고 로드
    await _adService.updateAdaptiveBannerSize(context);
    
    // 광고는 AdService에서 자동으로 미리 로드됨
    // 주기적으로 상태 업데이트
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {});
    });
  }

  Future<void> _rotateImage(bool clockwise) async {
    if (_isRotating) return;
    
    setState(() {
      _isRotating = true;
    });

    try {
      // 회전 각도 업데이트
      if (clockwise) {
        _rotationAngle = (_rotationAngle + 90) % 360;
      } else {
        _rotationAngle = (_rotationAngle - 90) % 360;
        if (_rotationAngle < 0) _rotationAngle += 360;
      }

      // 처리된 이미지 회전
      final processedImg = img.decodeImage(widget.processedImage);
      if (processedImg != null) {
        img.Image rotatedProcessed;
        
        // 누적 회전 각도에 따라 회전
        switch (_rotationAngle) {
          case 90:
            rotatedProcessed = img.copyRotate(processedImg, angle: 90);
            break;
          case 180:
            rotatedProcessed = img.copyRotate(processedImg, angle: 180);
            break;
          case 270:
            rotatedProcessed = img.copyRotate(processedImg, angle: 270);
            break;
          default:
            rotatedProcessed = processedImg;
        }
        
        _rotatedImage = Uint8List.fromList(img.encodePng(rotatedProcessed));
      }

      // 원본 이미지도 회전
      final originalBytes = await widget.originalImage.readAsBytes();
      final originalImg = img.decodeImage(originalBytes);
      if (originalImg != null) {
        img.Image rotatedOriginal;
        
        switch (_rotationAngle) {
          case 90:
            rotatedOriginal = img.copyRotate(originalImg, angle: 90);
            break;
          case 180:
            rotatedOriginal = img.copyRotate(originalImg, angle: 180);
            break;
          case 270:
            rotatedOriginal = img.copyRotate(originalImg, angle: 270);
            break;
          default:
            rotatedOriginal = originalImg;
        }
        
        // 원본 이미지는 JPG로 저장 (파일 크기 최적화)
        _rotatedOriginalImage = Uint8List.fromList(img.encodeJpg(rotatedOriginal, quality: 95));
      }
    } catch (e) {
      print('Error rotating image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회전 실패: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isRotating = false;
      });
    }
  }

  Future<void> _saveImage() async {
    setState(() => _isSaving = true);
    
    bool result = false;
    String message = '';

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'cleancut_$timestamp.png';

      // 플랫폼별 처리
      if (Platform.isAndroid || Platform.isIOS) {
        // 권한 체크
        bool hasPermission = false;

        if (Platform.isAndroid) {
          final sdkInt = await _getAndroidSdkInt();
          if (sdkInt >= 33) {
            // Android 13 이상은 권한 없이 MediaStore 사용 가능
            hasPermission = true;
          } else if (sdkInt >= 29) {
            // Android 10-12
            hasPermission = true;
          } else {
            // Android 9 이하
            hasPermission = await PermissionService.checkAndRequestPermissions(
              context: context,
              permissions: [Permission.storage],
            );
          }
        } else {
          // iOS
          hasPermission = await PermissionService.checkAndRequestPermissions(
            context: context,
            permissions: [Permission.photos],
          );
        }

        if (!hasPermission) {
          message = '저장 권한이 필요합니다';
        } else {
          // gal 패키지를 사용하여 갤러리에 직접 저장
          try {
            // 먼저 임시 파일로 저장
            final tempDir = await getTemporaryDirectory();
            final tempFile = File('${tempDir.path}/$fileName');
            await tempFile.writeAsBytes(_rotatedImage ?? widget.processedImage);

            // 갤러리에 저장
            await Gal.putImage(tempFile.path, album: 'CleanCut');

            // 임시 파일 삭제
            await tempFile.delete();

            result = true;
            message = '갤러리에 저장되었습니다';
          } catch (e) {
            message = '저장 실패: $e';
          }
        }
      } else {
        // Windows/Desktop: Downloads 폴더에 저장
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          final file = File('${downloadsDir.path}/$fileName');
          await file.writeAsBytes(_rotatedImage ?? widget.processedImage);
          result = true;
          message = 'Downloads 폴더에 저장되었습니다';
        }
      }

      // 저장 결과를 임시 저장
      final savedResult = result;
      final savedMessage = message;
      
      // 전면 광고 표시 시도 (광고가 닫힌 후 토스트 표시)
      if (_adService.isInterstitialAdReady) {
        await _adService.showInterstitialAd(
          onAdDismissed: () {
            // 광고가 닫힌 후 토스트 메시지 표시
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        savedResult ? Icons.check_circle : Icons.error,
                        color: Colors.white,
                      ),
                      SizedBox(width: 12),
                      Text(savedMessage),
                    ],
                  ),
                  backgroundColor: savedResult
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
        );
      } else {
        // 광고가 없으면 바로 토스트 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    savedResult ? Icons.check_circle : Icons.error,
                    color: Colors.white,
                  ),
                  SizedBox(width: 12),
                  Text(savedMessage),
                ],
              ),
              backgroundColor: savedResult
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _shareImage() async {
    // 전면 광고 표시 시도
    if (_adService.isInterstitialAdReady) {
      await _adService.showInterstitialAd();
      // 광고가 닫힐 때까지 잠시 대기
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/cleancut_$timestamp.png';

      final file = File(path);
      await file.writeAsBytes(widget.processedImage);

      await Share.shareXFiles([XFile(path)], text: 'CleanCut으로 제작');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('공유 실패: $e')));
      }
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
      body: SafeArea(
        child: Column(
          children: [
            // 커스텀 앱바
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  // 왼쪽: 다운로드 버튼
                  IconButton(
                    icon: Icon(
                      Icons.download_rounded,
                      size: 28,
                      color: _isSaving
                          ? AppTheme.textSecondary
                          : AppTheme.primaryColor,
                    ),
                    onPressed: _isSaving ? null : _saveImage,
                  ),
                  // 중앙: 제목
                  Expanded(
                    child: Text(
                      '편집 완료',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  // 오른쪽: 공유 버튼
                  IconButton(
                    icon: Icon(
                      Icons.share_rounded,
                      size: 28,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: _shareImage,
                  ),
                ],
              ),
            ),

            // 이미지 뷰어
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // 체크보드 패턴
                      if (!_showOriginal)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                  'assets/images/checkerboard.png',
                                ),
                                repeat: ImageRepeat.repeat,
                                opacity: 0.3,
                              ),
                            ),
                          ),
                        ),

                      // 이미지
                      PhotoView(
                        backgroundDecoration: BoxDecoration(
                          color: Colors.transparent,
                        ),
                        imageProvider: _showOriginal
                            ? (_rotatedOriginalImage != null 
                                ? MemoryImage(_rotatedOriginalImage!) 
                                : FileImage(widget.originalImage))
                                  as ImageProvider
                            : MemoryImage(_rotatedImage ?? widget.processedImage)
                                  as ImageProvider,
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 4,
                      ),

                      // 회전 버튼들
                      if (!_showOriginal)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 반시계 방향 회전
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: _isRotating ? null : () => _rotateImage(false),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Icon(
                                        Icons.rotate_left,
                                        size: 24,
                                        color: _isRotating 
                                            ? AppTheme.textSecondary 
                                            : AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              // 시계 방향 회전
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: _isRotating ? null : () => _rotateImage(true),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Icon(
                                        Icons.rotate_right,
                                        size: 24,
                                        color: _isRotating 
                                            ? AppTheme.textSecondary 
                                            : AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 원본/결과 전환 버튼
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                setState(() {
                                  _showOriginal = !_showOriginal;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _showOriginal
                                          ? Icons.image_outlined
                                          : Icons.compare,
                                      size: 18,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _showOriginal ? '원본' : '결과',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 배너 광고 영역 - 광고가 준비되면만 표시
            if (_adService.isEditorBannerAdReady)
              Container(
                height: 60,
                width: MediaQuery.of(context).size.width,
                color: Colors.white,
                child: _adService.getEditorBannerAdWidget() ?? const SizedBox.shrink(),
              ),
            
            // 하단 액션 버튼들
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_photo_alternate_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '홈 화면으로 이동',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
