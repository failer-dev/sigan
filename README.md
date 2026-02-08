**sigan** (시간, Korean for "time") -- timezone-aware date and time
for Dart. Zero dependencies.

## Features

- `Timestamp` -- UTC instant + `TimeZone`. Independent type, not a `DateTime` subclass.
- `Timestamp.parse()` / `toIso8601String()` -- RFC 3339 roundtrip.
- Interoperable with Go, Spring/Java, Rust, TypeScript, PostgreSQL.
- `Date` (SQL `DATE`), `Time` (SQL `TIME`) value types.
- 33 predefined timezone constants. `inZone()` for conversion.
- `operator +` / `operator -` arithmetic.

## Why

Dart's `DateTime` only supports UTC and system-local. No way to attach
an arbitrary timezone. sigan follows `java.time` / `kotlinx.datetime`
design: composition over inheritance, no `DateTime` subclassing.

## Usage

```dart
import 'package:sigan/sigan.dart';

final ts = Timestamp.of(year: 2025, month: 1, day: 1, hour: 12, timeZone: .kst);
ts.hour;              // 12 (KST)
ts.toDateTime().hour; // 3  (UTC)
ts.toIso8601String(); // 2025-01-01T12:00:00.000+09:00

ts.inZone(.utc).hour; // 3
ts + Duration(hours: 3);      // 15:00 KST

Timestamp.parse('2025-01-01T12:00:00+09:00');
Timestamp.fromEpochMilliseconds(1735700400000, timeZone: .kst);

const d = Date(2025, 12, 25);  // SQL DATE
const t = Time(14, 30);        // SQL TIME, serializes as 1430
```
