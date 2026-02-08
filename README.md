# sigan

**시간** (Korean for "time") — timezone-aware date and time for Dart.
Zero dependencies.

## Why not DateTime?

Dart's `DateTime` only supports UTC and system-local. There is no way to
attach an arbitrary timezone offset. sigan provides an independent
`Timestamp` type that carries its timezone — following the
`java.time` / `kotlinx.datetime` approach of composition over inheritance.

## Quick start

```dart
import 'package:sigan/sigan.dart';

// Create
final ts = Timestamp.of(
  year: 2025, month: 1, day: 1, hour: 12,
  timeZone: TimeZone.kst,
);

ts.hour;              // 12 (KST)
ts.toDateTime().hour; // 3  (UTC)
ts.toIso8601String(); // 2025-01-01T12:00:00.000+09:00

// Convert between zones
ts.inZone(TimeZone.utc).hour;  // 3
ts.inZone(TimeZone.pst).hour;  // 19 (previous day)

// Arithmetic
ts + Duration(hours: 3);  // 15:00 KST
ts.difference(other);     // Duration

// Parse
Timestamp.parse('2025-01-01T12:00:00+09:00');
Timestamp.fromEpochMilliseconds(1735700400000, timeZone: TimeZone.kst);

// Date & Time value types
const d = Date(2025, 12, 25);  // SQL DATE  → "2025-12-25"
const t = Time(14, 30);        // SQL TIME  → serializes as 1430
```

## Types

- **`Timestamp`** — UTC instant + `TimeZone`. Microsecond precision (PostgreSQL `timestamptz`).
- **`Date`** — Calendar date without time. SQL `DATE`.
- **`Time`** — Hour + minute without date. SQL `TIME`.
- **`TimeZone`** — Fixed UTC offset. 33 predefined constants.

## Backend interoperability

RFC 3339 with numeric offsets — no IANA zone IDs, no timezone database needed.

| Backend | Format |
|---|---|
| **Go** | `time.RFC3339` / `time.RFC3339Nano` |
| **Spring / Java** | `OffsetDateTime`, `Instant` (Jackson) |
| **Rust** | `chrono::DateTime<FixedOffset>` |
| **TypeScript** | `Date.toISOString()`, dayjs, luxon |
| **PostgreSQL** | `timestamptz`, `EXTRACT(EPOCH FROM ts)` |

Nanoseconds from Go/Rust are truncated to microseconds on parse — no data
loss through a typical database roundtrip.

## Design decisions

- **Fixed offsets, not IANA zones.** Offset is baked into the serialized string, not resolved at read time.
- **Independent type.** `Timestamp` does not extend `DateTime`.
- **Microsecond precision.** Matches PostgreSQL/MySQL(6). Sub-microsecond digits truncated.
- **Value equality.** Same UTC instant = `==`, regardless of timezone.


