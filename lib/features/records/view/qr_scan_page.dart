import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/utils/qr_record_codec.dart';
import '../../../data/repositories/scouting_repository.dart';

/// Full-screen camera page that scans QR codes exported by [RecordDetailPage].
///
/// On a successful scan:
///   1. Decode via [QrRecordCodec.decode]
///   2. Save via [ScoutingRepository.save] (Isar deduplicates on uuid)
///   3. Pop and show a SnackBar confirming success
///
/// Camera is paused between successful scans to avoid double-processing.
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QrScanPage()),
    );
  }

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  MobileScannerController? _controller;
  bool _processing = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _controller = MobileScannerController());
    } else {
      setState(() => _permissionDenied = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || _controller == null) return;
    final raw = capture.barcodes.firstOrNull?.displayValue;
    if (raw == null || raw.isEmpty) return;

    _processing = true;
    await _controller!.stop();

    try {
      final record = QrRecordCodec.decode(raw);
      if (!mounted) return;
      await context.read<ScoutingRepository>().save(record);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported Team ${record.teamNumber} · Match ${record.matchNumber}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FormatException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not a valid scouting QR: ${e.message}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        await _controller?.start();
      }
      _processing = false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to import record'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        await _controller?.start();
      }
      _processing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_controller != null)
            IconButton(
              icon: const Icon(Icons.flashlight_on_outlined),
              tooltip: 'Toggle torch',
              onPressed: () => _controller!.toggleTorch(),
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _permissionDenied
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.no_photography_outlined,
                        color: Colors.white54, size: 56),
                    const SizedBox(height: 16),
                    const Text(
                      'Camera permission is required to scan QR codes.',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: openAppSettings,
                      child: const Text('Open Settings'),
                    ),
                  ],
                ),
              ),
            )
          : _controller == null
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Stack(
                  children: [
                    MobileScanner(
                      controller: _controller!,
                      onDetect: _onDetect,
                    ),
                    Center(
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white70, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 32),
                        color: Colors.black54,
                        child: const Text(
                          'Point the camera at a Barn2Scout QR code',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
