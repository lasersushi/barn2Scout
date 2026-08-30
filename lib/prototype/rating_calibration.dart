// Throwaway calibration harness for the picklist rating model.
//
// Run:  flutter run -t lib/prototype/rating_calibration.dart
//
// Prints the distribution of implied contribution across one event so the
// reliability-bucket constants (PredictionConfig.steadyMax / .variableMax) can
// be picked from real data instead of guessed. `spread` is a team's stabilised
// swing — std/sqrt(median) — over the field's median of the same, so 1.00 is an
// exactly average robot and the cutoffs sit either side of it.
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

/// Candidate low-match thresholds, in event-median-std units, to compare.
const List<double> _lowSwingCandidates = [1.5, 2.0, 2.5, 3.0];

/// Candidate (steadyMax, variableMax) pairs to preview the bucket split for.
const List<(double, double)> _candidates = [
  (0.85, 1.10),
  (0.90, 1.20), // current values in PredictionConfig
  (0.95, 1.25),
  (1.00, 1.35),
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

  /// Matches more than [k] event-median swings below this team's own median —
  /// mirrors ScheduleRepository._lowCount.
  int lowCount(double eventStd, double k) {
    if (contribs.length < 2 || eventStd <= 1e-9) return 0;
    final floor = median - k * eventStd;
    return contribs.where((x) => x < floor).length;
  }
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

  // Mirrors TeamStrength._stability: std/sqrt(median) so big scorers aren't
  // marked streaky purely for scoring big.
  final stabilities = [
    for (final r in rows)
      if (r.std != null && r.median > 1e-9) r.std! / math.sqrt(r.median)
  ];
  final medianStability = stabilities.isEmpty ? 0.0 : _median(stabilities);
  final allStds = [for (final r in rows) if (r.std != null) r.std!];
  final medianStd = allStds.isEmpty ? 0.0 : _median(allStds);

  b.writeln('event $_eventKey · $played played matches · ${rows.length} teams');
  b.writeln('median contribution std ${medianStd.toStringAsFixed(1)} '
      '(low-match yardstick)');
  b.writeln('median stability ${medianStability.toStringAsFixed(2)} '
      '(reliability denominator)');
  b.writeln('');
  b.writeln('team    OPR    DPR    CON    STD  spread  low');
  b.writeln('-' * 48);
  for (final r in rows) {
    final spread = (r.std == null || r.median <= 1e-9 || medianStability <= 1e-9)
        ? null
        : (r.std! / math.sqrt(r.median)) / medianStability;
    b.writeln('${r.team.toString().padLeft(5)}  '
        '${r.opr.toStringAsFixed(0).padLeft(5)}  '
        '${r.dpr.toStringAsFixed(0).padLeft(5)}  '
        '${r.median.toStringAsFixed(0).padLeft(5)}  '
        '${(r.std?.toStringAsFixed(0) ?? '-').padLeft(5)}  '
        '${(spread?.toStringAsFixed(2) ?? '-').padLeft(6)}  '
        '${r.lowCount(medianStd, 2.0) == 0 ? '' : r.lowCount(medianStd, 2.0)}');
  }

  b.writeln('');
  b.writeln('bucket split by candidate cutoffs (steady / variable / streaky)');
  for (final (steady, variable) in _candidates) {
    var s = 0, v = 0, k = 0;
    for (final r in rows) {
      if (r.std == null || r.median <= 1e-9 || medianStability <= 1e-9) continue;
      final spread = (r.std! / math.sqrt(r.median)) / medianStability;
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

  b.writeln('');
  b.writeln('low-match rule: teams by flag count, and team $_focusTeam');
  b.writeln('  k     0    1    2   3+   per-team  $_focusTeam');
  for (final k in _lowSwingCandidates) {
    final counts = [for (final r in rows) r.lowCount(medianStd, k)];
    final z = counts.where((c) => c == 0).length;
    final one = counts.where((c) => c == 1).length;
    final two = counts.where((c) => c == 2).length;
    final more = counts.where((c) => c >= 3).length;
    final perTeam = counts.reduce((a, b) => a + b) / counts.length;
    final focusCount =
        rows.where((r) => r.team == _focusTeam).firstOrNull?.lowCount(
                medianStd, k) ??
            0;
    b.writeln('  ${k.toStringAsFixed(1)}  '
        '${z.toString().padLeft(3)}  ${one.toString().padLeft(3)}  '
        '${two.toString().padLeft(3)}  ${more.toString().padLeft(3)}  '
        '${perTeam.toStringAsFixed(2).padLeft(8)}  '
        '${focusCount.toString().padLeft(3)}');
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
