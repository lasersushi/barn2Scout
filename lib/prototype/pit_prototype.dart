// PROTOTYPE — throwaway. Question: what should the pit scouting form and
// Records Match/Pit toggle look like?
//
// Three variants, switchable via the bottom bar:
//   A — SegmentedButton toggle + sectioned list form
//   B — TabBar toggle + card-grouped form
//   C — FilterChip toggle + compact side-by-side form
//
// Run: flutter run -t lib/prototype/pit_prototype.dart

import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      home: const _PrototypeShell(),
    ),
  );
}

// ─────────────────────────────────────────────── prototype shell + switcher

class _PrototypeShell extends StatefulWidget {
  const _PrototypeShell();

  @override
  State<_PrototypeShell> createState() => _PrototypeShellState();
}

class _PrototypeShellState extends State<_PrototypeShell> {
  int _variant = 0;
  static const _labels = ['A — Segmented + Sections', 'B — TabBar + Cards', 'C — Chips + Compact'];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IndexedStack(
          index: _variant,
          children: const [_VariantA(), _VariantB(), _VariantC()],
        ),
        Positioned(
          bottom: 24,
          left: 32,
          right: 32,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(32),
            color: Colors.black87,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                    onPressed: () => setState(
                        () => _variant = (_variant - 1 + 3) % 3),
                  ),
                  Text(
                    _labels[_variant],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                    onPressed: () =>
                        setState(() => _variant = (_variant + 1) % 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────── shared fake data

final _fakeMatchRecords = [
  _MatchRecord(team: 254, match: 3, scouter: 'Lucas', synced: true),
  _MatchRecord(team: 1678, match: 3, scouter: 'Alex', synced: true),
  _MatchRecord(team: 751, match: 3, scouter: 'Lucas', synced: false),
];

final _fakePitRecords = [
  _PitRecord(team: 254, scouter: 'Lucas', synced: true),
  _PitRecord(team: 1678, scouter: 'Alex', synced: false),
];

class _MatchRecord {
  const _MatchRecord({required this.team, required this.match, required this.scouter, required this.synced});
  final int team, match;
  final String scouter;
  final bool synced;
}

class _PitRecord {
  const _PitRecord({required this.team, required this.scouter, required this.synced});
  final int team;
  final String scouter;
  final bool synced;
}

// ════════════════════════════════════════════════════════════════════════════
// VARIANT A — SegmentedButton toggle + sectioned list form
// ════════════════════════════════════════════════════════════════════════════

class _VariantA extends StatefulWidget {
  const _VariantA();
  @override
  State<_VariantA> createState() => _VariantAState();
}

class _VariantAState extends State<_VariantA> {
  bool _showPit = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Records'),
        actions: [
          IconButton(icon: const Icon(Icons.sync_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Match'), icon: Icon(Icons.sports_score)),
                ButtonSegment(value: true, label: Text('Pit'), icon: Icon(Icons.build_outlined)),
              ],
              selected: {_showPit},
              onSelectionChanged: (s) => setState(() => _showPit = s.first),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPit
            ? Navigator.push(context, MaterialPageRoute(builder: (_) => const _PitFormA()))
            : null,
        icon: const Icon(Icons.add),
        label: Text(_showPit ? 'Pit Scout' : 'Scout'),
      ),
      body: _showPit ? _PitListA() : _MatchListA(),
    );
  }
}

class _MatchListA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _fakeMatchRecords.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final r = _fakeMatchRecords[i];
        return ListTile(
          leading: CircleAvatar(child: Text('${r.team}'[0])),
          title: Text('Team ${r.team} · Match ${r.match}'),
          subtitle: Text('${r.scouter} · Jun 7'),
          trailing: Icon(r.synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: r.synced ? Colors.green : Theme.of(context).colorScheme.outline),
        );
      },
    );
  }
}

class _PitListA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _fakePitRecords.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final r = _fakePitRecords[i];
        return ListTile(
          leading: CircleAvatar(child: Text('${r.team}'[0])),
          title: Text('Team ${r.team} · Pit'),
          subtitle: Text('${r.scouter} · Jun 7'),
          trailing: Icon(r.synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: r.synced ? Colors.green : Theme.of(context).colorScheme.outline),
        );
      },
    );
  }
}

class _PitFormA extends StatefulWidget {
  const _PitFormA();
  @override
  State<_PitFormA> createState() => _PitFormAState();
}

class _PitFormAState extends State<_PitFormA> {
  String? _drivetrain;
  int _weight = 0, _width = 0, _length = 0;
  bool _autoLeave = false, _autoL1 = false, _autoL2 = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pit Scout — Team 254')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _SectionHeader('Hardware'),
          _ChoiceTile(
            label: 'Drivetrain',
            options: const ['Swerve', 'Tank', 'Mecanum', 'Other'],
            value: _drivetrain,
            onChanged: (v) => setState(() => _drivetrain = v),
          ),
          _CounterTile(label: 'Weight (lbs)', value: _weight,
              onChanged: (v) => setState(() => _weight = v)),
          _CounterTile(label: 'Width (in)', value: _width,
              onChanged: (v) => setState(() => _width = v)),
          _CounterTile(label: 'Length (in)', value: _length,
              onChanged: (v) => setState(() => _length = v)),
          _SectionHeader('Auto Capabilities'),
          SwitchListTile(
            title: const Text('Can leave starting line'),
            value: _autoLeave,
            onChanged: (v) => setState(() => _autoLeave = v),
          ),
          SwitchListTile(
            title: const Text('Can score Level 1'),
            value: _autoL1,
            onChanged: (v) => setState(() => _autoL1 = v),
          ),
          SwitchListTile(
            title: const Text('Can score Level 2'),
            value: _autoL2,
            onChanged: (v) => setState(() => _autoL2 = v),
          ),
          _SectionHeader('Observations'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Notes about this robot...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save'),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// VARIANT B — TabBar toggle + card-grouped form
// ════════════════════════════════════════════════════════════════════════════

class _VariantB extends StatefulWidget {
  const _VariantB();
  @override
  State<_VariantB> createState() => _VariantBState();
}

class _VariantBState extends State<_VariantB> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Records'),
        actions: [
          IconButton(icon: const Icon(Icons.sync_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.sports_score), text: 'Match'),
            Tab(icon: Icon(Icons.build_outlined), text: 'Pit'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tab.index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const _PitFormB()));
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tab.index == 0 ? 'Scout' : 'Pit Scout'),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _MatchListA(), // reuse same list
          ListView.separated(
            itemCount: _fakePitRecords.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = _fakePitRecords[i];
              return ListTile(
                leading: CircleAvatar(child: Text('${r.team}'[0])),
                title: Text('Team ${r.team} · Pit Scout'),
                subtitle: Text('${r.scouter} · Jun 7'),
                trailing: Icon(r.synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                    color: r.synced ? Colors.green : Theme.of(context).colorScheme.outline),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PitFormB extends StatefulWidget {
  const _PitFormB();
  @override
  State<_PitFormB> createState() => _PitFormBState();
}

class _PitFormBState extends State<_PitFormB> {
  String? _drivetrain;
  int _weight = 0, _width = 0, _length = 0;
  bool _autoLeave = false, _autoL1 = false, _autoL2 = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Pit Scout — Team 254')),
      body: ListView(
        padding: const EdgeInsets.all(12).copyWith(bottom: 100),
        children: [
          // Hardware card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hardware', style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  const Text('Drivetrain', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Swerve', 'Tank', 'Mecanum', 'Other'].map((opt) =>
                      ChoiceChip(
                        label: Text(opt),
                        selected: _drivetrain == opt,
                        onSelected: (v) => setState(() => _drivetrain = v ? opt : null),
                      ),
                    ).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _CounterCard(label: 'Weight\n(lbs)', value: _weight,
                          onChanged: (v) => setState(() => _weight = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _CounterCard(label: 'Width\n(in)', value: _width,
                          onChanged: (v) => setState(() => _width = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _CounterCard(label: 'Length\n(in)', value: _length,
                          onChanged: (v) => setState(() => _length = v))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Auto capabilities card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Auto Capabilities', style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Leaves starting line'),
                    value: _autoLeave,
                    onChanged: (v) => setState(() => _autoLeave = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Scores Level 1'),
                    value: _autoL1,
                    onChanged: (v) => setState(() => _autoL1 = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Scores Level 2'),
                    value: _autoL2,
                    onChanged: (v) => setState(() => _autoL2 = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Observations card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Observations', style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'What did you notice about this robot?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save'),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// VARIANT C — FilterChip toggle + compact side-by-side form
// ════════════════════════════════════════════════════════════════════════════

class _VariantC extends StatefulWidget {
  const _VariantC();
  @override
  State<_VariantC> createState() => _VariantCState();
}

class _VariantCState extends State<_VariantC> {
  bool _showPit = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Records'),
        actions: [
          IconButton(icon: const Icon(Icons.sync_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPit
            ? Navigator.push(context, MaterialPageRoute(builder: (_) => const _PitFormC()))
            : null,
        icon: const Icon(Icons.add),
        label: Text(_showPit ? 'Pit Scout' : 'Scout'),
      ),
      body: Column(
        children: [
          // Filter chip row
          Container(
            color: cs.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Match'),
                  selected: !_showPit,
                  avatar: const Icon(Icons.sports_score, size: 16),
                  onSelected: (_) => setState(() => _showPit = false),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pit'),
                  selected: _showPit,
                  avatar: const Icon(Icons.build_outlined, size: 16),
                  onSelected: (_) => setState(() => _showPit = true),
                ),
                const Spacer(),
                if (_showPit)
                  Text('${_fakePitRecords.length} teams scouted',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _showPit
                ? ListView.separated(
                    itemCount: _fakePitRecords.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = _fakePitRecords[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.primaryContainer,
                          child: Text('${r.team}', style: TextStyle(color: cs.onPrimaryContainer, fontSize: 12)),
                        ),
                        title: Text('Team ${r.team}'),
                        subtitle: Text('Pit · ${r.scouter} · Jun 7'),
                        trailing: Icon(r.synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                            color: r.synced ? Colors.green : cs.outline),
                      );
                    },
                  )
                : _MatchListA(),
          ),
        ],
      ),
    );
  }
}

class _PitFormC extends StatefulWidget {
  const _PitFormC();
  @override
  State<_PitFormC> createState() => _PitFormCState();
}

class _PitFormCState extends State<_PitFormC> {
  String? _drivetrain;
  int _weight = 0, _width = 0, _length = 0;
  bool _autoLeave = false, _autoL1 = false, _autoL2 = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Pit Scout — Team 254')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(bottom: 100),
        children: [
          // Drivetrain as horizontal chips row (no section header)
          Text('Drivetrain', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Row(
            children: ['Swerve', 'Tank', 'Mecanum', 'Other'].map((opt) =>
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(opt),
                  selected: _drivetrain == opt,
                  onSelected: (v) => setState(() => _drivetrain = v ? opt : null),
                ),
              ),
            ).toList(),
          ),
          const SizedBox(height: 16),
          // Dimensions in a compact row
          Text('Dimensions & Weight', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _CompactCounter(label: 'Weight (lbs)', value: _weight,
                  onChanged: (v) => setState(() => _weight = v))),
              const SizedBox(width: 8),
              Expanded(child: _CompactCounter(label: 'Width (in)', value: _width,
                  onChanged: (v) => setState(() => _width = v))),
              const SizedBox(width: 8),
              Expanded(child: _CompactCounter(label: 'Length (in)', value: _length,
                  onChanged: (v) => setState(() => _length = v))),
            ],
          ),
          const SizedBox(height: 16),
          // Auto capabilities as toggle chips
          Text('Auto Capabilities', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Leaves line'),
                selected: _autoLeave,
                onSelected: (v) => setState(() => _autoLeave = v),
              ),
              FilterChip(
                label: const Text('Scores L1'),
                selected: _autoL1,
                onSelected: (v) => setState(() => _autoL1 = v),
              ),
              FilterChip(
                label: const Text('Scores L2'),
                selected: _autoL2,
                onSelected: (v) => setState(() => _autoL2 = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Observations', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          TextField(
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'What did you notice about this robot?',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save'),
      ),
    );
  }
}

// ─────────────────────────────────────────────── shared sub-widgets

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.label, required this.options, required this.value, required this.onChanged});
  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: options.map((opt) => ChoiceChip(
              label: Text(opt),
              selected: value == opt,
              onSelected: (v) => onChanged(v ? opt : null),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _CounterTile extends StatelessWidget {
  const _CounterTile({required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 32,
            child: Text('$value', textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 18,
                icon: const Icon(Icons.remove),
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
              ),
              IconButton(
                iconSize: 18,
                icon: const Icon(Icons.add),
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactCounter extends StatelessWidget {
  const _CompactCounter({required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: value > 0 ? () => onChanged(value - 1) : null,
              child: Icon(Icons.remove_circle, color: value > 0 ? cs.primary : cs.outline),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('$value',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            GestureDetector(
              onTap: () => onChanged(value + 1),
              child: Icon(Icons.add_circle, color: cs.primary),
            ),
          ],
        ),
      ],
    );
  }
}
