import 'package:sigan/sigan.dart';
import 'package:test/test.dart';

/// Security and robustness tests.
///
/// Covers: input validation in release mode, overflow, extreme values,
/// ReDoS, and adversarial inputs.
void main() {
  // ==========================================================================
  // Date — constructor rejects invalid values
  // ==========================================================================
  group('Date validation', () {
    test('month 0', () {
      expect(() => Date(2025, 0, 1), throwsArgumentError);
    });

    test('month 13', () {
      expect(() => Date(2025, 13, 1), throwsArgumentError);
    });

    test('day 0', () {
      expect(() => Date(2025, 1, 0), throwsArgumentError);
    });

    test('day 32', () {
      expect(() => Date(2025, 1, 32), throwsArgumentError);
    });

    test('Feb 29 non-leap year', () {
      expect(() => Date(2025, 2, 29), throwsArgumentError);
    });

    test('Feb 30 leap year', () {
      expect(() => Date(2024, 2, 30), throwsArgumentError);
    });

    test('Apr 31', () {
      expect(() => Date(2025, 4, 31), throwsArgumentError);
    });

    test('negative year', () {
      expect(() => Date(-1, 1, 1), throwsArgumentError);
    });

    test('year 10000', () {
      expect(() => Date(10000, 1, 1), throwsArgumentError);
    });

    test('Date.parse rejects Feb 30', () {
      expect(() => Date.parse('2025-02-30'), throwsA(anything));
    });

    test('Date.parse rejects month 00', () {
      expect(() => Date.parse('2025-00-01'), throwsA(anything));
    });
  });

  // ==========================================================================
  // Time — constructor rejects invalid values
  // ==========================================================================
  group('Time validation', () {
    test('hour 24', () {
      expect(() => Time(24, 0), throwsArgumentError);
    });

    test('hour -1', () {
      expect(() => Time(-1, 0), throwsArgumentError);
    });

    test('minute 60', () {
      expect(() => Time(12, 60), throwsArgumentError);
    });

    test('minute -1', () {
      expect(() => Time(12, -1), throwsArgumentError);
    });

    test('Time.fromJson rejects 2500', () {
      expect(() => Time.fromJson(2500), throwsArgumentError);
    });

    test('Time.fromJson rejects 1260', () {
      expect(() => Time.fromJson(1260), throwsArgumentError);
    });

    test('Time.fromJson rejects -100', () {
      expect(() => Time.fromJson(-100), throwsArgumentError);
    });

    test('Time.fromJson rejects null', () {
      expect(() => Time.fromJson(null), throwsArgumentError);
    });

    test('Time.fromJson rejects list', () {
      expect(() => Time.fromJson([14, 30]), throwsArgumentError);
    });

    test('Time.fromJson rejects map', () {
      expect(() => Time.fromJson({'hour': 14}), throwsArgumentError);
    });
  });

  // ==========================================================================
  // Timestamp.parse — adversarial strings
  // ==========================================================================
  group('Timestamp.parse adversarial input', () {
    test('empty string', () {
      expect(() => Timestamp.parse(''), throwsArgumentError);
    });

    test('null character embedded', () {
      expect(() => Timestamp.parse('2025-01-01T12:00:00\x00Z'), throwsA(anything));
    });

    test('extremely long string (potential ReDoS)', () {
      final huge = 'A' * 10000;
      expect(() => Timestamp.parse(huge), throwsA(anything));
    });

    test('repeated offset suffixes', () {
      expect(
        () => Timestamp.parse('2025-01-01T12:00:00+09:00+09:00'),
        throwsA(anything),
      );
    });

    test('unicode in date', () {
      expect(() => Timestamp.parse('২০২৫-০১-০১T12:00:00Z'), throwsA(anything));
    });

    test('SQL injection attempt in string', () {
      expect(
        () => Timestamp.parse("2025-01-01'; DROP TABLE timestamps;--"),
        throwsA(anything),
      );
    });

    test('XSS attempt in string', () {
      expect(
        () => Timestamp.parse('<script>alert(1)</script>'),
        throwsA(anything),
      );
    });

    test('newline in string', () {
      expect(
        () => Timestamp.parse('2025-01-01T12:00:00Z\n2025-01-02T12:00:00Z'),
        throwsA(anything),
      );
    });

    test('only whitespace', () {
      expect(() => Timestamp.parse('   '), throwsA(anything));
    });
  });

  // ==========================================================================
  // TimeZone — extreme offsets
  // ==========================================================================
  group('TimeZone extreme offsets', () {
    test('+99:99 rejected', () {
      expect(() => TimeZone.fromOffset('+99:99'), throwsArgumentError);
    });

    test('-99:99 rejected', () {
      expect(() => TimeZone.fromOffset('-99:99'), throwsArgumentError);
    });

    test('+15:00 rejected (beyond +14:00)', () {
      expect(() => TimeZone.fromOffset('+15:00'), throwsArgumentError);
    });

    test('-13:00 rejected (beyond -12:00)', () {
      expect(() => TimeZone.fromOffset('-13:00'), throwsArgumentError);
    });

    test('+14:00 accepted (Kiribati)', () {
      final tz = TimeZone.fromOffset('+14:00');
      expect(tz.totalMinutes, 840);
    });

    test('-12:00 accepted (Baker Island)', () {
      final tz = TimeZone.fromOffset('-12:00');
      expect(tz.totalMinutes, -720);
    });

    test('fromOffset with empty string', () {
      expect(() => TimeZone.fromOffset(''), throwsArgumentError);
    });

    test('fromOffset with garbage', () {
      expect(() => TimeZone.fromOffset('abc'), throwsArgumentError);
    });

    test('fromName with empty string', () {
      expect(() => TimeZone.fromName(''), throwsArgumentError);
    });

    test('fromName is case-sensitive', () {
      expect(() => TimeZone.fromName('kst'), throwsArgumentError);
    });
  });

  // ==========================================================================
  // Timestamp — integer overflow
  // ==========================================================================
  group('Timestamp integer overflow', () {
    test('max epoch microseconds', () {
      final ts = Timestamp.fromEpochMicroseconds(8640000000000000000);
      expect(ts.microsecondsSinceEpoch, 8640000000000000000);
    });

    test('addition with huge duration', () {
      final ts = Timestamp.of(year: 2025, month: 1, day: 1);
      final huge = ts + Duration(days: 100000000);
      expect(huge.microsecondsSinceEpoch, isNot(ts.microsecondsSinceEpoch));
    });

    test('negative epoch', () {
      final ts = Timestamp.fromEpochMicroseconds(-62135596800000000);
      expect(ts.year, isA<int>());
    });
  });

  // ==========================================================================
  // Timestamp.format — pattern injection
  // ==========================================================================
  group('Timestamp.format pattern safety', () {
    test('pattern with no tokens passes through', () {
      final ts = Timestamp.of(year: 2025, month: 1, day: 1);
      expect(ts.format('hello world'), 'hello world');
    });

    test('pattern with HTML', () {
      final ts = Timestamp.of(year: 2025, month: 1, day: 1);
      final result = ts.format('<b>yyyy</b>');
      expect(result, '<b>2025</b>');
    });

    test('pattern with format specifiers does not crash', () {
      final ts = Timestamp.of(year: 2025, month: 1, day: 1);
      expect(ts.format('%s %d yyyy'), '%s %d 2025');
    });

    test('empty pattern', () {
      final ts = Timestamp.of(year: 2025, month: 1, day: 1);
      expect(ts.format(''), '');
    });

    test('extremely long pattern', () {
      final ts = Timestamp.of(year: 2025, month: 1, day: 1);
      final pattern = 'yyyy-' * 10000;
      final result = ts.format(pattern);
      expect(result.length, greaterThan(0));
    });
  });

  // ==========================================================================
  // Date.parse — adversarial
  // ==========================================================================
  group('Date.parse adversarial', () {
    test('too many segments', () {
      expect(() => Date.parse('2025-01-01-01'), throwsArgumentError);
    });

    test('too few segments', () {
      expect(() => Date.parse('2025-01'), throwsArgumentError);
    });

    test('non-numeric', () {
      expect(() => Date.parse('abcd-ef-gh'), throwsA(anything));
    });

    test('huge year', () {
      expect(() => Date.parse('99999999-01-01'), throwsA(anything));
    });

    test('empty string', () {
      expect(() => Date.parse(''), throwsA(anything));
    });

    test('negative day', () {
      expect(() => Date.parse('2025-01--1'), throwsA(anything));
    });
  });

  // ==========================================================================
  // Equality edge cases
  // ==========================================================================
  group('equality edge cases', () {
    test('Timestamp == non-Timestamp always false', () {
      final ts = Timestamp.of(year: 2025, month: 1, day: 1);
      // ignore: unrelated_type_equality_checks
      expect(ts == 'not a timestamp', isFalse);
      // ignore: unrelated_type_equality_checks
      expect(ts == 42, isFalse);
      expect(ts == (null as dynamic), isFalse);
    });

    test('Date == non-Date always false', () {
      final d = Date(2025, 1, 1);
      // ignore: unrelated_type_equality_checks
      expect(d == '2025-01-01', isFalse);
    });

    test('TimeZone == non-TimeZone always false', () {
      // ignore: unrelated_type_equality_checks
      expect(TimeZone.utc == 0, isFalse);
    });

    test('Time == non-Time always false', () {
      final t = Time(14, 30);
      // ignore: unrelated_type_equality_checks
      expect(t == 1430, isFalse);
    });
  });

  // ==========================================================================
  // Serialization roundtrip integrity
  // ==========================================================================
  group('serialization integrity', () {
    test('Timestamp toJson/fromJson roundtrip preserves instant', () {
      final ts = Timestamp.of(
        year: 2025, month: 6, day: 15, hour: 14, minute: 30,
        second: 45, millisecond: 123, timeZone: TimeZone.kst,
      );
      final json = ts.toJson();
      final restored = Timestamp.fromJson(json);
      expect(restored, ts);
      expect(restored.timeZone, ts.timeZone);
    });

    test('Date toJson/fromJson roundtrip', () {
      final d = Date(2025, 2, 28);
      final restored = Date.fromJson(d.toJson());
      expect(restored, d);
    });

    test('Time toJson/fromJson roundtrip', () {
      final t = Time(0, 0);
      final restored = Time.fromJson(t.toJson());
      expect(restored, t);
    });

    test('Time midnight edge', () {
      final t = Time(0, 0);
      expect(t.toJson(), 0);
      expect(Time.fromJson(0), t);
    });

    test('Time 23:59 edge', () {
      final t = Time(23, 59);
      expect(t.toJson(), 2359);
      expect(Time.fromJson(2359), t);
    });
  });
}
