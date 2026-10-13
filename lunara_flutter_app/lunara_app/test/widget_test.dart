import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/models.dart';

void main() {
  test('day keys are zero-padded', () {
    expect(dayKey(DateTime(2026, 3, 7)), '2026-03-07');
  });

  test('minusDays crosses month boundaries', () {
    expect(minusDays(DateTime(2026, 3, 1), 1), DateTime(2026, 2, 28));
  });
}
