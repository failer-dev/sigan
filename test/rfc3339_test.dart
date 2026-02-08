import 'package:sigan/sigan.dart';
import 'package:test/test.dart';

/// RFC 3339 compliance tests.
void main() {
  // ==========================================================================
  // RFC 3339 §5.6 parsing
  // ==========================================================================
  group('RFC 3339 parsing', () {
    test('YYYY-MM-DDTHH:MM:SS.sssZ', () {
      final ts = Timestamp.parse('2025-01-01T12:00:00.000Z');
      expect(ts.timeZone, TimeZone.utc);
      expect(ts.hour, 12);
      expect(ts.millisecond, 0);
    });

    test('YYYY-MM-DDTHH:MM:SS.sss+HH:MM', () {
      final ts = Timestamp.parse('2025-01-01T12:00:00.000+09:00');
      expect(ts.timeZone, TimeZone.kst);
      expect(ts.hour, 12);
    });

    test('negative offset', () {
      final ts = Timestamp.parse('2025-01-01T12:00:00.000-05:00');
      expect(ts.timeZone, TimeZone.est);
    });

    test('no fractional seconds', () {
      final ts = Timestamp.parse('2025-01-01T12:00:00Z');
      expect(ts.millisecond, 0);
      expect(ts.microsecond, 0);
    });

    test('3-digit fractional (milliseconds)', () {
      final ts = Timestamp.parse('2025-01-01T12:00:00.123Z');
      expect(ts.millisecond, 123);
    });

    test('6-digit fractional (microseconds)', () {
      final ts = Timestamp.parse('2025-01-01T12:00:00.123456Z');
      expect(ts.millisecond, 123);
      expect(ts.microsecond, 456);
    });

    test('9-digit fractional (nanoseconds truncated to microseconds)', () {
      final ts = Timestamp.parse('2025-01-01T12:00:00.123456789Z');
      expect(ts.millisecond, 123);
      expect(ts.microsecond, 456);
    });

    test('+00:00 is equivalent to Z', () {
      final z = Timestamp.parse('2025-01-01T12:00:00Z');
      final plus = Timestamp.parse('2025-01-01T12:00:00+00:00');
      expect(z, plus);
      expect(z.timeZone, plus.timeZone);
    });

    test('-00:00 is equivalent to Z', () {
      final z = Timestamp.parse('2025-01-01T12:00:00Z');
      final minus = Timestamp.parse('2025-01-01T12:00:00-00:00');
      expect(z, minus);
    });

    test('space separator (RFC 3339 §5.6 NOTE)', () {
      final ts = Timestamp.parse('2025-01-01 12:00:00Z');
      expect(ts.hour, 12);
    });
  });

  // ==========================================================================
  // Boundary values
  // ==========================================================================
  group('RFC 3339 boundary values', () {
    test('midnight 00:00:00', () {
      final ts = Timestamp.parse('2025-01-01T00:00:00Z');
      expect(ts.hour, 0);
      expect(ts.minute, 0);
      expect(ts.second, 0);
    });

    test('end of day 23:59:59', () {
      final ts = Timestamp.parse('2025-12-31T23:59:59Z');
      expect(ts.hour, 23);
      expect(ts.minute, 59);
      expect(ts.second, 59);
    });

    test('leap second boundary 23:59:59.999999', () {
      final ts = Timestamp.parse('2025-12-31T23:59:59.999999Z');
      expect(ts.second, 59);
      expect(ts.millisecond, 999);
      expect(ts.microsecond, 999);
    });

    test('Feb 29 leap year', () {
      final ts = Timestamp.parse('2024-02-29T12:00:00Z');
      expect(ts.month, 2);
      expect(ts.day, 29);
    });

    test('max positive offset +14:00 (Kiribati)', () {
      final ts = Timestamp.parse('2025-01-01T12:00:00+14:00');
      expect(ts.timeZone.totalMinutes, 840);
      expect(ts.hour, 12);
    });

    test('max negative offset -12:00 (Baker Island)', () {
      final ts = Timestamp.parse('2025-01-01T12:00:00-12:00');
      expect(ts.timeZone.totalMinutes, -720);
    });

    test('half-hour offset +05:30 (India)', () {
      final ts = Timestamp.parse('2025-01-01T12:00:00+05:30');
      expect(ts.timeZone, TimeZone.ist);
    });

    test('45-minute offset +05:45 (Nepal)', () {
      final ts = Timestamp.parse('2025-01-01T12:00:00+05:45');
      expect(ts.timeZone.totalMinutes, 345);
    });
  });

  // ==========================================================================
  // Output compliance
  // ==========================================================================
  group('RFC 3339 output', () {
    test('sigan output matches RFC 3339 pattern', () {
      final ts = Timestamp.of(
        year: 2025, month: 6, day: 15, hour: 10, minute: 30,
        second: 45, millisecond: 123,
        timeZone: TimeZone.kst,
      );
      final iso = ts.toIso8601String();
      expect(
        RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}[+-]\d{2}:\d{2}$')
            .hasMatch(iso),
        isTrue,
        reason: 'Output "$iso" is not valid RFC 3339',
      );
    });

    test('output roundtrips', () {
      final ts = Timestamp.of(
        year: 2025, month: 6, day: 15, hour: 10, minute: 30,
        second: 45, millisecond: 123,
        timeZone: TimeZone.kst,
      );
      expect(Timestamp.parse(ts.toIso8601String()), ts);
    });
  });

  // ==========================================================================
  // Parse → serialize roundtrip
  // ==========================================================================
  group('parse → serialize roundtrip', () {
    final inputs = [
      '2025-01-01T00:00:00.000+00:00',
      '2025-01-01T12:00:00.000+09:00',
      '2025-06-15T23:59:59.999-05:00',
      '2024-02-29T12:00:00.000+00:00',
      '1970-01-01T00:00:00.000+00:00',
      '2025-01-01T05:30:00.000+05:30',
    ];
    for (final input in inputs) {
      test(input, () {
        final ts = Timestamp.parse(input);
        expect(ts.toIso8601String(), input);
      });
    }
  });

  // ==========================================================================
  // Epoch roundtrip
  // ==========================================================================
  group('epoch roundtrip', () {
    test('milliseconds roundtrip across all predefined zones', () {
      final original = Timestamp.of(
        year: 2025, month: 6, day: 15, hour: 12, minute: 30,
        second: 45, millisecond: 123,
        timeZone: TimeZone.utc,
      );
      for (final tz in TimeZone.values) {
        final inZone = original.inZone(tz);
        final ms = inZone.millisecondsSinceEpoch;
        final restored = Timestamp.fromEpochMilliseconds(ms, timeZone: tz);
        expect(restored.millisecondsSinceEpoch, ms, reason: tz.name);
        expect(restored.isAtSameMoment(original), isTrue, reason: tz.name);
      }
    });

    test('microseconds roundtrip', () {
      final original = Timestamp.of(
        year: 2025, month: 3, day: 14, hour: 9, minute: 26,
        second: 53, millisecond: 589,
        timeZone: TimeZone.utc,
      );
      final us = original.microsecondsSinceEpoch;
      final restored = Timestamp.fromEpochMicroseconds(us);
      expect(restored, original);
    });

    test('epoch 0', () {
      final ts = Timestamp.fromEpochMilliseconds(0);
      expect(ts.year, 1970);
      expect(ts.month, 1);
      expect(ts.day, 1);
      expect(ts.hour, 0);
    });

    test('negative epoch (before 1970)', () {
      final ts = Timestamp.fromEpochMilliseconds(-1000);
      expect(ts.year, 1969);
      expect(ts.month, 12);
      expect(ts.day, 31);
    });
  });

  // ==========================================================================
  // Malformed input
  // ==========================================================================
  group('malformed input', () {
    test('empty string', () {
      expect(() => Timestamp.parse(''), throwsArgumentError);
    });

    test('garbage', () {
      expect(() => Timestamp.parse('not-a-date'), throwsArgumentError);
    });

    test('date only (no time)', () {
      // System-timezone dependent. Just verify no crash.
      Timestamp.parse('2025-01-01');
    });

    test('whitespace padded', () {
      final ts = Timestamp.parse('  2025-01-01T12:00:00Z  ');
      expect(ts.hour, 12);
    });

    test('month 13', () {
      expect(
        () {
          final ts = Timestamp.parse('2025-13-01T00:00:00Z');
          if (ts.month != 13) throw ArgumentError('rolled over');
        },
        throwsA(anything),
      );
    });
  });
}
