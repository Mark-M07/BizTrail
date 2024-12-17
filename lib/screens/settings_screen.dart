import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  final Map<Permission, bool> _isPreciseLocationDeniedMap = {};
  bool _isLoading = true;
  bool _returnedFromSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _returnedFromSettings) {
      _returnedFromSettings = false;
      _handleReturnFromSettings();
    }
  }

  Future<void> _handleReturnFromSettings() async {
    await _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    final permissions = [
      Permission.camera,
      Permission.locationWhenInUse,
    ];

    final statuses = await Future.wait(
      permissions.map((permission) => permission.status),
    );

    final newStatuses = Map.fromIterables(permissions, statuses);

    // Check precise location status for both iOS and Android
    final preciseLocationStatus = await Permission.location.status;
    final locationStatus = newStatuses[Permission.locationWhenInUse];

    if (locationStatus?.isGranted == true && !preciseLocationStatus.isGranted) {
      _isPreciseLocationDeniedMap[Permission.locationWhenInUse] = true;
    } else {
      _isPreciseLocationDeniedMap[Permission.locationWhenInUse] = false;
    }

    setState(() {
      _permissionStatuses = newStatuses;
      _isLoading = false;
    });
  }

  Future<void> _requestPermission(Permission permission) async {
    try {
      if (permission == Permission.camera) {
        final result = await permission.request();
        setState(() {
          _permissionStatuses[permission] = result;
        });

        if (result.isPermanentlyDenied) {
          _showCameraPermissionDialog();
        }
      } else if (permission == Permission.locationWhenInUse) {
        // First, set loading state
        setState(() {
          _isLoading = true;
        });

        // Request coarse location
        final coarseResult = await Permission.locationWhenInUse.request();

        // Immediately check precise location status
        final preciseResult = await Permission.location.status;

        // Update both statuses together
        setState(() {
          _permissionStatuses[permission] = coarseResult;
          _isPreciseLocationDeniedMap[permission] =
              coarseResult.isGranted && !preciseResult.isGranted;
          _isLoading = false;
        });

        if (!coarseResult.isGranted || !preciseResult.isGranted) {
          _showPreciseLocationDialog();
          return;
        }

        // Final permission check to ensure consistency
        await _loadPermissions();
      }
    } catch (e) {
      debugPrint('Error handling permission: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCameraPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Camera Access Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BizTrail requires camera access to scan QR codes at business locations.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'To enable camera access:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: Platform.isIOS
                    ? const [
                        Text('1. Press "Open Settings"'),
                        Text('2. Enable "Camera"'),
                      ]
                    : const [
                        Text('1. Press "Open Settings"'),
                        Text('2. Tap "Permissions"'),
                        Text('3. Select "Camera"'),
                        Text('4. Choose "Allow only while using the app"'),
                      ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _returnedFromSettings = true;
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPreciseLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Precise Location Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BizTrail requires precise location to verify your presence at business locations.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'To enable precise location:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: Platform.isIOS
                    ? const [
                        Text('1. Press "Open Settings"'),
                        Text('2. Tap "Location"'),
                        Text('3. Enable "Precise Location"'),
                      ]
                    : const [
                        Text('1. Press "Open Settings"'),
                        Text('2. Tap "Permissions"'),
                        Text('3. Select "Location"'),
                        Text(
                            '4. Ensure "Allow only while using the app" is selected'),
                        Text('5. Enable "Use precise location"'),
                      ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _returnedFromSettings = true;
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  String _getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Required for scanning QR codes at business locations';
      case Permission.locationWhenInUse:
        return 'Required to verify your presence at business locations';
      default:
        return 'Permission description not available';
    }
  }

  String _getPermissionTitle(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera';
      case Permission.locationWhenInUse:
        return 'Precise Location';
      default:
        return permission.toString();
    }
  }

  Widget _buildPermissionTile(Permission permission) {
    final status = _permissionStatuses[permission];
    final isPreciseLocationDenied =
        permission == Permission.locationWhenInUse &&
            status?.isGranted == true &&
            _isPreciseLocationDeniedMap[permission] == true;

    return ListTile(
      title: Text(_getPermissionTitle(permission)),
      subtitle: Text(_getPermissionDescription(permission)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status, isPreciseLocationDenied)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPreciseLocationDenied ? 'Denied' : _getStatusText(status),
              style: TextStyle(
                color: _getStatusColor(status, isPreciseLocationDenied),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (status?.isDenied == true ||
              status?.isPermanentlyDenied == true ||
              isPreciseLocationDenied)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _requestPermission(permission),
              tooltip: 'Update Permission',
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(
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

  String _getStatusText(PermissionStatus? status) {
    if (status?.isGranted == true &&
        _isPreciseLocationDeniedMap[Permission.locationWhenInUse] == true) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'App Permissions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ..._permissionStatuses.keys.map(_buildPermissionTile),
              ],
            ),
    );
  }
}
