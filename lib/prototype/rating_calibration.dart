// Throwaway calibration harness for the picklist rating model.
//
// Run:  flutter run -t lib/prototype/rating_calibration.dart
//
// Prints the distribution of implied contribution across one event so the
// reliability-bucket constants (PredictionConfig.steadyMax / .variableMax) can
// be picked from real data instead of guessed. The previous 0.12 / 0.22 pair
// was fitted against a different metric and put 14 of 15 teams in one bucket.
//
// The contribution maths below intentionally MIRRORS
// ScheduleRepository.fetchTeamRatings — this file is never imported by real
// code, so if you change the model there, change it here too or the numbers
// stop meaning anything.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/models/tba_match.dart';
import '../data/services/tba_service.dart';

/// The event to calibrate against — 2026 NorCal District Championship.
const String _eventKey = '2026cancmp';

/// Printed match-by-match so individual dead matches are visible.
const int _focusTeam = 1678;

/// Candidate (steadyMax, variableMax) pairs to preview the bucket split for.
const List<(double, double)> _candidates = [
  (0.12, 0.22), // the pre-2026 constants, for comparison
  (0.40, 0.85),
  (0.45, 0.95), // current values in PredictionConfig
  (0.50, 1.05),
];

void main() => runApp(const _CalibrationApp());

class _CalibrationApp extends StatelessWidget {
  const _CalibrationApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Rating calibration')),
          body: FutureBuilder<String>(
            future: _run(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('Failed: ${snap.error}'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  snap.data!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              );
            },
          ),
        ),
      );
}

class _Row {
  _Row(this.team, this.opr, this.dpr, this.contribs);

  final int team;
  final double opr;
  final double dpr;
  final List<double> contribs;

  late final double median = _median(contribs);
  late final double? std = _std(contribs);

  /// MAD-derived sigma, matching the low-match test in ScheduleRepository.
  late final int lowCount = () {
    if (contribs.length < 2) return 0;
    final mad = _median([for (final x in contribs) (x - median).abs()]);
    final sigma = mad > 1e-9 ? 1.4826 * mad : (std ?? 0.0);
    if (sigma <= 1e-9) return 0;
    final floor = median - 2 * sigma;
    return contribs.where((x) => x < floor).length;
  }();
}

Future<String> _run() async {
  final tba = TbaService();
  final b = StringBuffer();

  final oprData =
      await tba.get('/event/$_eventKey/oprs') as Map<String, dynamic>;
  final oprs = (oprData['oprs'] as Map?)?.cast<String, dynamic>() ?? {};
  final dprs = (oprData['dprs'] as Map?)?.cast<String, dynamic>() ?? {};
  if (oprs.isEmpty) return 'No OPRs for $_eventKey — wrong key, or no matches.';

  final raw = await tba.get('/event/$_eventKey/matches/simple') as List;
  final matches =
      raw.cast<Map<String, dynamic>>().map(TbaMatch.fromJson).toList();

  final meanOpr =
      oprs.values.map((v) => (v as num).toDouble()).reduce((a, b) => a + b) /
          oprs.length;
  double oprOf(String key) => (oprs[key] as num?)?.toDouble() ?? meanOpr;

  final contribs = <int, List<double>>{};
  void collect(List<String> keys, int? score) {
    if (score == null) return;
    for (final k in keys) {
      final n = int.tryParse(TbaMatch.displayNumber(k));
      if (n == null) continue;
      var partners = 0.0;
      for (final other in keys) {
        if (other != k) partners += oprOf(other);
      }
      (contribs[n] ??= []).add(score.toDouble() - partners);
    }
  }

  var played = 0;
  for (final m in matches) {
    if (!m.isPlayed) continue;
    played++;
    collect(m.redTeams, m.redScore);
    collect(m.blueTeams, m.blueScore);
  }

  final rows = <_Row>[];
  for (final e in oprs.entries) {
    final n = int.tryParse(TbaMatch.displayNumber(e.key));
    if (n == null) continue;
    final xs = contribs[n] ?? const <double>[];
    if (xs.isEmpty) continue;
    rows.add(_Row(n, (e.value as num).toDouble(),
        (dprs[e.key] as num?)?.toDouble() ?? 0, xs));
  }
  rows.sort((a, b) => b.median.compareTo(a.median));

  final meanContrib =
      rows.map((r) => r.median).reduce((a, b) => a + b) / rows.length;
  final floor = (meanContrib * 0.25).abs();

  b.writeln('event $_eventKey · $played played matches · ${rows.length} teams');
  b.writeln('mean contribution ${meanContrib.toStringAsFixed(1)}  '
      'floor ${floor.toStringAsFixed(1)}');
  b.writeln('');
  b.writeln('team    OPR    DPR    CON    STD  spread  low');
  b.writeln('-' * 48);
  for (final r in rows) {
    final denom = math.max(r.median, floor);
    final spread = (r.std == null || denom <= 1e-9) ? null : r.std! / denom;
    b.writeln('${r.team.toString().padLeft(5)}  '
        '${r.opr.toStringAsFixed(0).padLeft(5)}  '
        '${r.dpr.toStringAsFixed(0).padLeft(5)}  '
        '${r.median.toStringAsFixed(0).padLeft(5)}  '
        '${(r.std?.toStringAsFixed(0) ?? '-').padLeft(5)}  '
        '${(spread?.toStringAsFixed(2) ?? '-').padLeft(6)}  '
        '${r.lowCount == 0 ? '' : r.lowCount}');
  }

  b.writeln('');
  b.writeln('bucket split by candidate cutoffs (steady / variable / streaky)');
  for (final (steady, variable) in _candidates) {
    var s = 0, v = 0, k = 0;
    for (final r in rows) {
      final denom = math.max(r.median, floor);
      if (r.std == null || denom <= 1e-9) continue;
      final spread = r.std! / denom;
      if (spread < steady) {
        s++;
      } else if (spread < variable) {
        v++;
      } else {
        k++;
      }
    }
    b.writeln('  ${steady.toStringAsFixed(2)} / '
        '${variable.toStringAsFixed(2)}  →  $s / $v / $k');
  }

  final focus = rows.where((r) => r.team == _focusTeam).firstOrNull;
  if (focus != null) {
    b.writeln('');
    b.writeln('team $_focusTeam per-match implied contribution');
    b.writeln('  median ${focus.median.toStringAsFixed(1)} · '
        'OPR ${focus.opr.toStringAsFixed(1)} · '
        '${focus.lowCount} below baseline');
    final sorted = [...focus.contribs]..sort();
    b.writeln('  ${sorted.map((x) => x.toStringAsFixed(0)).join(', ')}');
  }

  debugPrint(b.toString());
  return b.toString();
}

double _median(List<double> xs) {
  final sorted = [...xs]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}

double? _std(List<double> xs) {
  if (xs.length < 2) return null;
  final mean = xs.reduce((a, b) => a + b) / xs.length;
  final variance =
      xs.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
          (xs.length - 1);
  return math.sqrt(variance);
}
