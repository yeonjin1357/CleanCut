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
      // Android: 포토 피커/SAF 사용으로 저장소 권한 불필요
      return true;
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status == PermissionStatus.granted;
    }
    return false;
  }

  static Future<bool> requestPhotoLibraryPermission() async {
    if (Platform.isAndroid) {
      // Android: 시스템 포토 피커/SAF로 권한 불필요
      return true;
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

    Map<Permission, PermissionStatus> results = await deniedPermissions
        .request();

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

  static Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      // Android: 포토 피커/SAF 사용으로 권한 체크 불필요
      return true;
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
