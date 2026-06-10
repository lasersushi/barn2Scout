/// Pure helpers for comparing dotted version strings — the release tags on
/// GitHub ('v26.2.0') against the runtime versionName ('26.2.0').
library;

/// Parses 'v26.1.0.2', '26.2.0', or 'v26.0.1.0-alpha' into `[26, 1, 0, 2]`
/// etc. Strips a leading 'v'/'V' and anything from the first '-' or '+'
/// onward. Returns null when any remaining segment is empty or non-numeric.
List<int>? parseDottedVersion(String raw) {
  var s = raw.trim();
  if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
  final dash = s.indexOf('-');
  if (dash != -1) s = s.substring(0, dash);
  final plus = s.indexOf('+');
  if (plus != -1) s = s.substring(0, plus);
  if (s.isEmpty) return null;

  final segments = <int>[];
  for (final part in s.split('.')) {
    final n = int.tryParse(part);
    if (n == null || n < 0) return null;
    segments.add(n);
  }
  return segments;
}

/// True only when [remote] is strictly newer than [local] (segment-wise,
/// shorter side zero-padded). False when either side fails to parse — a
/// version we can't read must never be offered as an update.
bool isRemoteNewer({required String local, required String remote}) {
  final l = parseDottedVersion(local);
  final r = parseDottedVersion(remote);
  if (l == null || r == null) return false;

  final length = l.length > r.length ? l.length : r.length;
  for (var i = 0; i < length; i++) {
    final li = i < l.length ? l[i] : 0;
    final ri = i < r.length ? r[i] : 0;
    if (ri != li) return ri > li;
  }
  return false; // equal
}
