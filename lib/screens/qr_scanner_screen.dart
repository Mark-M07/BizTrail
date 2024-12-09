import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isVisible) {
      initializeController();
    }
  }

  @override
  void didUpdateWidget(QRScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        initializeController();
      } else {
        controller?.dispose();
        controller = null;
      }
    }
  }

  void initializeController() {
    if (mounted && controller == null) {
      controller = MobileScannerController(
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

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
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!widget.isVisible) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        controller?.dispose();
        controller = null;
        break;
      case AppLifecycleState.resumed:
        initializeController();
        break;
      case AppLifecycleState.detached:
        controller?.dispose();
        controller = null;
        break;
      case AppLifecycleState.hidden:
        controller?.dispose();
        controller = null;
        break;
    }
  }
}
