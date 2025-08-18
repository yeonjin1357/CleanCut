import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionService {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await Permission.storage.status;
      
      if (androidInfo != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        return result == PermissionStatus.granted;
      }
      return true;
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status == PermissionStatus.granted;
    }
    return false;
  }

  static Future<bool> requestPhotoLibraryPermission() async {
    if (Platform.isAndroid) {
      final sdkInt = await _getAndroidSdkInt();
      if (sdkInt >= 33) {
        final status = await Permission.photos.request();
        return status == PermissionStatus.granted;
      } else {
        return await requestStoragePermission();
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status == PermissionStatus.granted;
    }
    return false;
  }

  static Future<bool> checkAndRequestPermissions({
    required BuildContext context,
    required List<Permission> permissions,
  }) async {
    Map<Permission, PermissionStatus> statuses = {};
    
    for (var permission in permissions) {
      statuses[permission] = await permission.status;
    }

    List<Permission> deniedPermissions = [];
    
    for (var entry in statuses.entries) {
      if (entry.value != PermissionStatus.granted) {
        deniedPermissions.add(entry.key);
      }
    }

    if (deniedPermissions.isEmpty) {
      return true;
    }

    Map<Permission, PermissionStatus> results = 
        await deniedPermissions.request();

    bool allGranted = true;
    for (var status in results.values) {
      if (status != PermissionStatus.granted) {
        allGranted = false;
        break;
      }
    }

    if (!allGranted && context.mounted) {
      await _showPermissionDialog(context);
    }

    return allGranted;
  }

  static Future<void> _showPermissionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('권한 필요'),
          content: const Text(
            '이 기능을 사용하려면 권한이 필요합니다.\n'
            '설정에서 권한을 허용해주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('설정으로 이동'),
            ),
          ],
        );
      },
    );
  }

  static Future<int> _getAndroidSdkInt() async {
    if (Platform.isAndroid) {
      try {
        final ProcessResult result = await Process.run('getprop', ['ro.build.version.sdk']);
        return int.tryParse(result.stdout.toString().trim()) ?? 0;
      } catch (e) {
        debugPrint('Error getting Android SDK version: $e');
        return 0;
      }
    }
    return 0;
  }

  static Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      final sdkInt = await _getAndroidSdkInt();
      if (sdkInt >= 33) {
        final status = await Permission.photos.status;
        return status == PermissionStatus.granted;
      } else {
        final status = await Permission.storage.status;
        return status == PermissionStatus.granted;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.status;
      return status == PermissionStatus.granted;
    }
    return false;
  }

  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status == PermissionStatus.granted;
  }
}