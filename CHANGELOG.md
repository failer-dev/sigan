## 1.0.0

### Timestamp

- Independent type combining UTC instant + `TimeZone` (not a `DateTime` subclass)
- `Timestamp.of()`, `Timestamp.now()`, `Timestamp.parse()` constructors
- `fromEpochMilliseconds()`, `fromEpochMicroseconds()`, `fromDateTime()` conversion constructors
- RFC 3339 parsing and serialization (`toIso8601String()`)
- `inZone()` timezone conversion
- `operator +` / `operator -` arithmetic, `difference()`
- `compareTo()`, `isBefore()`, `isAfter()`, `isAtSameMoment()` comparison
- `format()` pattern formatting (`yyyy`, `MM`, `dd`, `HH`, `mm`, `ss`, `SSS`)
- `toDate()`, `toTime()` extraction
- JSON serialization/deserialization
- Microsecond precision matching PostgreSQL `timestamptz` / MySQL `DATETIME(6)`

### TimeZone

- 33 predefined timezone constants (standard + DST)
- `fromName()`, `fromOffset()` factories
- ISO 8601 offset formatting (`isoOffset`)
- Offset range validation (-12:00 to +14:00)

### Date

- SQL `DATE` value type
- Calendar validation (leap year, days per month)
- `Date.parse()` (`yyyy-MM-dd`), `Date.today()`, `Date.fromDateTime()`
- `addDays()`, `weekday`, comparison operators
- `isLeapYear()`, `daysInMonth()` utilities

### Time

- SQL `TIME` value type (hour, minute)
- Compact integer serialization (`1430` = 14:30)
- `Time.fromJson()` supports both int and String
- Comparison operators

### Interoperability

- Go `time.RFC3339`, `time.RFC3339Nano`
- Java/Spring `OffsetDateTime`, `Instant`
- Rust `chrono`
- TypeScript `Date.toISOString()`
- PostgreSQL `timestamptz`
