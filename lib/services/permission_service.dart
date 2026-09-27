/// System Permission Handler by Shreesh Nalawade (shreeshnalawade9@gmail.com)
///
/// VisionBridge — Permission Servicer
///
/// Centralized permission management. Requests all required permissions
/// at the right time, not all at once on launch.
library;

import 'package:permission_handler/permission_handler.dart';

/// Groups of permissions needed at different stages.
enum PermissionGroup {
  camera,    // AI Assist screen
  microphone, // Voice commands + calls
  location,   // SOS
  notification, // FCM push
}

class PermissionService {
  /// Request a group of permissions.
  /// Returns true if ALL permissions in the group are granted.
  Future<bool> requestPermissionGroup(PermissionGroup group) async {
    switch (group) {
      case PermissionGroup.camera:
        return _requestPermissions([Permission.camera]);
      case PermissionGroup.microphone:
        return _requestPermissions([Permission.microphone]);
      case PermissionGroup.location:
        return _requestPermissions([
          Permission.location,
          Permission.locationWhenInUse,
        ]);
      case PermissionGroup.notification:
        return _requestPermissions([Permission.notification]);
    }
  }

  /// Request all permissions needed for AI Assist (camera + mic).
  Future<bool> requestAIAssistPermissions() async {
    return _requestPermissions([
      Permission.camera,
      Permission.microphone,
    ]);
  }

  /// Request all permissions needed for SOS (location + notification).
  Future<bool> requestSOSPermissions() async {
    return _requestPermissions([
      Permission.location,
      Permission.notification,
    ]);
  }

  /// Check if a permission group is already granted.
  Future<bool> isPermissionGroupGranted(PermissionGroup group) async {
    switch (group) {
      case PermissionGroup.camera:
        return Permission.camera.isGranted;
      case PermissionGroup.microphone:
        return Permission.microphone.isGranted;
      case PermissionGroup.location:
        return Permission.locationWhenInUse.isGranted;
      case PermissionGroup.notification:
        return Permission.notification.isGranted;
    }
  }

  /// Open app settings (for permanently denied permissions).
  Future<bool> openSettings() async {
    return openAppSettings();
  }

  Future<bool> _requestPermissions(List<Permission> permissions) async {
    final statuses = await permissions.request();
    return statuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );
  }
}
