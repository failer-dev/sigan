import 'date.dart';
import 'time.dart';
import 'time_zone.dart';

/// A point in time with an associated [TimeZone].
///
/// Internally stores the UTC instant as microseconds since epoch --
/// matching the precision of PostgreSQL `timestamptz` and MySQL
/// `DATETIME(6)`. Nanoseconds from Go/Java/Rust are truncated on
/// parse but no data is lost through a typical DB roundtrip.
///
/// Property getters ([year], [month], [day], [hour], etc.) return
/// timezone-adjusted local values with lazy caching.
///
/// Independent type -- does not extend or implement `DateTime`.
/// Use [toDateTime] to convert when a `DateTime` is needed.
///
/// ```dart
/// final ts = Timestamp.of(
///   year: 2025, month: 1, day: 1, hour: 12,
///   timeZone: TimeZone.kst,
/// );
/// print(ts.hour);             // 12 (KST)
/// print(ts.toDateTime().hour); // 3  (UTC)
/// print(ts);                  // 2025-01-01T12:00:00.000+09:00
/// ```
class Timestamp implements Comparable<Timestamp> {
  final int _microsecondsSinceEpoch;
  final TimeZone timeZone;

  DateTime? _localCache;

  DateTime get _local =>
      _localCache ??= DateTime.fromMicrosecondsSinceEpoch(
        _microsecondsSinceEpoch + timeZone.offset.inMicroseconds,
        isUtc: true,
      );

  // -- Constructors ----------------------------------------------------------

  Timestamp._({required int utcMicroseconds, required this.timeZone})
      : _microsecondsSinceEpoch = utcMicroseconds;

  /// The current time.
  factory Timestamp.now({TimeZone timeZone = TimeZone.utc}) {
    return Timestamp._(
      utcMicroseconds: DateTime.now().toUtc().microsecondsSinceEpoch,
      timeZone: timeZone,
    );
  }

  /// Creates from date and time components interpreted in [timeZone].
  ///
  /// ```dart
  /// // 2025-01-01 12:00 KST = 2025-01-01 03:00 UTC
  /// Timestamp.of(year: 2025, month: 1, day: 1, hour: 12, timeZone: TimeZone.kst);
  /// ```
  factory Timestamp.of({
    required int year,
    required int month,
    required int day,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    TimeZone timeZone = TimeZone.utc,
  }) {
    final local = DateTime.utc(year, month, day, hour, minute, second, millisecond);
    final utcMicros = local.microsecondsSinceEpoch - timeZone.offset.inMicroseconds;
    return Timestamp._(utcMicroseconds: utcMicros, timeZone: timeZone);
  }

  /// Parses an ISO 8601 string.
  ///
  /// The timezone is extracted from the offset suffix (`Z`, `+HH:MM`,
  /// `+HHMM`, or `+HH`).
  ///
  /// Throws [ArgumentError] if the string cannot be parsed.
  factory Timestamp.parse(String iso8601) {
    final trimmed = iso8601.trim();

    final DateTime parsed;
    try {
      parsed = DateTime.parse(trimmed);
    } on FormatException {
      throw ArgumentError('Invalid ISO 8601 format: $iso8601');
    }

    final offsetMatch =
        RegExp(r'(Z|[+-]\d{2}(?::?\d{2})?)$').firstMatch(trimmed);
    final timeZone = offsetMatch != null
        ? TimeZone.fromOffset(offsetMatch.group(1)!)
        : TimeZone.utc;

    final utc = parsed.isUtc ? parsed : parsed.toUtc();
    return Timestamp._(
      utcMicroseconds: utc.microsecondsSinceEpoch,
      timeZone: timeZone,
    );
  }

  /// Creates from epoch milliseconds.
  factory Timestamp.fromEpochMilliseconds(
    int millisecondsSinceEpoch, {
    TimeZone timeZone = TimeZone.utc,
  }) {
    return Timestamp._(
      utcMicroseconds: millisecondsSinceEpoch * 1000,
      timeZone: timeZone,
    );
  }

  /// Creates from epoch microseconds.
  factory Timestamp.fromEpochMicroseconds(
    int microsecondsSinceEpoch, {
    TimeZone timeZone = TimeZone.utc,
  }) {
    return Timestamp._(
      utcMicroseconds: microsecondsSinceEpoch,
      timeZone: timeZone,
    );
  }

  /// Creates from a [DateTime]. If not UTC, converts to UTC first.
  factory Timestamp.fromDateTime(
    DateTime dateTime, {
    TimeZone timeZone = TimeZone.utc,
  }) {
    final utc = dateTime.isUtc ? dateTime : dateTime.toUtc();
    return Timestamp._(
      utcMicroseconds: utc.microsecondsSinceEpoch,
      timeZone: timeZone,
    );
  }

  /// JSON deserialization (ISO 8601 string).
  factory Timestamp.fromJson(String json) => Timestamp.parse(json);

  // -- Local properties (adjusted to [timeZone]) -----------------------------

  /// The year in [timeZone].
  int get year => _local.year;

  /// The month (1-12) in [timeZone].
  int get month => _local.month;

  /// The day of the month (1-31) in [timeZone].
  int get day => _local.day;

  /// The hour (0-23) in [timeZone].
  int get hour => _local.hour;

  /// The minute (0-59) in [timeZone].
  int get minute => _local.minute;

  /// The second (0-59) in [timeZone].
  int get second => _local.second;

  /// The millisecond (0-999) in [timeZone].
  int get millisecond => _local.millisecond;

  /// The microsecond (0-999) in [timeZone].
  int get microsecond => _local.microsecond;

  /// Day of the week (1 = Monday, 7 = Sunday) in [timeZone].
  int get weekday => _local.weekday;

  // -- UTC access ------------------------------------------------------------

  /// Microseconds since Unix epoch (UTC).
  int get microsecondsSinceEpoch => _microsecondsSinceEpoch;

  /// Milliseconds since Unix epoch (UTC).
  int get millisecondsSinceEpoch => _microsecondsSinceEpoch ~/ 1000;

  // -- Conversion ------------------------------------------------------------

  /// Returns the same instant viewed in [zone].
  ///
  /// ```dart
  /// final kst = Timestamp.of(year: 2025, month: 1, day: 1, hour: 12, timeZone: TimeZone.kst);
  /// final utc = kst.inZone(TimeZone.utc);
  /// print(utc.hour); // 3
  /// ```
  Timestamp inZone(TimeZone zone) {
    return Timestamp._(utcMicroseconds: _microsecondsSinceEpoch, timeZone: zone);
  }

  /// Converts to a UTC [DateTime].
  DateTime toDateTime() {
    return DateTime.fromMicrosecondsSinceEpoch(
      _microsecondsSinceEpoch,
      isUtc: true,
    );
  }

  /// Extracts the local date.
  Date toDate() => Date(_local.year, _local.month, _local.day);

  /// Extracts the local time.
  Time toTime() => Time(_local.hour, _local.minute);

  /// ISO 8601 string with timezone offset.
  ///
  /// ```dart
  /// // 2025-01-01T12:00:00.000+09:00
  /// timestamp.toIso8601String();
  /// ```
  String toIso8601String() {
    final l = _local;
    final y = l.year.toString().padLeft(4, '0');
    final mo = l.month.toString().padLeft(2, '0');
    final d = l.day.toString().padLeft(2, '0');
    final h = l.hour.toString().padLeft(2, '0');
    final mi = l.minute.toString().padLeft(2, '0');
    final s = l.second.toString().padLeft(2, '0');
    final ms = l.millisecond.toString().padLeft(3, '0');
    return '$y-$mo-${d}T$h:$mi:$s.$ms${timeZone.isoOffset}';
  }

  /// JSON serialization (= [toIso8601String]).
  String toJson() => toIso8601String();

  // -- Arithmetic ------------------------------------------------------------

  /// Returns a new [Timestamp] with [duration] added, preserving [timeZone].
  Timestamp operator +(Duration duration) {
    return Timestamp._(
      utcMicroseconds: _microsecondsSinceEpoch + duration.inMicroseconds,
      timeZone: timeZone,
    );
  }

  /// Returns a new [Timestamp] with [duration] subtracted, preserving [timeZone].
  Timestamp operator -(Duration duration) {
    return Timestamp._(
      utcMicroseconds: _microsecondsSinceEpoch - duration.inMicroseconds,
      timeZone: timeZone,
    );
  }

  /// The [Duration] between this and [other].
  Duration difference(Timestamp other) {
    return Duration(
      microseconds: _microsecondsSinceEpoch - other._microsecondsSinceEpoch,
    );
  }

  // -- Comparison ------------------------------------------------------------

  @override
  int compareTo(Timestamp other) =>
      _microsecondsSinceEpoch.compareTo(other._microsecondsSinceEpoch);

  bool isBefore(Timestamp other) =>
      _microsecondsSinceEpoch < other._microsecondsSinceEpoch;

  bool isAfter(Timestamp other) =>
      _microsecondsSinceEpoch > other._microsecondsSinceEpoch;

  /// Whether this and [other] represent the same instant (timezone ignored).
  bool isAtSameMoment(Timestamp other) =>
      _microsecondsSinceEpoch == other._microsecondsSinceEpoch;

  // -- Formatting ------------------------------------------------------------

  /// Formats using a simple pattern.
  ///
  /// Supported tokens: `yyyy`, `MM`, `dd`, `HH`, `mm`, `ss`, `SSS`.
  String format(String pattern) {
    final l = _local;
    return pattern
        .replaceAll('yyyy', l.year.toString().padLeft(4, '0'))
        .replaceAll('MM', l.month.toString().padLeft(2, '0'))
        .replaceAll('dd', l.day.toString().padLeft(2, '0'))
        .replaceAll('HH', l.hour.toString().padLeft(2, '0'))
        .replaceAll('mm', l.minute.toString().padLeft(2, '0'))
        .replaceAll('ss', l.second.toString().padLeft(2, '0'))
        .replaceAll('SSS', l.millisecond.toString().padLeft(3, '0'));
  }

  // -- Object ----------------------------------------------------------------

  /// Two timestamps are equal if they represent the same UTC instant,
  /// regardless of timezone.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Timestamp &&
          _microsecondsSinceEpoch == other._microsecondsSinceEpoch;

  @override
  int get hashCode => _microsecondsSinceEpoch.hashCode;

  @override
  String toString() => toIso8601String();
}
