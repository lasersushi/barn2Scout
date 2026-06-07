import 'dart:math' as math;

/// Statistical helpers for match prediction.

const double _sqrt2 = 1.4142135623730951;

/// Standard-normal CDF. Φ(x) = P(Z ≤ x) for Z ~ N(0, 1).
///
/// Used to read a win probability off the point-differential distribution:
/// P(red wins) = P(diff > 0) = 1 - Φ(-μ/σ).
double normalCdf(double x) => 0.5 * (1.0 + erf(x / _sqrt2));

/// Error function — Abramowitz & Stegun 7.1.26 (max abs error ≈ 1.5e-7).
double erf(double x) {
  final sign = x < 0 ? -1.0 : 1.0;
  final ax = x.abs();
  const p = 0.3275911;
  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  final t = 1.0 / (1.0 + p * ax);
  final y = 1.0 -
      (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-ax * ax);
  return sign * y;
}
