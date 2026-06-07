// ⚠️ PROTOTYPE — THROWAWAY. DELETE WHEN DONE. Do not import from real code.
//
// Plan: three structurally-different takes on the alliance-picklist Teams page,
// switchable via the floating bottom bar, on one throwaway route.
//   A — Swipe-to-pick annotated ranked list   (ranking primary, pick = overlay)
//   B — Board + ordered, reorderable picklist  (evaluate vs decide, two lists)
//   C — Tier board / kanban bands              (spatial categorization)
//
// Validates 3 things with REAL kDefaultGameConfig + mock per-match data:
//   1. Point-weighted ranking  → headline = estimated points/match
//   2. Picklist workflow        → add/remove, reorder, pick / do-not-pick feel
//   3. Consistency display      → spread shown 3 ways (dot / whisker / shading)
//
// Run:  flutter run -t lib/prototype/picklist_prototype.dart
//
// VERDICT (fill in once chosen): __________________________________________

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/scouting/config/field_config.dart';
import '../features/scouting/config/game_config.dart';

void main() => runApp(const _PrototypeApp());

class _PrototypeApp extends StatelessWidget {
  const _PrototypeApp();
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Picklist Prototype',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const _PicklistPrototype(),
      );
}

// ─────────────────────────────────────────── POINT WEIGHTS (the real mechanism)
//
// In production these would become a `points` field on FieldConfig (one number
// per field, edited each January). Here they live in a side map keyed by the
// real field keys so the prototype exercises the actual schema.

const Map<String, num> _pointsPerUnit = {
  'auto_left_line': 3, // toggle → flat points if true
  'auto_scored_l1': 3, // counter → points each
  'auto_scored_l2': 4,
  'teleop_scored_l1': 2,
  'teleop_scored_l2': 3,
  // teleop_defense (rating)   → qualitative, no points
  // endgame_climb_time (stopwatch) → informational, no points
};

const Map<String, Map<String, num>> _pointsPerChoice = {
  'endgame_climb': {'None': 0, 'Park': 2, 'Shallow': 6, 'Deep': 12},
};

/// Points scored in a single match record — the production formula, verbatim.
double _matchPoints(Map<String, Object?> rec) {
  var pts = 0.0;
  for (final f in kDefaultGameConfig) {
    final v = rec[f.key];
    switch (f.type) {
      case FieldType.counter:
        pts += (_pointsPerUnit[f.key] ?? 0) * ((v as num?) ?? 0);
      case FieldType.toggle:
        if (v == true) pts += (_pointsPerUnit[f.key] ?? 0);
      case FieldType.choice:
        pts += (_pointsPerChoice[f.key]?[v as String?] ?? 0).toDouble();
      case FieldType.rating:
      case FieldType.stopwatch:
      case FieldType.text:
        break; // qualitative / informational — never weighted
    }
  }
  return pts;
}

double _phasePoints(Map<String, Object?> rec, ScoutPhase phase) {
  var pts = 0.0;
  for (final f in kDefaultGameConfig.where((f) => f.phase == phase)) {
    final v = rec[f.key];
    switch (f.type) {
      case FieldType.counter:
        pts += (_pointsPerUnit[f.key] ?? 0) * ((v as num?) ?? 0);
      case FieldType.toggle:
        if (v == true) pts += (_pointsPerUnit[f.key] ?? 0);
      case FieldType.choice:
        pts += (_pointsPerChoice[f.key]?[v as String?] ?? 0).toDouble();
      default:
        break;
    }
  }
  return pts;
}

// ─────────────────────────────────────────────────────────── MOCK DATA (seeded)

/// Tiny deterministic RNG so the mock teams are stable across hot reloads —
/// makes comparing variants fair.
class _Rng {
  _Rng(this._s);
  int _s;
  double next() {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return _s / 0x7fffffff;
  }
}

String _climbFor(_Rng r, double skill) {
  final x = r.next() * 0.55 + skill * 0.45;
  if (x > 0.82) return 'Deep';
  if (x > 0.55) return 'Shallow';
  if (x > 0.3) return 'Park';
  return 'None';
}

List<Map<String, Object?>> _genRecords(_Rng r, double skill, double noise, int n) {
  int ci(double base, double spread) =>
      (base + (r.next() * 2 - 1) * spread * noise).round().clamp(0, 99);
  return [
    for (var i = 0; i < n; i++)
      {
        'auto_left_line': r.next() < (0.45 + skill * 0.5),
        'auto_scored_l1': ci(skill * 3, 2),
        'auto_scored_l2': ci(skill * 2, 1.5),
        'teleop_scored_l1': ci(2 + skill * 10, 4),
        'teleop_scored_l2': ci(skill * 6, 3),
        'teleop_defense': ci(skill * 5, 2).clamp(0, 5),
        'endgame_climb': _climbFor(r, skill),
        'endgame_climb_time': ci(8 + (1 - skill) * 6, 3),
      }
  ];
}

class _TeamStats {
  _TeamStats(this.team, List<Map<String, Object?>> recs)
      : matches = recs.length {
    final totals = recs.map(_matchPoints).toList();
    meanPoints = _mean(totals);
    stdPoints = _std(totals, meanPoints);
    min = totals.reduce((a, b) => a < b ? a : b);
    max = totals.reduce((a, b) => a > b ? a : b);
    autoMean = _mean(recs.map((r) => _phasePoints(r, ScoutPhase.auto)).toList());
    teleopMean =
        _mean(recs.map((r) => _phasePoints(r, ScoutPhase.teleop)).toList());
    final climbs = recs.map((r) => r['endgame_climb'] as String).toList();
    climbPct = climbs.where((c) => c == 'Deep' || c == 'Shallow').length /
        climbs.length;
  }

  final int team;
  final int matches;
  late final double meanPoints, stdPoints, min, max, autoMean, teleopMean, climbPct;

  /// Coefficient of variation → a 0..2 reliability bucket (0 best).
  int get reliabilityBucket {
    if (meanPoints < 1) return 2;
    final cv = stdPoints / meanPoints;
    if (cv < 0.18) return 0;
    if (cv < 0.32) return 1;
    return 2;
  }

  static double _mean(List<num> xs) =>
      xs.isEmpty ? 0 : xs.fold<double>(0, (a, b) => a + b) / xs.length;
  static double _std(List<num> xs, double mean) {
    if (xs.length < 2) return 0;
    final v = xs.fold<double>(0, (a, b) => a + (b - mean) * (b - mean)) /
        (xs.length - 1);
    return _sqrt(v);
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    var g = x;
    for (var i = 0; i < 20; i++) {
      g = (g + x / g) / 2;
    }
    return g;
  }
}

List<_TeamStats> _mockTeams() {
  final r = _Rng(751);
  // (teamNumber, skill 0..1, noise 0.4 steady .. 1.6 streaky)
  const spec = [
    [254, 0.95, 0.5],
    [1678, 0.9, 0.55],
    [118, 0.86, 1.4], // strong but STREAKY — should read differently
    [2056, 0.83, 0.45],
    [751, 0.7, 0.7], // YOU
    [4414, 0.78, 0.6],
    [1323, 0.74, 1.5], // streaky mid
    [5460, 0.6, 0.7],
    [8840, 0.55, 0.9],
    [3669, 0.5, 0.6],
    [9999, 0.42, 1.3],
    [6800, 0.38, 0.7],
    [7777, 0.3, 0.9],
    [5274, 0.22, 0.6],
  ];
  final teams = [
    for (final s in spec)
      _TeamStats(
        s[0] as int,
        _genRecords(r, s[1].toDouble(), s[2].toDouble(), 8),
      )
  ]..sort((a, b) => b.meanPoints.compareTo(a.meanPoints));
  return teams;
}

const int _myTeam = 751;

// ───────────────────────────────────────────────────────────── PICK STATE MODEL

enum _Pick { available, picked, dnp }

const _tiers = ['1st Pick', '2nd Pick', 'Maybe', 'Do Not Pick', 'Unassigned'];

// ──────────────────────────────────────────────────────────────── HOST + SWITCH

class _PicklistPrototype extends StatefulWidget {
  const _PicklistPrototype();
  @override
  State<_PicklistPrototype> createState() => _PicklistPrototypeState();
}

class _PicklistPrototypeState extends State<_PicklistPrototype> {
  final List<_TeamStats> teams = _mockTeams();
  int variant = 0; // 0=A 1=B 2=C

  // A & B share a flat pick state.
  late final Map<int, _Pick> pick = {for (final t in teams) t.team: _Pick.available};
  // B: ordered picklist (team numbers).
  final List<int> order = [];
  // C: tier assignment.
  late final Map<int, String> tier = {for (final t in teams) t.team: 'Unassigned'};

  void _setPick(int team, _Pick p) => setState(() {
        pick[team] = p;
        order.remove(team);
        if (p == _Pick.picked) order.add(team);
      });

  void _reorder(int oldI, int newI) =>
      setState(() => order.insert(newI, order.removeAt(oldI)));

  void _setTier(int team, String t) => setState(() => tier[team] = t);

  static const _labels = ['A — Swipe-to-pick list', 'B — Board + picklist', 'C — Tier board'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teams · Picklist')),
      body: Stack(
        children: [
          Positioned.fill(
            child: switch (variant) {
              0 => _VariantA(teams: teams, pick: pick, onPick: _setPick),
              1 => _VariantB(
                  teams: teams,
                  pick: pick,
                  order: order,
                  onPick: _setPick,
                  onReorder: _reorder,
                ),
              _ => _VariantC(teams: teams, tier: tier, onTier: _setTier),
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _Switcher(
              label: _labels[variant],
              onPrev: () => setState(() => variant = (variant + 2) % 3),
              onNext: () => setState(() => variant = (variant + 1) % 3),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════ VARIANT A — swipe list

class _VariantA extends StatelessWidget {
  const _VariantA({required this.teams, required this.pick, required this.onPick});
  final List<_TeamStats> teams;
  final Map<int, _Pick> pick;
  final void Function(int, _Pick) onPick;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxPts = teams.first.meanPoints.clamp(1, 9999).toDouble();
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: teams.length + 1,
      separatorBuilder: (_, i) => i == 0 ? const SizedBox.shrink() : const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i == 0) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Swipe → to pick   ·   ← to veto   ·   tap for dossier',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          );
        }
        final t = teams[i - 1];
        final state = pick[t.team]!;
        return Dismissible(
          key: ValueKey(t.team),
          confirmDismiss: (dir) async {
            onPick(t.team,
                dir == DismissDirection.startToEnd ? _Pick.picked : _Pick.dnp);
            return false;
          },
          background: _swipeBg(Colors.green.shade600, Icons.check, 'PICK', left: true),
          secondaryBackground:
              _swipeBg(Colors.red.shade600, Icons.block, 'VETO', left: false),
          child: _RowA(t: t, rank: i, state: state, maxPts: maxPts, cs: cs),
        );
      },
    );
  }

  Widget _swipeBg(Color c, IconData icon, String label, {required bool left}) =>
      Container(
        color: c,
        alignment: left ? Alignment.centerLeft : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

class _RowA extends StatelessWidget {
  const _RowA({
    required this.t,
    required this.rank,
    required this.state,
    required this.maxPts,
    required this.cs,
  });
  final _TeamStats t;
  final int rank;
  final _Pick state;
  final double maxPts;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final dnp = state == _Pick.dnp;
    final picked = state == _Pick.picked;
    final mine = t.team == _myTeam;
    return Opacity(
      opacity: dnp ? 0.45 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showDossierStub(context, t),
        child: Container(
        color: picked
            ? Colors.green.withValues(alpha: 0.10)
            : mine
                ? cs.primaryContainer.withValues(alpha: 0.3)
                : null,
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        child: Row(
          children: [
            SizedBox(
                width: 28,
                child: Text('$rank',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurfaceVariant))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('Team ${t.team}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            decoration:
                                dnp ? TextDecoration.lineThrough : null)),
                    if (mine) ...[
                      const SizedBox(width: 6),
                      _miniBadge('YOU', cs.primary)
                    ],
                    if (picked) ...[
                      const SizedBox(width: 6),
                      _miniBadge('PICKED', Colors.green.shade700)
                    ],
                    if (dnp) ...[
                      const SizedBox(width: 6),
                      _miniBadge('DNP', Colors.red.shade700)
                    ],
                    const SizedBox(width: 8),
                    _ReliabilityDot(bucket: t.reliabilityBucket),
                  ]),
                  const SizedBox(height: 5),
                  _Bar(frac: t.meanPoints / maxPts, fill: cs.primary, track: cs.surfaceContainerHighest),
                  const SizedBox(height: 5),
                  Text(
                    'Auto ${t.autoMean.toStringAsFixed(0)} · Tele ${t.teleopMean.toStringAsFixed(0)} · Climb ${(t.climbPct * 100).toStringAsFixed(0)}%  ·  ${t.matches} matches',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(children: [
              Text(t.meanPoints.toStringAsFixed(0),
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cs.primary)),
              Text('±${t.stdPoints.toStringAsFixed(0)} pts',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ]),
          ],
        ),
      ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════ VARIANT B — board + list

class _VariantB extends StatefulWidget {
  const _VariantB({
    required this.teams,
    required this.pick,
    required this.order,
    required this.onPick,
    required this.onReorder,
  });
  final List<_TeamStats> teams;
  final Map<int, _Pick> pick;
  final List<int> order;
  final void Function(int, _Pick) onPick;
  final void Function(int, int) onReorder;

  @override
  State<_VariantB> createState() => _VariantBState();
}

class _VariantBState extends State<_VariantB> {
  int seg = 0; // 0 = board, 1 = picklist

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pickedCount = widget.order.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: SegmentedButton<int>(
            segments: [
              const ButtonSegment(value: 0, label: Text('Board'), icon: Icon(Icons.grid_view)),
              ButtonSegment(value: 1, label: Text('Picklist ($pickedCount)'), icon: const Icon(Icons.list_alt)),
            ],
            selected: {seg},
            onSelectionChanged: (s) => setState(() => seg = s.first),
          ),
        ),
        Expanded(child: seg == 0 ? _board(cs) : _picklist(cs)),
      ],
    );
  }

  Widget _board(ColorScheme cs) {
    final maxPts = widget.teams.first.meanPoints.clamp(1, 9999).toDouble();
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: widget.teams.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final t = widget.teams[i];
        final state = widget.pick[t.team]!;
        return ListTile(
          onTap: () => _showDossierStub(context, t),
          contentPadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
          leading: CircleAvatar(
            backgroundColor: cs.surfaceContainerHighest,
            child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Row(children: [
            Text('Team ${t.team}', style: const TextStyle(fontWeight: FontWeight.w700)),
            if (t.team == _myTeam) ...[const SizedBox(width: 6), _miniBadge('YOU', cs.primary)],
          ]),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${t.meanPoints.toStringAsFixed(0)} pts/match',
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              _Whisker(t: t, maxPts: maxPts, cs: cs), // consistency = range bar
            ],
          ),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: Icon(Icons.add_circle,
                  color: state == _Pick.picked ? Colors.green : cs.outline),
              tooltip: 'Add to picklist',
              onPressed: () => widget.onPick(
                  t.team, state == _Pick.picked ? _Pick.available : _Pick.picked),
            ),
            IconButton(
              icon: Icon(Icons.block,
                  color: state == _Pick.dnp ? Colors.red : cs.outline),
              tooltip: 'Do not pick',
              onPressed: () => widget.onPick(
                  t.team, state == _Pick.dnp ? _Pick.available : _Pick.dnp),
            ),
          ]),
        );
      },
    );
  }

  Widget _picklist(ColorScheme cs) {
    final statsByTeam = {for (final t in widget.teams) t.team: t};
    final dnp = widget.teams.where((t) => widget.pick[t.team] == _Pick.dnp).toList();
    if (widget.order.isEmpty && dnp.isEmpty) {
      return Center(
        child: Text('No picks yet — add teams from the Board.',
            style: TextStyle(color: cs.onSurfaceVariant)),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (widget.order.isNotEmpty)
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorderItem: widget.onReorder,
            children: [
              for (var i = 0; i < widget.order.length; i++)
                ListTile(
                  key: ValueKey('pl_${widget.order[i]}'),
                  tileColor: Colors.green.withValues(alpha: 0.08),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade600,
                    child: Text('${i + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text('Team ${widget.order[i]}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      '${statsByTeam[widget.order[i]]!.meanPoints.toStringAsFixed(0)} pts/match · ±${statsByTeam[widget.order[i]]!.stdPoints.toStringAsFixed(0)}'),
                  trailing: const Icon(Icons.drag_handle),
                ),
            ],
          ),
        if (dnp.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text('DO NOT PICK',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: Colors.red.shade700)),
          ),
          for (final t in dnp)
            ListTile(
              dense: true,
              leading: const Icon(Icons.block, color: Colors.red),
              title: Text('Team ${t.team}',
                  style: const TextStyle(decoration: TextDecoration.lineThrough)),
            ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════ VARIANT C — tier board

class _VariantC extends StatelessWidget {
  const _VariantC({required this.teams, required this.tier, required this.onTier});
  final List<_TeamStats> teams;
  final Map<int, String> tier;
  final void Function(int, String) onTier;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        children: [
          for (final band in _tiers)
            Expanded(
              child: DragTarget<int>(
                onAcceptWithDetails: (d) => onTier(d.data, band),
                builder: (context, cand, _) {
                  final members = teams
                      .where((t) => tier[t.team] == band)
                      .toList()
                    ..sort((a, b) => b.meanPoints.compareTo(a.meanPoints));
                  final highlight = cand.isNotEmpty;
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: highlight
                          ? cs.primaryContainer.withValues(alpha: 0.5)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: highlight ? cs.primary : cs.outlineVariant,
                          width: highlight ? 2 : 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(band.toUpperCase(),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Expanded(
                          child: members.isEmpty
                              ? Center(
                                  child: Text('drag teams here',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: cs.outline,
                                          fontStyle: FontStyle.italic)))
                              : ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    for (final t in members)
                                      _TierCard(t: t, cs: cs)
                                  ],
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.t, required this.cs});
  final _TeamStats t;
  final ColorScheme cs;

  static const _relColor = [Color(0xFF2E7D32), Color(0xFFF9A825), Color(0xFFC62828)];

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 92,
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        // Consistency = thickness/color of the left accent.
        border: Border(
          left: BorderSide(
              color: _relColor[t.reliabilityBucket],
              width: 5.0 - t.reliabilityBucket * 1.5),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 3)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${t.team}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: t.team == _myTeam ? cs.primary : null)),
          Text('${t.meanPoints.toStringAsFixed(0)} pts',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          Text('±${t.stdPoints.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 10, color: _relColor[t.reliabilityBucket])),
        ],
      ),
    );
    return LongPressDraggable<int>(
      data: t.team,
      feedback: Material(color: Colors.transparent, child: Opacity(opacity: 0.85, child: card)),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: GestureDetector(
        onTap: () => _showDossierStub(context, t),
        child: card,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── shared mini-widgets

/// Stand-in for the real TeamDossierSheet (which exists in production but takes a
/// TeamAnalytics, not the prototype's mock _TeamStats). Just enough to feel the
/// tap-through flow.
void _showDossierStub(BuildContext context, _TeamStats t) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      Widget stat(String label, String value) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          );
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Team ${t.team}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              if (t.team == _myTeam) ...[const SizedBox(width: 8), _miniBadge('YOU', cs.primary)],
              const Spacer(),
              _ReliabilityDot(bucket: t.reliabilityBucket),
            ]),
            const SizedBox(height: 4),
            Text('(prototype stub — real dossier already exists in the app)',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: cs.onSurfaceVariant)),
            const Divider(height: 24),
            stat('Estimated points / match', t.meanPoints.toStringAsFixed(1)),
            stat('Consistency (±1σ)', '±${t.stdPoints.toStringAsFixed(1)} pts'),
            stat('Range (worst – best)', '${t.min.toStringAsFixed(0)} – ${t.max.toStringAsFixed(0)}'),
            const Divider(height: 24),
            stat('Auto points', t.autoMean.toStringAsFixed(1)),
            stat('Teleop points', t.teleopMean.toStringAsFixed(1)),
            stat('Climb success', '${(t.climbPct * 100).toStringAsFixed(0)}%'),
            stat('Matches scouted', '${t.matches}'),
          ],
        ),
      );
    },
  );
}

Widget _miniBadge(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
    );

/// Consistency as a traffic-light dot (Variant A).
class _ReliabilityDot extends StatelessWidget {
  const _ReliabilityDot({required this.bucket});
  final int bucket;
  static const _c = [Color(0xFF2E7D32), Color(0xFFF9A825), Color(0xFFC62828)];
  static const _t = ['steady', 'variable', 'streaky'];
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: _c[bucket], shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(_t[bucket], style: TextStyle(fontSize: 10, color: _c[bucket])),
      ]);
}

/// Consistency as a min–mean–max whisker (Variant B).
class _Whisker extends StatelessWidget {
  const _Whisker({required this.t, required this.maxPts, required this.cs});
  final _TeamStats t;
  final double maxPts;
  final ColorScheme cs;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      double x(double v) => (v / maxPts).clamp(0, 1) * w;
      return SizedBox(
        height: 14,
        child: Stack(children: [
          Positioned(top: 6, left: 0, right: 0, child: Container(height: 2, color: cs.surfaceContainerHighest)),
          Positioned(top: 4, left: x(t.min), width: (x(t.max) - x(t.min)).clamp(2, w), child: Container(height: 6, decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(3)))),
          Positioned(top: 1, left: (x(t.meanPoints) - 5).clamp(0, w - 10), child: Icon(Icons.circle, size: 12, color: cs.primary)),
        ]),
      );
    });
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.frac, required this.fill, required this.track});
  final double frac;
  final Color fill, track;
  @override
  Widget build(BuildContext context) {
    final f = (frac.clamp(0.0, 1.0) * 1000).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Row(children: [
        if (f > 0) Expanded(flex: f, child: Container(height: 8, color: fill)),
        if (f < 1000) Expanded(flex: 1000 - f, child: Container(height: 8, color: track)),
      ]),
    );
  }
}

class _Switcher extends StatelessWidget {
  const _Switcher({required this.label, required this.onPrev, required this.onNext});
  final String label;
  final VoidCallback onPrev, onNext;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(30),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left, color: Colors.white)),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right, color: Colors.white)),
            ]),
          ),
        ),
      ),
    );
  }
}
