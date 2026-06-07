import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  final _controller = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.displayValue;
    if (raw == null || raw.isEmpty) return;

    // Guard against double-fires while we await the repo write.
    _processing = true;
    await _controller.stop();

    try {
      final record = QrRecordCodec.decode(raw);
      if (!mounted) return;
      await context.read<ScoutingRepository>().save(record);
      if (!mounted) return;
      // RecordsCubit uses an Isar stream watcher — it updates automatically
      // when the save above fires, so no manual reload is needed.

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
      // Not a valid Barn2Scout QR — show error, resume scanner.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not a valid scouting QR: ${e.message}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        await _controller.start();
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
        await _controller.start();
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
          // Torch toggle
          IconButton(
            icon: const Icon(Icons.flashlight_on_outlined),
            tooltip: 'Toggle torch',
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Scan frame overlay
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

          // Instructions at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
