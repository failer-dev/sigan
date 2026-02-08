import 'package:sigan/sigan.dart';
import 'package:test/test.dart';

void main() {
  group('Timestamp', () {
    // =============================================
    // Construction: Timestamp.of
    // =============================================
    group('Timestamp.of', () {
      test('basic UTC', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 12,
          timeZone: TimeZone.utc,
        );
        expect(ts.year, 2025);
        expect(ts.month, 1);
        expect(ts.day, 1);
        expect(ts.hour, 12);
        expect(ts.minute, 0);
        expect(ts.second, 0);
        expect(ts.timeZone, TimeZone.utc);
      });

      test('KST components → correct UTC', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 12,
          timeZone: TimeZone.kst,
        );
        expect(ts.hour, 12); // local
        expect(ts.toDateTime().hour, 3); // UTC = 12 - 9
      });

      test('midnight KST → previous day UTC', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 0,
          timeZone: TimeZone.kst,
        );
        final utc = ts.toDateTime();
        expect(utc.year, 2024);
        expect(utc.month, 12);
        expect(utc.day, 31);
        expect(utc.hour, 15);
      });

      test('negative offset date change (PST)', () {
        // 2025-01-01 03:00 UTC → 2024-12-31 19:00 PST
        final ts = Timestamp.of(
          year: 2024, month: 12, day: 31, hour: 19,
          timeZone: TimeZone.pst,
        );
        expect(ts.toDateTime().year, 2025);
        expect(ts.toDateTime().month, 1);
        expect(ts.toDateTime().day, 1);
        expect(ts.toDateTime().hour, 3);
      });

      test('year boundary: 2024-12-31 23:00 UTC → 2025-01-01 08:00 KST', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 8,
          timeZone: TimeZone.kst,
        );
        final utc = ts.toDateTime();
        expect(utc.year, 2024);
        expect(utc.month, 12);
        expect(utc.day, 31);
        expect(utc.hour, 23);
      });

      test('with milliseconds', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, millisecond: 123,
          timeZone: TimeZone.utc,
        );
        expect(ts.millisecond, 123);
      });

      test('defaults to UTC', () {
        final ts = Timestamp.of(year: 2025, month: 1, day: 1);
        expect(ts.timeZone, TimeZone.utc);
      });
    });

    // =============================================
    // Construction: Timestamp.now
    // =============================================
    group('Timestamp.now', () {
      test('returns current time', () {
        final before = DateTime.now().toUtc();
        final ts = Timestamp.now();
        final after = DateTime.now().toUtc();
        expect(ts.microsecondsSinceEpoch,
            greaterThanOrEqualTo(before.microsecondsSinceEpoch));
        expect(ts.microsecondsSinceEpoch,
            lessThanOrEqualTo(after.microsecondsSinceEpoch));
      });

      test('with timezone', () {
        final ts = Timestamp.now(timeZone: TimeZone.kst);
        expect(ts.timeZone, TimeZone.kst);
      });
    });

    // =============================================
    // Construction: Timestamp.parse
    // =============================================
    group('Timestamp.parse', () {
      test('with Z suffix', () {
        final ts = Timestamp.parse('2025-01-01T12:00:00.000Z');
        expect(ts.timeZone, TimeZone.utc);
        expect(ts.hour, 12);
      });

      test('with +09:00', () {
        final ts = Timestamp.parse('2025-01-01T12:00:00.000+09:00');
        expect(ts.timeZone, TimeZone.kst);
        expect(ts.hour, 12);
      });

      test('with +0900', () {
        final ts = Timestamp.parse('2025-01-01T12:00:00.000+0900');
        expect(ts.timeZone, TimeZone.kst);
      });

      test('with +09', () {
        final ts = Timestamp.parse('2025-01-01T12:00:00+09');
        expect(ts.timeZone, TimeZone.kst);
      });

      test('with -05:00', () {
        final ts = Timestamp.parse('2025-01-01T12:00:00-05:00');
        expect(ts.timeZone, TimeZone.est);
        expect(ts.hour, 12); // local EST
      });

      test('with milliseconds', () {
        final ts = Timestamp.parse('2025-01-01T12:00:00.123+09:00');
        expect(ts.millisecond, 123);
      });

      test('with microseconds', () {
        final ts = Timestamp.parse('2025-01-01T12:00:00.123456+09:00');
        expect(ts.millisecond, 123);
        expect(ts.microsecond, 456);
      });

      test('space separator', () {
        final ts = Timestamp.parse('2025-01-01 12:00:00+09:00');
        expect(ts.hour, 12);
      });

      test('invalid throws ArgumentError', () {
        expect(() => Timestamp.parse('not-a-date'), throwsArgumentError);
        expect(() => Timestamp.parse(''), throwsArgumentError);
      });
    });

    // =============================================
    // Construction: fromEpoch*
    // =============================================
    group('fromEpoch', () {
      test('fromEpochMilliseconds', () {
        final ts = Timestamp.fromEpochMilliseconds(0);
        expect(ts.year, 1970);
        expect(ts.month, 1);
        expect(ts.day, 1);
      });

      test('fromEpochMilliseconds with timezone', () {
        final ts = Timestamp.fromEpochMilliseconds(0, timeZone: TimeZone.kst);
        expect(ts.hour, 9); // UTC+9
      });

      test('fromEpochMicroseconds', () {
        final ts = Timestamp.fromEpochMicroseconds(1000000);
        expect(ts.microsecondsSinceEpoch, 1000000);
      });

      test('millisecondsSinceEpoch roundtrip', () {
        final ts = Timestamp.of(year: 2025, month: 6, day: 15, hour: 10);
        final ms = ts.millisecondsSinceEpoch;
        final ts2 = Timestamp.fromEpochMilliseconds(ms);
        expect(ts2.microsecondsSinceEpoch ~/ 1000, ts.microsecondsSinceEpoch ~/ 1000);
      });
    });

    // =============================================
    // Construction: fromDateTime
    // =============================================
    group('fromDateTime', () {
      test('from UTC DateTime', () {
        final dt = DateTime.utc(2025, 1, 1, 12);
        final ts = Timestamp.fromDateTime(dt, timeZone: TimeZone.kst);
        expect(ts.hour, 21); // 12 + 9
        expect(ts.toDateTime(), dt);
      });

      test('from local DateTime converts to UTC', () {
        final dt = DateTime(2025, 1, 1, 12);
        final ts = Timestamp.fromDateTime(dt);
        expect(ts.toDateTime().isUtc, isTrue);
      });
    });

    // =============================================
    // Construction: fromJson
    // =============================================
    group('fromJson', () {
      test('parses ISO 8601', () {
        final ts = Timestamp.fromJson('2025-01-01T12:00:00.000+09:00');
        expect(ts.timeZone, TimeZone.kst);
        expect(ts.hour, 12);
      });
    });

    // =============================================
    // Local properties
    // =============================================
    group('local properties', () {
      test('all components reflect timezone', () {
        final ts = Timestamp.of(
          year: 2025, month: 3, day: 14, hour: 10, minute: 30,
          second: 45, millisecond: 123,
          timeZone: TimeZone.kst,
        );
        expect(ts.year, 2025);
        expect(ts.month, 3);
        expect(ts.day, 14);
        expect(ts.hour, 10);
        expect(ts.minute, 30);
        expect(ts.second, 45);
        expect(ts.millisecond, 123);
      });

      test('weekday', () {
        // 2025-01-01 is Wednesday
        final ts = Timestamp.of(year: 2025, month: 1, day: 1);
        expect(ts.weekday, DateTime.wednesday);
      });
    });

    // =============================================
    // inZone
    // =============================================
    group('inZone', () {
      test('same instant, different view', () {
        final kst = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 12,
          timeZone: TimeZone.kst,
        );
        final utc = kst.inZone(TimeZone.utc);
        expect(utc.hour, 3);
        expect(utc.microsecondsSinceEpoch, kst.microsecondsSinceEpoch);
      });

      test('chain KST → PST → UTC preserves instant', () {
        final kst = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 12,
          timeZone: TimeZone.kst,
        );
        final pst = kst.inZone(TimeZone.pst);
        final utc = pst.inZone(TimeZone.utc);
        expect(utc.microsecondsSinceEpoch, kst.microsecondsSinceEpoch);
      });

      test('inZone preserves instant across all timezones', () {
        final original = Timestamp.of(
          year: 2025, month: 6, day: 15, hour: 12,
          timeZone: TimeZone.utc,
        );
        for (final tz in TimeZone.values) {
          final converted = original.inZone(tz);
          expect(converted.microsecondsSinceEpoch,
              original.microsecondsSinceEpoch,
              reason: 'Failed for ${tz.name}');
        }
      });
    });

    // =============================================
    // toDateTime
    // =============================================
    group('toDateTime', () {
      test('returns UTC DateTime', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 12,
          timeZone: TimeZone.kst,
        );
        final dt = ts.toDateTime();
        expect(dt.isUtc, isTrue);
        expect(dt.hour, 3);
      });
    });

    // =============================================
    // toDate / toTime
    // =============================================
    group('toDate / toTime', () {
      test('toDate extracts local date', () {
        final ts = Timestamp.of(
          year: 2025, month: 3, day: 14,
          timeZone: TimeZone.kst,
        );
        expect(ts.toDate(), Date(2025, 3, 14));
      });

      test('toTime extracts local time', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 14, minute: 30,
          timeZone: TimeZone.kst,
        );
        expect(ts.toTime(), Time(14, 30));
      });
    });

    // =============================================
    // Arithmetic
    // =============================================
    group('arithmetic', () {
      test('operator + preserves timezone', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 12,
          timeZone: TimeZone.kst,
        );
        final result = ts + const Duration(hours: 1);
        expect(result.hour, 13);
        expect(result.timeZone, TimeZone.kst);
      });

      test('operator - preserves timezone', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 12,
          timeZone: TimeZone.kst,
        );
        final result = ts - const Duration(hours: 1);
        expect(result.hour, 11);
        expect(result.timeZone, TimeZone.kst);
      });

      test('add crosses day boundary', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 23,
          timeZone: TimeZone.utc,
        );
        final result = ts + const Duration(hours: 2);
        expect(result.day, 2);
        expect(result.hour, 1);
      });

      test('add large duration (1000 days)', () {
        final ts = Timestamp.of(year: 2025, month: 1, day: 1, timeZone: TimeZone.kst);
        final result = ts + const Duration(days: 1000);
        expect(result.timeZone, TimeZone.kst);
        // Just verify it doesn't crash
        expect(result.year, greaterThanOrEqualTo(2027));
      });

      test('difference', () {
        final a = Timestamp.of(year: 2025, month: 1, day: 2, timeZone: TimeZone.utc);
        final b = Timestamp.of(year: 2025, month: 1, day: 1, timeZone: TimeZone.utc);
        expect(a.difference(b), const Duration(days: 1));
      });

      test('difference cross-timezone', () {
        final kst = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 12,
          timeZone: TimeZone.kst,
        );
        final utc = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 3,
          timeZone: TimeZone.utc,
        );
        // Same instant
        expect(kst.difference(utc), Duration.zero);
      });
    });

    // =============================================
    // Comparison
    // =============================================
    group('comparison', () {
      test('isBefore / isAfter', () {
        final a = Timestamp.of(year: 2025, month: 1, day: 1);
        final b = Timestamp.of(year: 2025, month: 1, day: 2);
        expect(a.isBefore(b), isTrue);
        expect(b.isAfter(a), isTrue);
        expect(a.isAfter(b), isFalse);
        expect(b.isBefore(a), isFalse);
      });

      test('isAtSameMoment across timezones', () {
        final kst = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 12,
          timeZone: TimeZone.kst,
        );
        final utc = kst.inZone(TimeZone.utc);
        expect(kst.isAtSameMoment(utc), isTrue);
      });

      test('compareTo for sorting', () {
        final a = Timestamp.of(year: 2025, month: 1, day: 3);
        final b = Timestamp.of(year: 2025, month: 1, day: 1);
        final c = Timestamp.of(year: 2025, month: 1, day: 2);
        final list = [a, b, c];
        list.sort();
        expect(list[0], b);
        expect(list[1], c);
        expect(list[2], a);
      });

      test('sort cross-timezone', () {
        final kst = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 21,
          timeZone: TimeZone.kst,
        );
        final utc = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 10,
          timeZone: TimeZone.utc,
        );
        final pst = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 5,
          timeZone: TimeZone.pst,
        );
        // UTC instants: KST 21:00 → 12:00Z, UTC 10:00Z, PST 05:00 → 13:00Z
        final list = [kst, utc, pst];
        list.sort();
        expect(list[0], utc);  // 10:00Z
        expect(list[1], kst);  // 12:00Z
        expect(list[2], pst);  // 13:00Z
      });
    });

    // =============================================
    // Equality
    // =============================================
    group('equality', () {
      test('same instant same timezone', () {
        final a = Timestamp.of(year: 2025, month: 1, day: 1, timeZone: TimeZone.kst);
        final b = Timestamp.of(year: 2025, month: 1, day: 1, timeZone: TimeZone.kst);
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('same instant different timezone are equal', () {
        final kst = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 12,
          timeZone: TimeZone.kst,
        );
        final utc = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 3,
          timeZone: TimeZone.utc,
        );
        expect(kst, utc);
        expect(kst.hashCode, utc.hashCode);
      });

      test('different instant are not equal', () {
        final a = Timestamp.of(year: 2025, month: 1, day: 1, timeZone: TimeZone.utc);
        final b = Timestamp.of(year: 2025, month: 1, day: 2, timeZone: TimeZone.utc);
        expect(a == b, isFalse);
      });

      test('not equal to non-Timestamp', () {
        final ts = Timestamp.of(year: 2025, month: 1, day: 1);
        // ignore: unrelated_type_equality_checks
        expect(ts == 'not a timestamp', isFalse);
      });
    });

    // =============================================
    // Serialization
    // =============================================
    group('serialization', () {
      test('toIso8601String UTC', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 12,
          timeZone: TimeZone.utc,
        );
        expect(ts.toIso8601String(), '2025-01-01T12:00:00.000+00:00');
      });

      test('toIso8601String KST', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 12,
          timeZone: TimeZone.kst,
        );
        expect(ts.toIso8601String(), '2025-01-01T12:00:00.000+09:00');
      });

      test('toString equals toIso8601String', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 12,
          timeZone: TimeZone.kst,
        );
        expect(ts.toString(), ts.toIso8601String());
      });

      test('toJson roundtrip', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 12,
          timeZone: TimeZone.kst,
        );
        final json = ts.toJson();
        final ts2 = Timestamp.fromJson(json);
        expect(ts2.isAtSameMoment(ts), isTrue);
        expect(ts2.timeZone, ts.timeZone);
      });

      test('parse → toIso8601String roundtrip', () {
        const iso = '2025-06-15T10:30:45.123+09:00';
        final ts = Timestamp.parse(iso);
        final out = ts.toIso8601String();
        final ts2 = Timestamp.parse(out);
        expect(ts2, ts);
      });

      test('epoch milliseconds roundtrip', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 12,
          timeZone: TimeZone.kst,
        );
        final ms = ts.millisecondsSinceEpoch;
        final ts2 = Timestamp.fromEpochMilliseconds(ms, timeZone: TimeZone.kst);
        expect(ts2.hour, ts.hour);
        expect(ts2.day, ts.day);
      });
    });

    // =============================================
    // format
    // =============================================
    group('format', () {
      test('basic pattern', () {
        final ts = Timestamp.of(
          year: 2025, month: 3, day: 14, hour: 10, minute: 30,
          timeZone: TimeZone.kst,
        );
        expect(ts.format('yyyy/MM/dd HH:mm'), '2025/03/14 10:30');
      });

      test('with seconds and millis', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 9, minute: 5,
          second: 3, millisecond: 7,
        );
        expect(ts.format('HH:mm:ss.SSS'), '09:05:03.007');
      });
    });

    // =============================================
    // Edge cases
    // =============================================
    group('edge cases', () {
      test('epoch zero', () {
        final ts = Timestamp.fromEpochMicroseconds(0);
        expect(ts.year, 1970);
        expect(ts.month, 1);
        expect(ts.day, 1);
        expect(ts.hour, 0);
      });

      test('millisecond boundary', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 23, minute: 59,
          second: 59, millisecond: 999,
        );
        final next = ts + const Duration(milliseconds: 1);
        expect(next.day, 2);
        expect(next.hour, 0);
        expect(next.minute, 0);
        expect(next.second, 0);
        expect(next.millisecond, 0);
      });

      test('year end boundary with KST', () {
        // 2024-12-31T23:59:59Z → 2025-01-01T08:59:59 KST
        final ts = Timestamp.parse('2024-12-31T23:59:59Z').inZone(TimeZone.kst);
        expect(ts.year, 2025);
        expect(ts.month, 1);
        expect(ts.day, 1);
        expect(ts.hour, 8);
        expect(ts.minute, 59);
        expect(ts.second, 59);
      });

      test('IST +05:30 half-hour offset', () {
        final ts = Timestamp.of(
          year: 2025, month: 1, day: 1, hour: 5, minute: 30,
          timeZone: TimeZone.ist,
        );
        expect(ts.toDateTime().hour, 0);
        expect(ts.toDateTime().minute, 0);
      });

      test('not a DateTime', () {
        final ts = Timestamp.of(year: 2025, month: 1, day: 1);
        expect(ts is DateTime, isFalse);
      });
    });
  });
}
