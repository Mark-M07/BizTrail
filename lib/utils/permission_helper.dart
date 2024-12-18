import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

/// Result class to hold permission check results
class PermissionCheckResult {
  final Map<Permission, PermissionStatus> statuses;
  final Map<Permission, bool> isPreciseLocationDeniedMap;

  PermissionCheckResult(this.statuses, this.isPreciseLocationDeniedMap);
}

class PermissionHelper {
  static const Duration resumeDelay = Duration(milliseconds: 500);

  static const MethodChannel _accuracyChannel =
      MethodChannel('com.biztrail.app/location_accuracy');

  /// List of all permissions required by the app
  static List<Permission> get requiredPermissions => [
        Permission.camera,
        Permission.locationWhenInUse,
      ];

  /// Check if precise location is denied
  static Future<bool> _checkPreciseLocationDenied() async {
    if (Platform.isIOS) {
      final accuracy =
          await _accuracyChannel.invokeMethod<String>('checkLocationAccuracy');
      return accuracy == 'reducedAccuracy';
    } else {
      final preciseStatus = await Permission.location.status;
      return !preciseStatus.isGranted;
    }
  }

  /// Loads and checks all permission statuses
  static Future<PermissionCheckResult> loadPermissionStatuses() async {
    // Get current statuses
    final statuses = await Future.wait(
      requiredPermissions.map((permission) => permission.status),
    );
    final Map<Permission, PermissionStatus> statusMap =
        Map.fromIterables(requiredPermissions, statuses);

    // Check precise location status
    final locationStatus = statusMap[Permission.locationWhenInUse];
    bool isPreciseDenied = false;

    if (locationStatus?.isGranted == true) {
      isPreciseDenied = await _checkPreciseLocationDenied();
    }

    final preciseLocationMap = {Permission.locationWhenInUse: isPreciseDenied};

    return PermissionCheckResult(statusMap, preciseLocationMap);
  }

  /// Checks if all required permissions are granted
  static Future<bool> checkAllPermissions() async {
    final result = await loadPermissionStatuses();
    return result.statuses.values.every((status) => status.isGranted) &&
        !result.isPreciseLocationDeniedMap.values.contains(true);
  }

  /// Request a specific permission and handle platform-specific requirements
  static Future<(PermissionStatus, bool)> requestPermission(
      Permission permission) async {
    if (permission == Permission.camera) {
      final status = await permission.request();
      return (status, false);
    } else if (permission == Permission.locationWhenInUse) {
      final locationStatus = await permission.request();
      if (!locationStatus.isGranted) {
        return (locationStatus, false);
      }

      if (!Platform.isIOS) {
        // On Android, also request precise location
        await Permission.location.request();
      }

      final isPreciseDenied = await _checkPreciseLocationDenied();
      return (locationStatus, isPreciseDenied);
    }

    throw ArgumentError('Unsupported permission type: $permission');
  }

  /// Gets platform-specific instructions for enabling camera permission
  static List<String> getCameraPermissionInstructions() {
    return Platform.isIOS
        ? [
            '1. Press "Open Settings"',
            '2. Enable "Camera"',
          ]
        : [
            '1. Press "Open Settings"',
            '2. Tap "Permissions"',
            '3. Select "Camera"',
            '4. Choose "Allow only while using the app"',
          ];
  }

  /// Gets platform-specific instructions for enabling precise location
  static List<String> getPreciseLocationInstructions() {
    return Platform.isIOS
        ? [
            '1. Press "Open Settings"',
            '2. Tap "Location"',
            '3. Enable "Precise Location"',
          ]
        : [
            '1. Press "Open Settings"',
            '2. Tap "Permissions"',
            '3. Select "Location"',
            '4. Ensure "Allow only while using the app" is selected',
            '5. Enable "Use precise location"',
          ];
  }

  /// Gets descriptive text for each permission type
  static String getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Required for scanning QR codes at business locations';
      case Permission.locationWhenInUse:
        return 'Required to verify your presence at business locations';
      default:
        return 'Permission description not available';
    }
  }

  /// Gets user-friendly title for each permission type
  static String getPermissionTitle(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera';
      case Permission.locationWhenInUse:
        return 'Precise Location';
      default:
        return permission.toString();
    }
  }

  /// Gets the color for a permission status
  static Color getStatusColor(
      PermissionStatus? status, bool isPreciseLocationDenied) {
    if (isPreciseLocationDenied) return Colors.red;
    if (status == null) return Colors.grey;

    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      case PermissionStatus.restricted:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Gets the display text for a permission status
  static String getStatusText(
      PermissionStatus? status, bool isPreciseLocationDenied) {
    if (status?.isGranted == true && isPreciseLocationDenied) {
      return 'Denied';
    }

    switch (status) {
      case PermissionStatus.granted:
        return 'Allowed';
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
        return 'Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      default:
        return 'Unknown';
    }
  }

  /// Checks if a permission needs attention
  static bool needsAttention(
      PermissionStatus? status, bool isPreciseLocationDenied) {
    return status?.isDenied == true ||
        status?.isPermanentlyDenied == true ||
        isPreciseLocationDenied;
  }
}
