import 'package:sigan/sigan.dart';
import 'package:test/test.dart';

/// Backend interoperability tests.
///
/// Verifies that sigan correctly parses and roundtrips formats produced by
/// Go, Spring/Java, Rust, TypeScript/JS, and PostgreSQL.
void main() {
  // ==========================================================================
  // Go
  // ==========================================================================
  group('Go interop', () {
    test('time.RFC3339', () {
      // Go: t.Format(time.RFC3339)
      final ts = Timestamp.parse('2025-01-01T12:00:00+09:00');
      expect(ts.hour, 12);
      expect(ts.timeZone, TimeZone.kst);
    });

    test('time.RFC3339Nano', () {
      // Go: t.Format(time.RFC3339Nano) — 9-digit fractional
      final ts = Timestamp.parse('2025-01-01T12:00:00.123456789+09:00');
      expect(ts.millisecond, 123);
      expect(ts.microsecond, 456);
    });

    test('Go UTC', () {
      // Go: t.UTC().Format(time.RFC3339)
      final ts = Timestamp.parse('2025-01-01T03:00:00Z');
      expect(ts.timeZone, TimeZone.utc);
    });

    test('Go negative offset', () {
      // Go: t.In(loc).Format(time.RFC3339) where loc is America/New_York
      final ts = Timestamp.parse('2025-01-01T12:00:00-05:00');
      expect(ts.timeZone, TimeZone.est);
    });

    test('Go epoch millis roundtrip', () {
      // Go: t.UnixMilli()
      final ts = Timestamp.of(year: 2025, month: 1, day: 1, timeZone: TimeZone.utc);
      final goMs = ts.millisecondsSinceEpoch;
      final restored = Timestamp.fromEpochMilliseconds(goMs);
      expect(restored, ts);
    });
  });

  // ==========================================================================
  // Spring / Java
  // ==========================================================================
  group('Spring/Java interop', () {
    test('OffsetDateTime.toString()', () {
      // Java: OffsetDateTime.of(2025,1,1,12,0,0,123456789, ZoneOffset.ofHours(9)).toString()
      final ts = Timestamp.parse('2025-01-01T12:00:00.123456789+09:00');
      expect(ts.hour, 12);
      expect(ts.timeZone, TimeZone.kst);
    });

    test('Instant.toString()', () {
      // Java: Instant.now().toString() — always Z
      final ts = Timestamp.parse('2025-01-01T03:00:00.123456Z');
      expect(ts.timeZone, TimeZone.utc);
      expect(ts.microsecond, 456);
    });

    test('Jackson ISO format', () {
      // Jackson: "2025-01-01T12:00:00.000+09:00"
      final ts = Timestamp.parse('2025-01-01T12:00:00.000+09:00');
      expect(ts.hour, 12);
    });

    test('Jackson with WRITE_DATES_AS_TIMESTAMPS', () {
      // Jackson: epoch millis as long
      final ts = Timestamp.fromEpochMilliseconds(1735700400000, timeZone: TimeZone.kst);
      expect(ts.year, 2025);
      expect(ts.month, 1);
      expect(ts.day, 1);
    });

    test('Java no fractional seconds', () {
      // Some serializers omit sub-seconds: "2025-01-01T12:00:00+09:00"
      final ts = Timestamp.parse('2025-01-01T12:00:00+09:00');
      expect(ts.millisecond, 0);
    });

    test('Java Instant.toEpochMilli() roundtrip', () {
      final ts = Timestamp.of(
        year: 2025, month: 6, day: 15, hour: 10, minute: 30,
        second: 45, millisecond: 678,
        timeZone: TimeZone.utc,
      );
      final javaMs = ts.millisecondsSinceEpoch;
      final restored = Timestamp.fromEpochMilliseconds(javaMs);
      expect(restored.year, 2025);
      expect(restored.hour, 10);
      expect(restored.millisecond, 678);
    });
  });

  // ==========================================================================
  // Rust
  // ==========================================================================
  group('Rust interop', () {
    test('chrono to_rfc3339()', () {
      // Rust: dt.to_rfc3339()
      final ts = Timestamp.parse('2025-01-01T12:00:00+09:00');
      expect(ts.hour, 12);
    });

    test('chrono with nanoseconds', () {
      // Rust chrono preserves nanosecond precision in string
      final ts = Timestamp.parse('2025-01-01T12:00:00.123456789+09:00');
      expect(ts.millisecond, 123);
      expect(ts.microsecond, 456);
    });

    test('chrono UTC uses +00:00 not Z', () {
      // Rust chrono: Utc.to_rfc3339() → "+00:00"
      final ts = Timestamp.parse('2025-01-01T03:00:00+00:00');
      expect(ts.timeZone, TimeZone.utc);
    });

    test('chrono::NaiveDateTime (no offset) defaults to UTC', () {
      // Some Rust APIs return no offset — sigan defaults to UTC
      // DateTime.parse treats no-offset as local, then converts to UTC
      final ts = Timestamp.parse('2025-01-01T12:00:00');
      expect(ts.timeZone, TimeZone.utc);
      // The hour depends on system timezone; just verify it parsed
      expect(ts.year, 2025);
    });

    test('Rust timestamp millis', () {
      // Rust: dt.timestamp_millis()
      final ts = Timestamp.fromEpochMilliseconds(1735689600000);
      expect(ts.year, 2025);
      expect(ts.month, 1);
      expect(ts.day, 1);
    });
  });

  // ==========================================================================
  // TypeScript / JavaScript
  // ==========================================================================
  group('TypeScript/JS interop', () {
    test('Date.toISOString()', () {
      // JS: new Date().toISOString() — always UTC, always Z, always 3-digit ms
      final ts = Timestamp.parse('2025-01-01T03:00:00.000Z');
      expect(ts.timeZone, TimeZone.utc);
      expect(ts.hour, 3);
    });

    test('Date.toJSON()', () {
      // JSON.stringify(new Date()) — same as toISOString
      final ts = Timestamp.parse('2025-01-01T03:00:00.123Z');
      expect(ts.millisecond, 123);
    });

    test('Date.getTime() epoch roundtrip', () {
      // JS: Date.getTime() returns milliseconds
      final ts = Timestamp.of(year: 2025, month: 1, day: 1, timeZone: TimeZone.utc);
      final jsMs = ts.millisecondsSinceEpoch;
      final restored = Timestamp.fromEpochMilliseconds(jsMs);
      expect(restored, ts);
    });

    test('dayjs with tz plugin', () {
      // dayjs('2025-01-01').tz('Asia/Seoul').format()
      final ts = Timestamp.parse('2025-01-01T12:00:00+09:00');
      expect(ts.timeZone, TimeZone.kst);
    });

    test('luxon toISO()', () {
      // luxon: DateTime.now().setZone('Asia/Seoul').toISO()
      final ts = Timestamp.parse('2025-01-01T12:00:00.000+09:00');
      expect(ts.hour, 12);
    });

    test('luxon toMillis() roundtrip', () {
      final ts = Timestamp.of(
        year: 2025, month: 3, day: 14, hour: 15, minute: 9,
        second: 26, millisecond: 535,
        timeZone: TimeZone.utc,
      );
      final luxonMs = ts.millisecondsSinceEpoch;
      final restored = Timestamp.fromEpochMilliseconds(luxonMs);
      expect(restored, ts);
    });
  });

  // ==========================================================================
  // PostgreSQL
  // ==========================================================================
  group('PostgreSQL interop', () {
    test('timestamptz output format (space separator)', () {
      // PG: SELECT now()::timestamptz → "2025-01-01 12:00:00+09"
      // With full format: "2025-01-01 12:00:00.123456+09:00"
      final ts = Timestamp.parse('2025-01-01 12:00:00.123456+09:00');
      expect(ts.hour, 12);
      expect(ts.microsecond, 456);
    });

    test('timestamptz UTC', () {
      // PG: SELECT now() AT TIME ZONE 'UTC'
      final ts = Timestamp.parse('2025-01-01 03:00:00+00:00');
      expect(ts.timeZone, TimeZone.utc);
    });

    test('timestamp without timezone (no offset)', () {
      // PG: SELECT '2025-01-01 12:00:00'::timestamp
      // No offset → DateTime.parse treats as local then converts to UTC
      final ts = Timestamp.parse('2025-01-01 12:00:00');
      expect(ts.timeZone, TimeZone.utc);
      expect(ts.year, 2025);
    });

    test('PG microsecond precision preserved', () {
      // PG timestamptz stores microsecond precision
      final ts = Timestamp.parse('2025-01-01T12:00:00.999999+09:00');
      expect(ts.millisecond, 999);
      expect(ts.microsecond, 999);
    });

    test('PG extract(epoch) roundtrip', () {
      // PG: SELECT extract(epoch FROM ts) * 1000 → millis
      final ts = Timestamp.of(
        year: 2025, month: 1, day: 1, hour: 12,
        timeZone: TimeZone.kst,
      );
      final pgEpochMs = ts.millisecondsSinceEpoch;
      final restored = Timestamp.fromEpochMilliseconds(pgEpochMs, timeZone: TimeZone.kst);
      expect(restored.hour, 12);
      expect(restored.isAtSameMoment(ts), isTrue);
    });
  });

  // ==========================================================================
  // Cross-backend instant preservation
  // ==========================================================================
  group('cross-backend instant preservation', () {
    test('same instant across all backend formats', () {
      // All these represent the same instant: 2025-01-01T03:00:00Z
      final formats = [
        '2025-01-01T03:00:00Z',                // JS Date.toISOString()
        '2025-01-01T03:00:00+00:00',            // Rust chrono UTC
        '2025-01-01T03:00:00.000Z',             // JS with millis
        '2025-01-01T03:00:00.000000Z',          // Java Instant with micros
        '2025-01-01T12:00:00+09:00',            // Go/Java in KST
        '2025-01-01T12:00:00.000+09:00',        // Jackson in KST
        '2024-12-31T22:00:00-05:00',            // EST view
        '2024-12-31T19:00:00-08:00',            // PST view
        '2025-01-01 03:00:00+00:00',            // PostgreSQL UTC
        '2025-01-01 12:00:00+09:00',            // PostgreSQL KST
      ];

      final instants = formats.map(Timestamp.parse).toList();

      for (var i = 1; i < instants.length; i++) {
        expect(
          instants[i].isAtSameMoment(instants[0]),
          isTrue,
          reason: 'Format "${formats[i]}" differs from "${formats[0]}".\n'
              '  [0] epoch: ${instants[0].microsecondsSinceEpoch}\n'
              '  [$i] epoch: ${instants[i].microsecondsSinceEpoch}',
        );
      }
    });

    test('parse in one zone, serialize, re-parse preserves instant', () {
      // Simulates: Go sends KST → sigan parses → stores → serializes → Java parses
      final goOutput = '2025-06-15T14:30:00.123+09:00';
      final ts = Timestamp.parse(goOutput);
      final siganOutput = ts.toIso8601String();
      final reparsed = Timestamp.parse(siganOutput);
      expect(reparsed, ts);
      expect(reparsed.timeZone, ts.timeZone);
    });

    test('timezone conversion preserves instant through serialize', () {
      final kst = Timestamp.parse('2025-01-01T12:00:00+09:00');
      final est = kst.inZone(TimeZone.est);
      final estIso = est.toIso8601String();
      final reparsed = Timestamp.parse(estIso);
      expect(reparsed.isAtSameMoment(kst), isTrue);
    });
  });
}
