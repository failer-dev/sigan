/// A calendar date without time or timezone. Corresponds to SQL `DATE`.
///
/// A pure value type -- timezone is not needed because a date represents
/// a square on a calendar, not an instant. To get today's date in a
/// specific timezone, use `Timestamp.now(timeZone: .kst).toDate()`.
///
/// ```dart
/// const d = Date(2025, 12, 25);
/// print(d.weekday);               // 4 (Thursday)
/// print(d.addDays(7));             // 2026-01-01
/// print(Date.isLeapYear(2024));    // true
/// print(Date.daysInMonth(2024, 2)); // 29
/// ```
class Date implements Comparable<Date> {
  final int year;
  final int month;
  final int day;

  /// Creates a [Date]. Validates that the date exists in the calendar.
  ///
  /// Throws [ArgumentError] for invalid components (month 13, Feb 30, etc.).
  Date(this.year, this.month, this.day) {
    _validate(year, month, day);
  }

  /// Internal unchecked constructor for trusted sources.
  const Date._unchecked(this.year, this.month, this.day);

  static void _validate(int year, int month, int day) {
    if (year < 0 || year > 9999) {
      throw ArgumentError('Year must be 0-9999, got $year');
    }
    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be 1-12, got $month');
    }
    if (day < 1 || day > daysInMonth(year, month)) {
      throw ArgumentError('Day $day does not exist in $year-$month');
    }
  }

  /// Today in the system local timezone.
  factory Date.today() {
    final now = DateTime.now();
    return Date(now.year, now.month, now.day);
  }

  /// Parses a `yyyy-MM-dd` string.
  ///
  /// Throws [ArgumentError] on invalid format or nonexistent date.
  factory Date.parse(String date) {
    final parts = date.split('-');
    if (parts.length != 3) {
      throw ArgumentError('Invalid date format: $date');
    }
    return Date(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// JSON deserialization (`yyyy-MM-dd`).
  factory Date.fromJson(String json) => Date.parse(json);

  /// Extracts the date from a [DateTime].
  Date.fromDateTime(DateTime dt) : this(dt.year, dt.month, dt.day);

  // -- Properties ------------------------------------------------------------

  /// Day of the week (1 = Monday, 7 = Sunday). Matches [DateTime.weekday].
  int get weekday => DateTime(year, month, day).weekday;

  // -- Static utilities ------------------------------------------------------

  /// Whether [year] is a leap year.
  static bool isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  /// The number of days in [month] of [year].
  static int daysInMonth(int year, int month) {
    const days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && isLeapYear(year)) return 29;
    return days[month];
  }

  // -- Operations ------------------------------------------------------------

  /// Returns a new [Date] with [days] added (or subtracted if negative).
  Date addDays(int days) {
    final dt = DateTime(year, month, day).add(Duration(days: days));
    return Date._unchecked(dt.year, dt.month, dt.day);
  }

  bool isSameDay(Date other) => this == other;

  // -- Comparable ------------------------------------------------------------

  @override
  int compareTo(Date other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  bool operator >(Date other) => compareTo(other) > 0;
  bool operator >=(Date other) => compareTo(other) >= 0;
  bool operator <(Date other) => compareTo(other) < 0;
  bool operator <=(Date other) => compareTo(other) <= 0;

  // -- Serialization ---------------------------------------------------------

  String toJson() => toString();

  @override
  String toString() {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // -- Object ----------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Date && year == other.year && month == other.month && day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);
}
