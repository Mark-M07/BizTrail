import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import '../screens/settings_screen.dart';
import 'package:flutter/services.dart';

class QRScannerScreen extends StatefulWidget {
  final bool isVisible;

  const QRScannerScreen({
    super.key,
    required this.isVisible,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? controller;
  bool isScanned = false;
  bool? hasPermission;

  static const MethodChannel _accuracyChannel =
      MethodChannel('com.biztrail.app/location_accuracy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isVisible) {
      _checkAndInitializeScanner();
    }
  }

  @override
  void didUpdateWidget(QRScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _checkAndInitializeScanner();
      } else {
        _disposeScanner();
      }
    }
  }

  Future<void> _checkAndInitializeScanner() async {
    // Check camera permission
    final cameraStatus = await Permission.camera.status;
    if (!mounted) return;

    if (!cameraStatus.isGranted) {
      // Request camera permission if not granted
      final newCameraStatus = await Permission.camera.request();
      if (!mounted) return;

      if (!newCameraStatus.isGranted) {
        // Camera permission still not granted, show warning screen
        setState(() {
          hasPermission = false;
        });
        return;
      }
    }

    // At this point, camera is granted. Now check location permission
    final locationWhenInUseStatus = await Permission.locationWhenInUse.status;
    if (!mounted) return;

    if (!locationWhenInUseStatus.isGranted) {
      // Location (when in use) not granted, show warning
      setState(() {
        hasPermission = false;
      });
      return;
    }

    // If on iOS, check precise location using the method channel
    if (Platform.isIOS) {
      final accuracy =
          await _accuracyChannel.invokeMethod<String>('checkLocationAccuracy');
      if (accuracy == 'reducedAccuracy') {
        // Precise location not granted on iOS, show warning
        setState(() {
          hasPermission = false;
        });
        return;
      }
    } else {
      // On Android, also check Permission.location for full accuracy
      final preciseStatus = await Permission.location.status;
      if (!preciseStatus.isGranted) {
        // Means we have coarse location (whenInUse) but not precise (location)
        setState(() {
          hasPermission = false;
        });
        return;
      }
    }

    // All required permissions (camera & precise location) are good
    setState(() {
      hasPermission = true;
    });
    _initializeScanner();
  }

  void _initializeScanner() {
    if (mounted && controller == null) {
      controller = MobileScannerController(
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      controller!.start().catchError((error) {
        debugPrint('Failed to start scanner: $error');
        if (mounted) {
          setState(() {
            hasPermission = false;
          });
        }
        return null;
      });
    }
  }

  void _disposeScanner() {
    controller?.stop();
    controller?.dispose();
    controller = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    if (hasPermission == null) {
      return const SizedBox.shrink();
    }

    if (!hasPermission!) {
      // Show the warning UI
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_update_warning,
                  size: 64, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Permissions Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'BizTrail needs camera access to scan QR codes and precise location to verify your presence at business locations.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (context) => const SettingsScreen(),
                  );
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    // If we have all permissions, show the scanner
    return Stack(
      children: [
        if (controller != null)
          MobileScanner(
            controller: controller!,
            errorBuilder: (context, error, child) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: Text(
                    'Error: ${error.errorCode}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (!isScanned && barcodes.isNotEmpty) {
                isScanned = true;
                String code = barcodes.first.rawValue ?? 'No data found!';
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('QR Code Found!'),
                    content: Text('Value: $code'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          isScanned = false;
                          Navigator.pop(context);
                        },
                        child: const Text('Continue Scanning'),
                      ),
                    ],
                  ),
                ).then((_) => isScanned = false);
              }
            },
          ),
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              color: Colors.black26,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (controller != null) ...[
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: controller!,
                      builder: (context, state, child) {
                        return IconButton(
                          color: Colors.white,
                          icon: state.torchState == TorchState.on
                              ? const Icon(Icons.flash_on)
                              : const Icon(Icons.flash_off),
                          onPressed: () => controller?.toggleTorch(),
                        );
                      },
                    ),
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: controller!,
                      builder: (context, state, child) {
                        return IconButton(
                          color: Colors.white,
                          icon: state.cameraDirection == CameraFacing.front
                              ? const Icon(Icons.camera_front)
                              : const Icon(Icons.camera_rear),
                          onPressed: () => controller?.switchCamera(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              'Position the QR code within the frame',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeScanner();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!widget.isVisible) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _disposeScanner();
        break;
      case AppLifecycleState.resumed:
        // Add slight delay when resuming to ensure camera system is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _checkAndInitializeScanner();
          }
        });
        break;
    }
  }
}
