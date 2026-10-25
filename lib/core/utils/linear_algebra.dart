import 'dart:math' as math;

/// Small dense linear algebra for the team rating model.

/// Cholesky factorisation of a symmetric positive-definite matrix: `a = L·Lᵀ`,
/// with `L` lower-triangular. Factor once, then [solve] any number of
/// right-hand sides against it.
///
/// The OPR normal equations `(AᵀA)·x = Aᵀs` are always symmetric, and adding a
/// ridge prior (λ > 0 on the diagonal) makes them positive-definite — exactly
/// the case Cholesky is built for. It does about half the work of Gaussian
/// elimination and needs no pivoting.
class Cholesky {
  /// Factors [a]. Throws [ArgumentError] if [a] isn't square, isn't
  /// symmetric, or isn't positive-definite — a zero, negative or NaN pivot
  /// shows up while factoring.
  Cholesky(List<List<double>> a) : _l = _factor(a);

  /// Lower-triangular factor, row-major. Entries above the diagonal stay 0.
  final List<List<double>> _l;

  int get size => _l.length;

  static List<List<double>> _factor(List<List<double>> a) {
    final n = a.length;
    if (a.any((row) => row.length != n)) {
      throw ArgumentError('matrix must be square');
    }
    // Only the lower triangle is read below, so an asymmetric matrix would be
    // silently misread rather than rejected.
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < i; j++) {
        final scale = math.max(1.0, math.max(a[i][j].abs(), a[j][i].abs()));
        if ((a[i][j] - a[j][i]).abs() > 1e-9 * scale) {
          throw ArgumentError('matrix must be symmetric');
        }
      }
    }
    final l = List.generate(n, (_) => List<double>.filled(n, 0));
    for (var i = 0; i < n; i++) {
      for (var j = 0; j <= i; j++) {
        var sum = a[i][j];
        for (var k = 0; k < j; k++) {
          sum -= l[i][k] * l[j][k];
        }
        if (i == j) {
          // Written as !(sum > 0), not sum <= 0, so NaN is rejected too.
          if (!(sum > 0)) {
            throw ArgumentError('matrix is not positive-definite');
          }
          l[i][i] = math.sqrt(sum);
        } else {
          l[i][j] = sum / l[j][j];
        }
      }
    }
    return l;
  }

  /// Solves `a·x = b` for the factored `a`: forward substitution through `L`,
  /// then back substitution through `Lᵀ`.
  List<double> solve(List<double> b) {
    final n = size;
    if (b.length != n) {
      throw ArgumentError('b has ${b.length} entries, matrix is $n×$n');
    }
    // L·y = b
    final y = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      var sum = b[i];
      for (var k = 0; k < i; k++) {
        sum -= _l[i][k] * y[k];
      }
      y[i] = sum / _l[i][i];
    }
    // Lᵀ·x = y — column i of L is row i of Lᵀ.
    final x = List<double>.filled(n, 0);
    for (var i = n - 1; i >= 0; i--) {
      var sum = y[i];
      for (var k = i + 1; k < n; k++) {
        sum -= _l[k][i] * x[k];
      }
      x[i] = sum / _l[i][i];
    }
    return x;
  }
}
