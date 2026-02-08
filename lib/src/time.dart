/// A time of day (hour and minute) without a date or timezone.
/// Corresponds to SQL `TIME`.
///
/// Timezone is intentionally omitted -- SQL's `TIMETZ` is
/// [discouraged by PostgreSQL](https://www.postgresql.org/docs/current/datatype-datetime.html)
/// because a time + offset without a date has ambiguous semantics
/// (e.g. DST transitions).
///
/// ```dart
/// const t = Time(14, 30);
/// print(t);          // 14:30
/// print(t.toJson()); // 1430
/// ```
class Time implements Comparable<Time> {
  final int hour;
  final int minute;

  /// Creates a [Time]. Validates that hour (0-23) and minute (0-59) are
  /// in range.
  ///
  /// Throws [ArgumentError] for out-of-range values.
  Time(this.hour, this.minute) {
    _validate(hour, minute);
  }

  static void _validate(int hour, int minute) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError('Hour must be 0-23, got $hour');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError('Minute must be 0-59, got $minute');
    }
  }

  /// Creates from a compact integer or string (e.g. `1430` for 14:30).
  factory Time.fromJson(dynamic json) {
    final int value;
    if (json is String) {
      value = int.parse(json);
    } else if (json is int) {
      value = json;
    } else {
      throw ArgumentError('Expected int or String, got ${json.runtimeType}');
    }
    return Time(value ~/ 100, value % 100);
  }

  /// Extracts the time from a [DateTime].
  Time.fromDateTime(DateTime dt) : this(dt.hour, dt.minute);

  /// Serializes as a compact integer (e.g. `1430`).
  int toJson() => hour * 100 + minute;

  // -- Comparable ------------------------------------------------------------

  @override
  int compareTo(Time other) {
    if (hour != other.hour) return hour.compareTo(other.hour);
    return minute.compareTo(other.minute);
  }

  bool operator >(Time other) => compareTo(other) > 0;
  bool operator >=(Time other) => compareTo(other) >= 0;
  bool operator <(Time other) => compareTo(other) < 0;
  bool operator <=(Time other) => compareTo(other) <= 0;

  // -- Object ----------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Time && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
