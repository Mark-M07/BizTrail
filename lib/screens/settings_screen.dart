import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/permission_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  Map<Permission, bool> _isPreciseLocationDeniedMap = {}; // Removed final
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

    try {
      final result = await PermissionHelper.loadPermissionStatuses();

      setState(() {
        _permissionStatuses = result.statuses;
        _isPreciseLocationDeniedMap = result.isPreciseLocationDeniedMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading permissions: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    try {
      setState(() => _isLoading = true);

      final (status, isPreciseDenied) =
          await PermissionHelper.requestPermission(permission);

      setState(() {
        _permissionStatuses[permission] = status;
        if (permission == Permission.locationWhenInUse) {
          _isPreciseLocationDeniedMap[permission] = isPreciseDenied;
        }
      });

      if (status.isPermanentlyDenied && permission == Permission.camera) {
        _showCameraPermissionDialog();
      } else if ((permission == Permission.locationWhenInUse &&
          (!status.isGranted || isPreciseDenied))) {
        _showPreciseLocationDialog();
      }

      await _loadPermissions(); // Refresh all statuses
    } catch (e) {
      debugPrint('Error handling permission: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCameraPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Camera'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              PermissionHelper.getPermissionDescription(Permission.camera),
              style: const TextStyle(fontSize: 16),
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
                children: PermissionHelper.getCameraPermissionInstructions()
                    .map((instruction) => Text(instruction))
                    .toList(),
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
        title: const Text('Precise Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              PermissionHelper.getPermissionDescription(
                  Permission.locationWhenInUse),
              style: const TextStyle(fontSize: 16),
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
                children: PermissionHelper.getPreciseLocationInstructions()
                    .map((instruction) => Text(instruction))
                    .toList(),
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

  Widget _buildPermissionTile(Permission permission) {
    final status = _permissionStatuses[permission];
    final isPreciseLocationDenied =
        permission == Permission.locationWhenInUse &&
            status?.isGranted == true &&
            _isPreciseLocationDeniedMap[permission] == true;

    return ListTile(
      title: Text(PermissionHelper.getPermissionTitle(permission)),
      subtitle: Text(PermissionHelper.getPermissionDescription(permission)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: PermissionHelper.getStatusColor(
                      status, isPreciseLocationDenied)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              PermissionHelper.getStatusText(status, isPreciseLocationDenied),
              style: TextStyle(
                color: PermissionHelper.getStatusColor(
                    status, isPreciseLocationDenied),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (PermissionHelper.needsAttention(status, isPreciseLocationDenied))
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _requestPermission(permission),
              tooltip: 'Update Permission',
            ),
        ],
      ),
    );
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
