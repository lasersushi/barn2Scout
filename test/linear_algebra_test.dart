import 'dart:math' as math;

import 'package:barn2scout/core/utils/linear_algebra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cholesky', () {
    // Symmetric positive-definite: leading minors 4, 16, 60 are all > 0.
    final a = [
      [4.0, 2.0, 0.0],
      [2.0, 5.0, 3.0],
      [0.0, 3.0, 6.0],
    ];

    test('solves a known system', () {
      // b = a · [1, -2, 3]
      final x = Cholesky(a).solve([0, 1, 12]);
      expect(x[0], closeTo(1, 1e-12));
      expect(x[1], closeTo(-2, 1e-12));
      expect(x[2], closeTo(3, 1e-12));
    });

    test('one factorisation solves several right-hand sides', () {
      final solver = Cholesky(a);
      final x1 = solver.solve([0, 1, 12]);
      final x2 = solver.solve([4, 2, 0]); // a · [1, 0, 0]
      expect(x1, [
        for (final v in [1.0, -2.0, 3.0]) closeTo(v, 1e-12),
      ]);
      expect(x2, [
        for (final v in [1.0, 0.0, 0.0]) closeTo(v, 1e-12),
      ]);
    });

    test('the identity returns b unchanged', () {
      final x = Cholesky([
        [1.0, 0.0],
        [0.0, 1.0],
      ]).solve([7, -3]);
      expect(x, [closeTo(7, 1e-15), closeTo(-3, 1e-15)]);
    });

    test('rejects a symmetric matrix that is not positive-definite', () {
      // Eigenvalues 3 and -1.
      expect(
        () => Cholesky([
          [1.0, 2.0],
          [2.0, 1.0],
        ]),
        throwsArgumentError,
      );
    });

    test('rejects an asymmetric matrix instead of reading half of it', () {
      expect(
        () => Cholesky([
          [4.0, 1.0],
          [3.0, 4.0],
        ]),
        throwsArgumentError,
      );
    });

    test('rejects NaN rather than returning NaN', () {
      expect(
        () => Cholesky([
          [double.nan, 0.0],
          [0.0, 1.0],
        ]),
        throwsArgumentError,
      );
      expect(
        () => Cholesky([
          [4.0, double.nan],
          [double.nan, 4.0],
        ]),
        throwsArgumentError,
      );
    });

    test('rejects a non-square matrix and a mismatched b', () {
      expect(
        () => Cholesky([
          [1.0, 0.0],
        ]),
        throwsArgumentError,
      );
      expect(() => Cholesky(a).solve([1, 2]), throwsArgumentError);
    });

    test('solves a 60×60 system the shape of an event to round-off', () {
      // MᵀM + I is symmetric positive-definite for any M — the same shape as
      // the ridge-regularised OPR normal equations.
      final rng = math.Random(751);
      const n = 60;
      final m = List.generate(
        n,
        (_) => List.generate(n, (_) => rng.nextDouble() * 2 - 1),
      );
      final big = List.generate(
        n,
        (i) => List.generate(n, (j) {
          var sum = i == j ? 1.0 : 0.0;
          for (var k = 0; k < n; k++) {
            sum += m[k][i] * m[k][j];
          }
          return sum;
        }),
      );
      final b = List.generate(n, (_) => rng.nextDouble() * 100);

      final x = Cholesky(big).solve(b);

      for (var i = 0; i < n; i++) {
        var row = 0.0;
        for (var j = 0; j < n; j++) {
          row += big[i][j] * x[j];
        }
        expect(row, closeTo(b[i], 1e-8), reason: 'row $i');
      }
    });
  });

  group('Cholesky.addOuter', () {
    test('matches factoring a + v·vᵀ from scratch', () {
      final a = [
        [4.0, 2.0, 0.0],
        [2.0, 5.0, 3.0],
        [0.0, 3.0, 6.0],
      ];
      const v = [1.0, 0.0, 2.0];
      final grown = [
        for (var i = 0; i < 3; i++)
          [for (var j = 0; j < 3; j++) a[i][j] + v[i] * v[j]],
      ];

      final updated = Cholesky(a)..addOuter(v);

      expect(updated.solve([1, 2, 3]), [
        for (final x in Cholesky(grown).solve([1, 2, 3])) closeTo(x, 1e-12),
      ]);
    });

    test('builds Λ + AᵀA one alliance row at a time', () {
      // The ridge OPR equations for 200 random three-robot alliances, with
      // λ = 2 for half the teams (a prior of their own) and 1 for the rest.
      final rng = math.Random(751);
      const n = 40;
      final lambdas = [for (var i = 0; i < n; i++) i.isEven ? 2.0 : 1.0];
      final ata = List.generate(
        n,
        (i) => List<double>.generate(n, (j) => i == j ? lambdas[i] : 0),
      );
      final solver = Cholesky.diagonal(lambdas);
      for (var r = 0; r < 200; r++) {
        final row = List<double>.filled(n, 0);
        while (row.where((x) => x > 0).length < 3) {
          row[rng.nextInt(n)] = 1;
        }
        for (var i = 0; i < n; i++) {
          for (var j = 0; j < n; j++) {
            ata[i][j] += row[i] * row[j];
          }
        }
        solver.addOuter(row);
      }
      final b = List.generate(n, (_) => rng.nextDouble() * 100);

      expect(solver.solve(b), [
        for (final x in Cholesky(ata).solve(b)) closeTo(x, 1e-9),
      ]);
    });

    test('rejects a non-positive diagonal entry and a mismatched v', () {
      expect(() => Cholesky.diagonal([1, 0]), throwsArgumentError);
      expect(() => Cholesky.diagonal([double.nan, 1]), throwsArgumentError);
      expect(
        () => Cholesky.diagonal([1, 1]).addOuter([1]),
        throwsArgumentError,
      );
    });
  });
}
