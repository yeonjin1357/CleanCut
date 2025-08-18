import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_view/photo_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import '../services/permission_service.dart';
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

  Future<void> _saveImage() async {
    setState(() => _isSaving = true);
    
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'cleancut_$timestamp.png';
      bool result = false;
      String message = '';
      
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
            await tempFile.writeAsBytes(widget.processedImage);
            
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
          await file.writeAsBytes(widget.processedImage);
          result = true;
          message = 'Downloads 폴더에 저장되었습니다';
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(result ? Icons.check_circle : Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text(message),
              ],
            ),
            backgroundColor: result ? AppTheme.successColor : AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
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
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _shareImage() async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/cleancut_$timestamp.png';
      
      final file = File(path);
      await file.writeAsBytes(widget.processedImage);
      
      await Share.shareXFiles([XFile(path)], text: 'CleanCut으로 제작');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공유 실패: $e')),
        );
      }
    }
  }
  
  Future<int> _getAndroidSdkInt() async {
    if (Platform.isAndroid) {
      try {
        final ProcessResult result = await Process.run('getprop', ['ro.build.version.sdk']);
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
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, size: 24, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      '편집',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.download_rounded, 
                      size: 26,
                      color: _isSaving ? AppTheme.textSecondary : AppTheme.primaryColor,
                    ),
                    onPressed: _isSaving ? null : _saveImage,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.share_rounded,
                      size: 26,
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
                                image: AssetImage('assets/images/checkerboard.png'),
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
                            ? FileImage(widget.originalImage)
                            : MemoryImage(widget.processedImage) as ImageProvider,
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 4,
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
                            '새 이미지',
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