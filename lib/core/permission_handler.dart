import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AppPermissionHandler {
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Check if Android 13 or higher (SDK 33)
      // Note: This is a simplified check. In a real app, you'd use device info.
      // But READ_MEDIA_AUDIO is the correct permission for Android 13+.
      
      final status = await Permission.audio.status;
      if (status.isGranted) return true;
      
      final result = await Permission.audio.request();
      if (result.isGranted) return true;

      // Fallback for older Android versions
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.mediaLibrary.request();
      return status.isGranted;
    }
    return false;
  }
}
