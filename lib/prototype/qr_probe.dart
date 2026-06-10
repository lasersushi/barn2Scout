import 'package:flutter/material.dart';

import '../features/records/view/qr_scan_page.dart';

/// Release-mode camera probe: boots straight into the QR scan page with no
/// auth, Isar, or Supabase, so the scanner can be tested under a real
/// release build (R8 shrinking + AOT) without signing in.
///
///   flutter run --release -t lib/prototype/qr_probe.dart
///
/// Scanning a real Barn2Scout QR here will crash on save (no repositories
/// are provided) — this probe only exercises camera startup and the ML Kit
/// pipeline, which is where the release-only null crash lived.
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QrScanPage(),
    ),
  );
}
