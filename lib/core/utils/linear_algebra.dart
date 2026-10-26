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

  /// The factor of a diagonal matrix with [diagonal] (every entry > 0) down
  /// its diagonal: each pivot is the square root of its entry. Grow it with
  /// [addOuter].
  Cholesky.diagonal(List<double> diagonal) : _l = _diagonal(diagonal);

  /// Lower-triangular factor, row-major. Entries above the diagonal stay 0.
  final List<List<double>> _l;

  int get size => _l.length;

  static List<List<double>> _diagonal(List<double> d) {
    // Written as !(x > 0) so NaN is rejected too.
    if (d.any((x) => !(x > 0))) {
      throw ArgumentError('diagonal entries must be positive');
    }
    final n = d.length;
    return [
      for (var i = 0; i < n; i++)
        [for (var j = 0; j < n; j++) i == j ? math.sqrt(d[i]) : 0.0],
    ];
  }

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

  /// Updates the factor in place to that of `a + v·vᵀ`: O(n²), against the
  /// O(n³) of factoring the new matrix from scratch.
  ///
  /// Adding a row v to a matrix A adds v·vᵀ to AᵀA, so OPR's normal equations
  /// can take results one alliance at a time and stay factored throughout.
  /// Column k folds v's k-th entry into pivot k with a rotation, then passes
  /// what's left of v down to the columns after it. Adding v·vᵀ keeps the
  /// matrix positive-definite, so pivots only grow and the update can't fail.
  void addOuter(List<double> v) {
    final n = size;
    if (v.length != n) {
      throw ArgumentError('v has ${v.length} entries, matrix is $n×$n');
    }
    final x = [...v];
    for (var k = 0; k < n; k++) {
      // Nothing left to fold into this column, so it stays as it is.
      if (x[k] == 0) continue;
      final pivot = _l[k][k];
      final r = math.sqrt(pivot * pivot + x[k] * x[k]);
      final c = r / pivot;
      final s = x[k] / pivot;
      _l[k][k] = r;
      for (var i = k + 1; i < n; i++) {
        _l[i][k] = (_l[i][k] + s * x[i]) / c;
        x[i] = c * x[i] - s * _l[i][k];
      }
    }
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
