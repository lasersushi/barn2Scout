import 'dart:math' as math;

import '../../core/utils/linear_algebra.dart';
import 'tba_match.dart';

/// Tunable constants for [RatingModel], in one place so the model can be
/// re-tuned without hunting through the math.
///
/// The values and numbers below come from a one-off sweep over 65 2026
/// events, which isn't in the repo. To re-check one for a new game, change
/// it, re-run `test/prediction_backtest_test.dart`, and compare the 'new
/// model' rows between runs (log-loss gaps under ~0.05 are noise). That
/// backtest replays quals only, so it can't check [playoffSigmaScale].
class RatingConfig {
  const RatingConfig({
    this.priorWeight = 3,
    this.levelPriorWeight = 1,
    this.relativePriorWeight = 2,
    this.relativePriorScale = 0.8,
    this.noHistoryZ = -1,
    this.sigmaPerMeanScore = 0.5,
    this.sigmaPriorWeight = 10,
    this.playoffSigmaScale = 1.1,
  })  : assert(priorWeight > 0),
        assert(levelPriorWeight > 0),
        assert(relativePriorWeight > 0);

  /// λ for a team with a prior of its own (its OPR at an earlier event): how
  /// many matches' worth of evidence that prior counts for. Bigger is
  /// steadier early in an event, but slower to believe a team that really is
  /// better or worse than its prior.
  ///
  /// On 4,899 2026 quals, 65 events with two thirds of teams holding a prior,
  /// 2–4 tied (Brier 0.1460–0.1468) and 1 and 6 were a little worse. 3 was
  /// kept from the middle of that range. Against no priors at all it cut
  /// Brier from 0.1686 to 0.1461 and lifted accuracy from 74.4% to 79.0%.
  final double priorWeight;

  /// λ for a team with no prior, which is pulled toward the event's average
  /// points per robot instead. That says nothing about the team itself, so it
  /// counts for less than a real prior.
  ///
  /// 0.5 and 1 tied at predicting 4,899 2026 quals (Brier 0.1684 vs 0.1686,
  /// within noise), and both beat 1.5–4. 1 was kept for its slightly better
  /// accuracy and early-event Brier.
  final double levelPriorWeight;

  /// λ for a team whose prior is only relative: how far above or below an
  /// average robot it was last season (see [RatingModel.fit]'s
  /// `relativePriors`). Last season is a different game, so it counts for a
  /// little less than a real prior.
  final double relativePriorWeight;

  /// β: how many of this event's average robots one standard deviation of
  /// relative strength is worth. A relative prior of z expects
  /// `level × (1 + β·z)` points.
  ///
  /// Tuned with [relativePriorWeight] and [noHistoryZ] on the same 65 2026
  /// events, using each 2026 team's average z-score over its official 2025
  /// events (better than its last event alone). β 0.8–1.0 and λ 2–3 tied;
  /// smaller β or λ were worse. Against the event average for those teams it
  /// cut Brier from 0.1461 to 0.1395 overall, and from 0.1549 to 0.1395 on
  /// the 22 events where fewer than half the teams had a 2026 prior.
  final double relativePriorScale;

  /// The relative strength assumed for a team with no history to go on,
  /// mostly rookies, who on average are weaker: −1 beat −0.5, 0, −1.5 and −2.
  final double noHistoryZ;

  /// The miss assumed before an event has shown any real ones, as a fraction
  /// of its mean alliance score.
  final double sigmaPerMeanScore;

  /// How many replayed misses that assumption counts for, so a lucky first
  /// few predictions can't make the model overconfident.
  final double sigmaPriorWeight;

  /// Playoff margins stray further from a quals-only fit than qual margins
  /// do: alliances of top picks, defense, strategies quals never showed. So
  /// their σ is widened by this factor. On 986 2026 playoff matches 1.0–1.1
  /// scored best (Brier favoured 1.0, log loss 1.05–1.1), and anything up to
  /// 1.25 was within noise.
  final double playoffSigmaScale;
}

const RatingConfig kRatingConfig = RatingConfig();

/// Each team's expected points per match at one event, fit from TBA match
/// scores alone (no scouting), and how far real margins stray from the fit.
///
/// [expectedPoints] solves ridge-regularised OPR:
///
///     (AᵀA + Λ)·x = Aᵀs + Λ·μ
///
/// * A has a row per scored qual alliance, with a 1 for each robot on it, and
///   s holds those alliances' scores. With Λ = 0 this is exactly OPR.
/// * μ is each team's prior guess: its OPR at an earlier event, or failing
///   that the event's average points per robot.
/// * Λ is diagonal, holding each team's λ: how many matches' worth of
///   evidence its prior counts for. A real prior counts for more
///   ([RatingConfig.priorWeight]) than the event average
///   ([RatingConfig.levelPriorWeight]).
///
/// Plain OPR has no idea what "average" is. Early in an event, with about as
/// many unknowns as alliance results, it lurches to absurd values: 3,423
/// points for one 2026 Curie team after 37 quals. The λ terms pull every team
/// toward its prior until its own matches outweigh it, and also make the
/// equations solvable from the very first match.
class RatingModel {
  const RatingModel({
    this.expectedPoints = const {},
    this.meanTeamPoints = 0,
    this.marginSigma = 0,
    this.config = kRatingConfig,
  });

  /// No data: every prediction is a 50/50 no-call.
  static const empty = RatingModel();

  /// Whether [m] is a qual with both scores posted: one the fit learns from.
  ///
  /// Scores alone decide it, as they do for TBA's own OPRs. Some offseason
  /// uploads never fill in a match's start time, so [TbaMatch.isPlayed]
  /// would miss them.
  static bool isScoredQual(TbaMatch m) =>
      m.compLevel == 'qm' &&
      (m.redScore ?? -1) >= 0 &&
      (m.blueScore ?? -1) >= 0;

  /// Fits the model to the scored quals in [matches]. Playoffs and unscored
  /// matches are ignored, so the full schedule can be passed straight in.
  ///
  /// [priors] are prior guesses at a team's points per match, keyed by team
  /// number: its OPR at an earlier event. A team without one is pulled toward
  /// the event average instead.
  ///
  /// Priors are used as they are, though teams improve between events: in
  /// 2026 they scored about 1.5× their previous event's OPR in March, and
  /// about 1× by the championships. Scaling every prior to how the event was
  /// scoring didn't help on the 2026 replay (it was best not done at all).
  /// A bias every team shares mostly cancels out of the margin, and a team's
  /// own matches soon correct it.
  ///
  /// [relativePriors] are for teams with no prior in points: how many
  /// standard deviations above an average robot each is thought to be, e.g.
  /// from last season, whose game scored in different points. Such a team is
  /// pulled toward `level × (1 + β·z)`, with level the event's average points
  /// per robot and β [RatingConfig.relativePriorScale], so it follows the
  /// event's scoring as quals come in. A team in [priors] ignores it. With
  /// no quals scored and no [priors], there's no scale to put them on, so
  /// they're ignored: the model would otherwise claim to know every team at
  /// 0 points.
  factory RatingModel.fit(
    Iterable<TbaMatch> matches, {
    Map<int, double> priors = const {},
    Map<int, double> relativePriors = const {},
    RatingConfig config = kRatingConfig,
  }) {
    // Play order, so the replay below predicts each match from exactly what
    // was known before it. Match number isn't always that order: a replayed
    // match can run hours after the next one. Without start times, though,
    // match number is the best guess there is.
    final quals = [
      for (final m in matches)
        if (isScoredQual(m)) m,
    ];
    final timed = quals.every((m) => m.actualTime != null);
    quals.sort((a, b) {
      final byTime = timed ? a.actualTime!.compareTo(b.actualTime!) : 0;
      return byTime != 0 ? byTime : a.matchNumber.compareTo(b.matchNumber);
    });

    final priorsByKey = {
      for (final MapEntry(:key, :value) in priors.entries) 'frc$key': value,
    };
    final relativeByKey = {
      if (quals.isNotEmpty || priors.isNotEmpty)
        for (final MapEntry(:key, :value) in relativePriors.entries)
          if (!priors.containsKey(key)) 'frc$key': value,
    };
    final equations = _RidgeEquations(
      {
        ...priorsByKey.keys,
        ...relativeByKey.keys,
        for (final m in quals) ...[...m.redTeams, ...m.blueTeams],
      }.toList()
        ..sort(),
      priorsByKey,
      relativeByKey,
      config,
    );

    // σ comes from replaying the event: each qual is predicted from only the
    // quals before it, as a live prediction would have been then, and its
    // miss is kept. Misses on matches the fit has already seen would come
    // out far too small.
    var squaredMisses = 0.0;
    for (final m in quals) {
      final before = equations.solve();
      double sum(List<String> teams) =>
          teams.fold(0, (total, t) => total + before[t]!);
      final miss =
          (m.redScore! - m.blueScore!) - (sum(m.redTeams) - sum(m.blueTeams));
      squaredMisses += miss * miss;
      equations.add(m);
    }

    final assumed = config.sigmaPerMeanScore * equations.meanAllianceScore;
    final variance =
        (squaredMisses + config.sigmaPriorWeight * assumed * assumed) /
            (quals.length + config.sigmaPriorWeight);

    return RatingModel(
      expectedPoints: equations.solve(),
      meanTeamPoints: equations.level,
      marginSigma: math.sqrt(variance),
      config: config,
    );
  }

  /// Expected points per match, keyed by TBA team key ("frc254", or
  /// "frc254B" for a B-team), for every team the model knows something
  /// about: it played a scored qual here, or it has a prior.
  ///
  /// A team with neither isn't in the equations at all. [pointsOf] gives it
  /// [meanTeamPoints], which is what its row (λx = λ·μ, with μ the event
  /// average) would solve to anyway.
  final Map<String, double> expectedPoints;

  /// The event's average points per robot: what a team the model knows
  /// nothing about is expected to add.
  final double meanTeamPoints;

  /// The typical miss of a qual's predicted margin, in points: σ of actual
  /// minus predicted red − blue score. 0 when there's no data at all.
  ///
  /// It's the RMS of every replayed miss so far, blended with
  /// [RatingConfig.sigmaPerMeanScore] × the mean alliance score counted as
  /// [RatingConfig.sigmaPriorWeight] misses. Before any qual it's only that
  /// assumption. Being an average over the event so far, it runs a little
  /// wide late, when the early, less-informed misses still count. Without
  /// priors that was about 20% on the 2026 replay; priors shrink the early
  /// misses, and what's left is mild ("85%" calls won 91% of the time).
  final double marginSigma;

  final RatingConfig config;

  /// [teamKey]'s expected points, or [meanTeamPoints] if the model knows
  /// nothing about it.
  double pointsOf(String teamKey) => expectedPoints[teamKey] ?? meanTeamPoints;

  /// [marginSigma] for [match], widened for playoffs.
  double sigmaFor(TbaMatch match) => match.compLevel == 'qm'
      ? marginSigma
      : marginSigma * config.playoffSigmaScale;
}

/// The ridge normal equations `(AᵀA + Λ)·x = Aᵀs + Λ·μ`, built up one scored
/// qual at a time so the σ replay can re-solve after each. Λ is diagonal:
/// each team's λ depends on what kind of prior it has.
///
/// Keyed by TBA team key rather than number so a B-team ("frc254B") gets its
/// own share of its alliance's score instead of handing it to its partners.
class _RidgeEquations {
  _RidgeEquations(this.keys, this.priors, this.relativePriors, this.config)
      : index = {for (var i = 0; i < keys.length; i++) keys[i]: i},
        lambdas = [
          for (final k in keys)
            priors.containsKey(k)
                ? config.priorWeight
                : relativePriors.containsKey(k)
                    ? config.relativePriorWeight
                    : config.levelPriorWeight,
        ],
        ats = List<double>.filled(keys.length, 0) {
    factor = Cholesky.diagonal(lambdas);
  }

  /// Every team the fit covers, sorted.
  final List<String> keys;
  final Map<String, int> index;
  final Map<String, double> priors;

  /// Relative priors (in standard deviations) for teams not in [priors].
  final Map<String, double> relativePriors;
  final RatingConfig config;

  /// Each team's λ, in [keys] order.
  final List<double> lambdas;

  /// AᵀA + Λ, kept factored. It starts as Λ, and each alliance adds a row v
  /// to A and so v·vᵀ to AᵀA, which [Cholesky.addOuter] folds into the
  /// factor instead of factoring again before every solve.
  late final Cholesky factor;

  /// Aᵀs: each robot's alliance scores, summed.
  final List<double> ats;

  double _scoreTotal = 0;
  int _alliances = 0;
  int _robots = 0;

  void add(TbaMatch m) {
    for (final (teams, score) in [
      (m.redTeams, m.redScore!),
      (m.blueTeams, m.blueScore!),
    ]) {
      // This alliance's row of A.
      final row = List<double>.filled(keys.length, 0);
      for (final t in teams) {
        row[index[t]!] += 1;
        ats[index[t]!] += score;
      }
      factor.addOuter(row);
      _scoreTotal += score;
      _alliances++;
      _robots += teams.length;
    }
  }

  /// Average points per robot so far: the μ for a team with no prior. Before
  /// any quals the priors' average stands in.
  double get level {
    if (_robots > 0) return _scoreTotal / _robots;
    if (priors.isEmpty) return 0;
    return priors.values.reduce((a, b) => a + b) / priors.length;
  }

  /// Mean alliance score so far, or a three-robot alliance at [level] before
  /// any quals.
  double get meanAllianceScore =>
      _alliances > 0 ? _scoreTotal / _alliances : 3 * level;

  /// Every team's expected points from the quals added so far.
  Map<String, double> solve() {
    final level = this.level;
    double prior(String key) {
      if (priors[key] case final points?) return points;
      if (relativePriors[key] case final z?) {
        return level * (1 + config.relativePriorScale * z);
      }
      return level;
    }

    final x = factor.solve([
      for (var i = 0; i < keys.length; i++)
        ats[i] + lambdas[i] * prior(keys[i]),
    ]);
    return {for (var i = 0; i < keys.length; i++) keys[i]: x[i]};
  }
}
