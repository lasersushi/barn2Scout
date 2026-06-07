# Match predictor — logic prototype

**Question:** Does the normal-distribution win-probability model produce
believable scores and win %s from scouting stats — and how should it treat the
teams in a match that haven't been scouted yet?

Run:

```bash
dart run lib/prototype/predictor_tui.dart
```

Drive it with `n/p` (move slot), `space` (change team), `m` (toggle missing
policy), `1`–`5` (scenarios), `q` (quit).

## What it's testing

- `prediction_model.dart` is the **keeper** — pure math, graduates into
  `lib/core/utils/stats_utils.dart` + `lib/data/models/match_prediction.dart`.
- `predictor_tui.dart` is the throwaway shell.

## Scenarios

1. Blowout — top 3 vs bottom 3 (expect ~99% red)
2. Roughly even (expect near 50/50)
3. Red has ONE unscouted team — **toggle `m` here**: ZERO vs LEAGUE AVERAGE
4. Red has TWO unscouted teams — the policy gap gets bigger
5. Same means, red high-σ vs blue low-σ — does variance alone move the %?

## Design question on the table

The draft plan treats unscouted teams as contributing **0**. Scenario 3/4 +
`[m]` shows what that does vs substituting a **league-average** prior. Pick the
policy that makes scenario 3 look right, then bake it into the real
`MatchPrediction.compute`.

## Verdict

_TBD — fill in after driving it:_
- _Win %s believable? (check scenario 5 especially — σ-only swing)_
- _ZERO or LEAGUE AVERAGE for missing teams?_
- _Anything the model gets obviously wrong?_
