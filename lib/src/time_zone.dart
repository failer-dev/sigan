/// A fixed UTC offset.
///
/// ```dart
/// print(TimeZone.kst.isoOffset); // +09:00
/// print(TimeZone.est.offset);    // Duration(hours: -5)
/// ```
///
/// Includes predefined constants for common zones. For offsets not
/// covered by a constant, [fromOffset] creates an anonymous instance.
///
/// **Design note:** Predefined constants (e.g. [kst], [est]) are
/// convenience shorthands for writing code. Serialized data always
/// carries the numeric offset (e.g. `+09:00`), so even if a country
/// changes its offset in the future, previously stored timestamps
/// remain correct — the offset is baked into the string, not resolved
/// at read time. This is an intentional departure from IANA zone IDs
/// (`Asia/Seoul`) which require a database to resolve.
class TimeZone {
  /// The short identifier (e.g. `'KST'`, `'UTC'`).
  final String name;

  /// The total offset from UTC in minutes.
  final int totalMinutes;

  /// Creates a [TimeZone] with [hours] and optional [minutes] offset.
  const TimeZone(this.name, int hours, [int minutes = 0])
      : totalMinutes = hours * 60 + (hours < 0 ? -minutes : minutes);

  const TimeZone._internal(this.name, this.totalMinutes);

  // -- Constants (standard) --------------------------------------------------

  static const utc = TimeZone('UTC', 0);
  static const gmt = TimeZone('GMT', 0);

  // Asia / Oceania
  static const kst = TimeZone('KST', 9);
  static const jst = TimeZone('JST', 9);
  static const cstChina = TimeZone('CST', 8);
  static const sgt = TimeZone('SGT', 8);
  static const awst = TimeZone('AWST', 8);
  static const ict = TimeZone('ICT', 7);
  static const ist = TimeZone('IST', 5, 30);
  static const aest = TimeZone('AEST', 10);
  static const nzt = TimeZone('NZT', 12);

  // Europe
  static const cet = TimeZone('CET', 1);
  static const eet = TimeZone('EET', 2);

  // Americas
  static const est = TimeZone('EST', -5);
  static const cst = TimeZone('CST', -6);
  static const mst = TimeZone('MST', -7);
  static const pst = TimeZone('PST', -8);
  static const akst = TimeZone('AKST', -9);
  static const hst = TimeZone('HST', -10);
  static const sst = TimeZone('SST', -11);
  static const ast = TimeZone('AST', -4);
  static const art = TimeZone('ART', -3);
  static const brt = TimeZone('BRT', -3);

  // -- Constants (daylight saving) -------------------------------------------

  static const bst = TimeZone('BST', 1);
  static const cest = TimeZone('CEST', 2);
  static const eest = TimeZone('EEST', 3);
  static const edt = TimeZone('EDT', -4);
  static const cdt = TimeZone('CDT', -5);
  static const mdt = TimeZone('MDT', -6);
  static const pdt = TimeZone('PDT', -7);
  static const akdt = TimeZone('AKDT', -8);
  static const nzdt = TimeZone('NZDT', 13);
  static const aedt = TimeZone('AEDT', 11);

  /// All predefined time zones.
  ///
  /// `CST` maps to US Central (-06:00). Use [cstChina] for China (+08:00).
  static const List<TimeZone> values = [
    utc, gmt,
    // Asia / Oceania
    kst, jst, sgt, awst, ict, ist, aest, nzt,
    // Europe
    cet, eet,
    // Americas (CST = US Central before cstChina)
    est, cst, mst, pst, akst, hst, sst, ast, art, brt,
    // China
    cstChina,
    // Daylight saving
    bst, cest, eest, edt, cdt, mdt, pdt, akdt, nzdt, aedt,
  ];

  // -- Factories -------------------------------------------------------------

  /// Looks up a predefined zone by [name] (e.g. `'KST'`).
  ///
  /// Throws [ArgumentError] if not found.
  static TimeZone fromName(String name) {
    for (final tz in values) {
      if (tz.name == name) return tz;
    }
    throw ArgumentError('Unknown time zone: $name');
  }

  /// Creates a [TimeZone] from an offset string (`'Z'`, `'+09:00'`,
  /// `'+0900'`, `'+09'`).
  ///
  /// Returns a predefined constant if one matches, otherwise an anonymous
  /// instance.
  static TimeZone fromOffset(String offset) {
    if (offset == 'Z') return utc;

    final match = RegExp(r'([+-])(\d{2}):?(\d{2})?').firstMatch(offset);
    if (match == null) {
      throw ArgumentError('Invalid offset format: $offset');
    }

    final sign = match.group(1) == '+' ? 1 : -1;
    final h = int.parse(match.group(2)!);
    final m = int.parse(match.group(3) ?? '0');
    if (m > 59) {
      throw ArgumentError('Invalid offset minutes: $offset');
    }
    final target = (h * 60 + m) * sign;
    if (target < -720 || target > 840) {
      throw ArgumentError('Offset out of range (-12:00 to +14:00): $offset');
    }

    for (final tz in values) {
      if (tz.totalMinutes == target) return tz;
    }

    return TimeZone._internal('OFFSET $offset', target);
  }

  // -- Properties ------------------------------------------------------------

  /// The offset hours component.
  int get hours => totalMinutes ~/ 60;

  /// The offset minutes component (always non-negative).
  int get minutes => (totalMinutes % 60).abs();

  /// The offset as a [Duration].
  Duration get offset => Duration(minutes: totalMinutes);

  /// The offset in ISO 8601 format (e.g. `'+09:00'`).
  String get isoOffset {
    final sign = totalMinutes >= 0 ? '+' : '-';
    final abs = totalMinutes.abs();
    final h = (abs ~/ 60).toString().padLeft(2, '0');
    final m = (abs % 60).toString().padLeft(2, '0');
    return '$sign$h:$m';
  }

  // -- Object ----------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeZone && totalMinutes == other.totalMinutes;

  @override
  int get hashCode => totalMinutes.hashCode;

  @override
  String toString() => name;
}
