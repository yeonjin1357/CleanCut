import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_view/photo_view.dart';

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

  Future<void> _saveImage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/cleancut_$timestamp.png';
      
      final file = File(path);
      await file.writeAsBytes(widget.processedImage);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지가 저장되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('결과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _saveImage,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareImage,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 체크보드 패턴 배경
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/checkerboard.png'),
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          // 이미지 뷰어
          PhotoView(
            backgroundDecoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            imageProvider: _showOriginal
                ? FileImage(widget.originalImage)
                : MemoryImage(widget.processedImage) as ImageProvider,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.black87,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showOriginal = !_showOriginal;
                });
              },
              icon: Icon(_showOriginal ? Icons.visibility_off : Icons.visibility),
              label: Text(_showOriginal ? '결과 보기' : '원본 보기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('새 이미지'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}