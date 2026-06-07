// ═══════════════════════════════════════════════════════════════════════════
// THROWAWAY TUI SHELL — delete me once the prediction model is validated.
//
// Drives prediction_model.dart by hand so we can sanity-check the math before
// wiring it into the schedule. Punch teams onto each alliance, toggle how
// unscouted teams are handled, and watch the win % move.
//
// Run it (Dart VM — imports no Flutter):
//   dart run lib/prototype/predictor_tui.dart
//
// Keys:
//   n / p   move the cursor to the next / previous alliance slot
//   space   cycle the team in the current slot (wraps through the roster)
//   m       toggle missing-data policy (ZERO  ↔  LEAGUE AVERAGE)
//   1..5    load a preset scenario
//   q       quit
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';

import 'prediction_model.dart';

// ── ANSI helpers ────────────────────────────────────────────────────────────
const _clear = '\x1b[2J\x1b[H';
const _bold = '\x1b[1m';
const _dim = '\x1b[2m';
const _red = '\x1b[31m';
const _blue = '\x1b[34m';
const _reset = '\x1b[0m';

// ── Sample roster (composite mean & std; null = unscouted) ──────────────────
final List<TeamStat> _roster = [
  const TeamStat(254, 15.0, 2.4), // elite, consistent
  const TeamStat(1678, 12.9, 1.9),
  const TeamStat(118, 12.5, 3.1),
  const TeamStat(751, 11.3, 2.2), // us
  const TeamStat(33, 11.0, 6.5), // boom-or-bust (same mean as 27...)
  const TeamStat(27, 11.0, 1.0), // ...but metronome-steady
  const TeamStat(4414, 8.3, 2.6),
  const TeamStat(2056, 4.4, 1.3), // defense bot, scores little
  const TeamStat(9999, 1.7, 0.9), // weak
  const TeamStat(6321, null, null), // NEVER SCOUTED
  const TeamStat(7042, null, null), // NEVER SCOUTED
];

/// Named scenarios → (redIndices, blueIndices) into [_roster].
final Map<int, (List<int>, List<int>)> _scenarios = {
  1: ([0, 1, 2], [7, 8, 6]), // blowout: top 3 vs bottom 3
  2: ([2, 6, 8], [3, 7, 1]), // roughly even
  3: ([0, 1, 9], [3, 6, 7]), // red has ONE unscouted team (6321)
  4: ([0, 9, 10], [3, 6, 7]), // red has TWO unscouted teams
  5: ([4, 7, 8], [5, 7, 8]), // same means, red high-σ vs blue low-σ
};

class _Tui {
  List<int> red = List.of(_scenarios[1]!.$1);
  List<int> blue = List.of(_scenarios[1]!.$2);
  int cursor = 0; // 0..2 = red slots, 3..5 = blue slots
  MissingPolicy policy = MissingPolicy.leagueAverage;
  bool raw = true;

  // League-average prior, computed from scouted roster teams.
  double get _leagueMean {
    final s = _roster.where((t) => t.scouted).toList();
    return s.map((t) => t.mean!).reduce((a, b) => a + b) / s.length;
  }

  double get _leagueStd {
    final s = _roster.where((t) => t.scouted).toList();
    return s.map((t) => t.std!).reduce((a, b) => a + b) / s.length;
  }

  List<TeamStat> get _redTeams => red.map((i) => _roster[i]).toList();
  List<TeamStat> get _blueTeams => blue.map((i) => _roster[i]).toList();

  void run() {
    try {
      stdin.echoMode = false;
      stdin.lineMode = false;
    } catch (_) {
      raw = false; // piped / non-tty — fall back to line input
    }
    try {
      _render();
      var running = true;
      while (running) {
        final key = _readKey();
        if (key == -1) break;
        running = _handle(key);
        _render();
      }
    } finally {
      try {
        stdin.echoMode = true;
        stdin.lineMode = true;
      } catch (_) {}
      stdout.write(_reset);
    }
  }

  int _readKey() {
    if (raw) return stdin.readByteSync();
    final line = stdin.readLineSync();
    if (line == null || line.isEmpty) return -1;
    return line.codeUnitAt(0);
  }

  bool _handle(int key) {
    final c = String.fromCharCode(key);
    switch (c) {
      case 'q':
        return false;
      case 'n':
        cursor = (cursor + 1) % 6;
      case 'p':
        cursor = (cursor + 5) % 6;
      case ' ':
        _cycleSlot();
      case 'm':
        policy = policy == MissingPolicy.zero
            ? MissingPolicy.leagueAverage
            : MissingPolicy.zero;
      case '1' || '2' || '3' || '4' || '5':
        final s = _scenarios[int.parse(c)]!;
        red = List.of(s.$1);
        blue = List.of(s.$2);
    }
    if (key == 3) return false; // Ctrl-C
    return true;
  }

  void _cycleSlot() {
    if (cursor < 3) {
      red[cursor] = (red[cursor] + 1) % _roster.length;
    } else {
      blue[cursor - 3] = (blue[cursor - 3] + 1) % _roster.length;
    }
  }

  void _render() {
    final p = predictMatch(
      _redTeams,
      _blueTeams,
      policy: policy,
      leagueMean: _leagueMean,
      leagueStd: _leagueStd,
    );

    final b = StringBuffer(_clear);
    b.writeln('${_bold}BARN2SCOUT — MATCH PREDICTOR PROTOTYPE$_reset '
        '$_dim(throwaway)$_reset');
    b.writeln('${_dim}Q: believable win probs? + how to handle unscouted teams?'
        '$_reset');
    b.writeln();

    final polLabel = policy == MissingPolicy.leagueAverage
        ? 'LEAGUE AVERAGE (μ ${_leagueMean.toStringAsFixed(1)}, '
            'σ ${_leagueStd.toStringAsFixed(1)})'
        : 'ZERO';
    b.writeln('${_bold}Missing-data policy:$_reset $polLabel  ${_dim}[m]$_reset');
    b.writeln();

    _writeAlliance(b, 'RED ALLIANCE', _red, p.red, red, 0);
    b.writeln();
    _writeAlliance(b, 'BLUE ALLIANCE', _blue, p.blue, blue, 3);
    b.writeln();

    final z = zeroZScore(p);
    final zStr = z.isNaN ? 'n/a' : z.toStringAsFixed(2);
    b.writeln('${_bold}PREDICTION$_reset  ${_dim}diff μ '
        '${p.diffMu.toStringAsFixed(1)}  σ ${p.diffSigma.toStringAsFixed(1)}  '
        'z(0) $zStr$_reset');
    final rp = (p.redWinPct * 100).round();
    b.writeln('  $_red${_bold}RED $_reset  ${p.red.expected.toStringAsFixed(0)} pts  '
        '$_red${_winBar(p.redWinPct)}$_reset ${_pad('$rp%', 4)}');
    b.writeln('  $_blue${_bold}BLUE$_reset  ${p.blue.expected.toStringAsFixed(0)} pts  '
        '$_blue${_winBar(p.blueWinPct)}$_reset ${_pad('${100 - rp}%', 4)}');
    if (p.scoutedCount < 6) {
      b.writeln('  $_dim${p.scoutedCount}/6 teams scouted$_reset');
    }
    b.writeln();
    b.writeln('$_dim[n/p] slot   [space] change team   [1-5] scenario   '
        '[m] policy   [q] quit$_reset');

    stdout.write(b.toString());
  }

  void _writeAlliance(
    StringBuffer b,
    String title,
    String color,
    AllianceP a,
    List<int> slots,
    int slotBase,
  ) {
    b.writeln('$color${_bold}$title$_reset');
    for (var i = 0; i < slots.length; i++) {
      final t = _roster[slots[i]];
      final isCursor = cursor == slotBase + i;
      final marker = isCursor ? '$_bold>$_reset' : ' ';
      final stat = t.scouted
          ? 'μ ${_pad(t.mean!.toStringAsFixed(1), 5)} σ '
              '${t.std!.toStringAsFixed(1)}'
          : '${_dim}— never scouted —$_reset';
      b.writeln('  $marker ${_pad('${t.team}', 5)} $stat');
    }
    b.writeln('    $_dim Σμ ${a.expected.toStringAsFixed(1)}   '
        'σ ${a.actual.toStringAsFixed(1)}$_reset');
  }

  String _winBar(double pct, [int width = 20]) {
    final filled = (pct * width).round().clamp(0, width);
    return '█' * filled + '░' * (width - filled);
  }

  String _pad(String s, int width) =>
      s.length >= width ? s : s + ' ' * (width - s.length);
}

void main() => _Tui().run();
