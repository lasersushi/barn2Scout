import 'dart:math' as math;

/// One scored prediction from the backtest: what the model said before the
/// match, and what actually happened.
class Forecast {
  const Forecast({
    required this.eventKey,
    required this.phase,
    required this.redWinPct,
    required this.predictedMargin,
    required this.redScore,
    required this.blueScore,
    this.shown = true,
  });

  final String eventKey;

  /// Which third of the event's quals the match fell in: 0 early, 1 middle,
  /// 2 late. Early is where a model has the least to go on.
  final int phase;

  /// The model's P(red wins), 0..1.
  final double redWinPct;

  /// Predicted red score minus predicted blue score.
  final double predictedMargin;

  final int redScore;
  final int blueScore;

  /// Whether the app would have drawn this prediction at all
  /// (`MatchPrediction.hasData`).
  final bool shown;

  /// 1 = red won, 0 = blue won, 0.5 = tie.
  double get outcome =>
      redScore > blueScore ? 1 : (redScore < blueScore ? 0 : 0.5);

  /// A 50/50 forecast: the model had nothing to separate the alliances.
  bool get isNoCall => (redWinPct - 0.5).abs() < 1e-6;
}

double _mean(Iterable<double> xs) {
  var sum = 0.0;
  var n = 0;
  for (final x in xs) {
    sum += x;
    n++;
  }
  return n == 0 ? double.nan : sum / n;
}

double _median(Iterable<double> xs) {
  final sorted = xs.toList()..sort();
  if (sorted.isEmpty) return double.nan;
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}

/// Mean squared error of the win probability. 0 is perfect; always saying 50%
/// scores 0.25.
double brierScore(Iterable<Forecast> fs) =>
    _mean(fs.map((f) => math.pow(f.redWinPct - f.outcome, 2).toDouble()));

/// Probabilities are clamped to [logLossFloor, 1 − logLossFloor] before
/// [logLoss] scores them, so a single confident miss costs at most
/// ln(1 / 1e-4) ≈ 9.2 nats. Never change it: every baseline depends on it.
const logLossFloor = 1e-4;

/// Average surprise in nats. Unlike Brier it punishes confident misses
/// steeply (up to the [logLossFloor] cap), so it's the metric that exposes
/// overconfidence. Always saying 50% scores ln 2 ≈ 0.693.
double logLoss(Iterable<Forecast> fs) => _mean(fs.map((f) {
      final p = f.redWinPct.clamp(logLossFloor, 1 - logLossFloor);
      return -(f.outcome * math.log(p) + (1 - f.outcome) * math.log(1 - p));
    }));

/// Forecasts the [logLossFloor] clamp touched — each is a near-certain call.
int clampedCount(Iterable<Forecast> fs) => fs
    .where((f) => f.redWinPct < logLossFloor || f.redWinPct > 1 - logLossFloor)
    .length;

/// Share of decided (non-tie) matches where the favourite won. A 50/50
/// forecast picks nobody, so it earns half credit rather than counting as a
/// pick for blue.
double accuracy(Iterable<Forecast> fs) =>
    _mean(fs.where((f) => f.outcome != 0.5).map((f) {
      if (f.isNoCall) return 0.5;
      return (f.redWinPct > 0.5) == (f.outcome == 1) ? 1.0 : 0.0;
    }));

/// Root-mean-square error of the predicted score margin, in points.
double marginRmse(Iterable<Forecast> fs) => math.sqrt(_mean(fs.map((f) =>
    math.pow(f.predictedMargin - (f.redScore - f.blueScore), 2).toDouble())));

/// [marginRmse] of always predicting a 0-point margin — the bar a margin model
/// has to clear before its scores mean anything.
double zeroMarginRmse(Iterable<Forecast> fs) => math.sqrt(
    _mean(fs.map((f) => math.pow(f.redScore - f.blueScore, 2).toDouble())));

/// Median absolute margin error. RMSE squares its errors, so a few absurd
/// predictions can dominate it; the median shows the typical miss.
double medianMarginError(Iterable<Forecast> fs) => _median(
    fs.map((f) => (f.predictedMargin - (f.redScore - f.blueScore)).abs()));

/// One row per model.
String forecastTable(Map<String, List<Forecast>> rows) {
  final b = StringBuffer()
    ..writeln('${'model'.padRight(22)}    n    acc   Brier  LogLoss '
        '(clamped)  margin RMSE (0-margin)  median | Brier early    mid   late');
  for (final MapEntry(key: label, value: fs) in rows.entries) {
    String phase(int p) =>
        brierScore(fs.where((f) => f.phase == p)).toStringAsFixed(4);
    b.writeln('${label.padRight(22)} ${fs.length.toString().padLeft(4)}  '
        '${accuracy(fs).toStringAsFixed(3)}  '
        '${brierScore(fs).toStringAsFixed(4)}   '
        '${logLoss(fs).toStringAsFixed(4)} '
        '${'(${clampedCount(fs)})'.padLeft(9)}  '
        '${marginRmse(fs).toStringAsFixed(1).padLeft(11)} '
        '${'(${zeroMarginRmse(fs).toStringAsFixed(1)})'.padLeft(10)}  '
        '${medianMarginError(fs).toStringAsFixed(1).padLeft(6)} |      '
        '${phase(0)} ${phase(1)} ${phase(2)}');
  }
  return b.toString();
}

/// Predictions grouped into tenths by predicted P(red wins), against how
/// often red actually won. A calibrated model's two columns match. 50/50 calls
/// get their own row so they don't land in a bucket by rounding.
String calibrationTable(String label, List<Forecast> fs) {
  final b = StringBuffer()..writeln('calibration — $label');
  void row(String said, List<Forecast> group) {
    if (group.isEmpty) return;
    final avgSaid = 100 * _mean(group.map((f) => f.redWinPct));
    final won = 100 * _mean(group.map((f) => f.outcome));
    b.writeln('${'  $said'.padRight(18)}n=${group.length.toString().padLeft(4)}'
        '  avg said ${avgSaid.toStringAsFixed(1)}%'
        '  red won ${won.toStringAsFixed(1)}%');
  }

  row('no call (50%)', fs.where((f) => f.isNoCall).toList());
  for (var bucket = 0; bucket < 10; bucket++) {
    row(
      'said ${bucket * 10}-${bucket * 10 + 10}%',
      fs
          .where((f) =>
              !f.isNoCall && math.min((f.redWinPct * 10).floor(), 9) == bucket)
          .toList(),
    );
  }
  return b.toString();
}
