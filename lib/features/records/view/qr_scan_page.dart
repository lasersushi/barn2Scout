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
/// Camera permission is requested by mobile_scanner itself when the
/// controller starts. Start-up failures (denied permission, camera errors)
/// surface through the controller state and are rendered by [_ScanError]
/// instead of the plugin's bare default error widget.
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

  Future<void> _retry() async {
    if (_controller.value.isStarting) return;
    try {
      await _controller.start();
    } on MobileScannerException {
      // Start errors are also reflected in the controller state, which
      // re-renders the error UI — nothing further to do here.
    }
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
            errorBuilder: (context, error) =>
                _ScanError(error: error, onRetry: _retry),
          ),

          // Scan frame + instructions, hidden while the error UI is shown.
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              if (state.error != null) return const SizedBox.shrink();
              return Stack(
                children: [
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
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Friendly replacement for mobile_scanner's default error widget.
///
/// Distinguishes a denied camera permission from other camera failures, and
/// keeps the raw error message visible so testers can report something more
/// useful than "it didn't work".
class _ScanError extends StatelessWidget {
  const _ScanError({required this.error, required this.onRetry});

  final MobileScannerException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isPermission =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    final detail = error.errorDetails?.message;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermission
                  ? Icons.no_photography_outlined
                  : Icons.videocam_off_outlined,
              color: Colors.white54,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              isPermission
                  ? 'Camera access is needed to scan QR codes.\n'
                      'Allow camera access for Barn2Scout in your device '
                      'Settings, then try again.'
                  : 'The camera could not be started.',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            if (!isPermission && detail != null && detail.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
