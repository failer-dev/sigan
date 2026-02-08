import 'package:sigan/sigan.dart';
import 'package:test/test.dart';

void main() {
  group('Date', () {
    // =============================================
    // Construction
    // =============================================
    group('construction', () {
      test('basic', () {
        final d = Date(2025, 1, 15);
        expect(d.year, 2025);
        expect(d.month, 1);
        expect(d.day, 15);
      });

      test('fromDateTime', () {
        final d = Date.fromDateTime(DateTime(2025, 3, 14));
        expect(d, Date(2025, 3, 14));
      });

      test('today returns current date', () {
        final d = Date.today();
        final now = DateTime.now();
        expect(d.year, now.year);
        expect(d.month, now.month);
        expect(d.day, now.day);
      });
    });

    // =============================================
    // parse / fromJson
    // =============================================
    group('parse', () {
      test('valid yyyy-MM-dd', () {
        final d = Date.parse('2025-03-14');
        expect(d, Date(2025, 3, 14));
      });

      test('fromJson delegates to parse', () {
        final d = Date.fromJson('2025-03-14');
        expect(d, Date(2025, 3, 14));
      });

      test('invalid format throws', () {
        expect(() => Date.parse('2025/03/14'), throwsArgumentError);
        expect(() => Date.parse('not-a-date'), throwsA(anything));
      });

      test('non-existent date throws', () {
        expect(() => Date.parse('2025-02-30'), throwsArgumentError);
        expect(() => Date.parse('2025-04-31'), throwsArgumentError);
      });
    });

    // =============================================
    // Constructor validation
    // =============================================
    group('constructor validation', () {
      test('valid dates pass', () {
        Date(2025, 1, 1);
        Date(2024, 2, 29); // leap year
        Date(2025, 12, 31);
      });

      test('Feb 29 non-leap year throws', () {
        expect(() => Date(2025, 2, 29), throwsArgumentError);
      });

      test('Feb 30 throws', () {
        expect(() => Date(2024, 2, 30), throwsArgumentError);
      });

      test('Apr 31 throws', () {
        expect(() => Date(2025, 4, 31), throwsArgumentError);
      });

      test('Jun 31 throws', () {
        expect(() => Date(2025, 6, 31), throwsArgumentError);
      });
    });

    // =============================================
    // isLeapYear
    // =============================================
    group('isLeapYear', () {
      test('normal leap year (2024)', () {
        expect(Date.isLeapYear(2024), isTrue);
      });

      test('century non-leap (1900)', () {
        expect(Date.isLeapYear(1900), isFalse);
      });

      test('400-year leap (2000)', () {
        expect(Date.isLeapYear(2000), isTrue);
      });

      test('normal non-leap (2025)', () {
        expect(Date.isLeapYear(2025), isFalse);
      });
    });

    // =============================================
    // daysInMonth
    // =============================================
    group('daysInMonth', () {
      test('February leap year', () {
        expect(Date.daysInMonth(2024, 2), 29);
      });

      test('February non-leap year', () {
        expect(Date.daysInMonth(2025, 2), 28);
      });

      test('30-day months', () {
        for (final m in [4, 6, 9, 11]) {
          expect(Date.daysInMonth(2025, m), 30, reason: 'Month $m');
        }
      });

      test('31-day months', () {
        for (final m in [1, 3, 5, 7, 8, 10, 12]) {
          expect(Date.daysInMonth(2025, m), 31, reason: 'Month $m');
        }
      });
    });

    // =============================================
    // weekday
    // =============================================
    group('weekday', () {
      test('known dates', () {
        // 2025-01-01 is Wednesday
        expect(Date(2025, 1, 1).weekday, DateTime.wednesday);
        // 2024-02-29 is Thursday (leap day)
        expect(Date(2024, 2, 29).weekday, DateTime.thursday);
      });
    });

    // =============================================
    // addDays
    // =============================================
    group('addDays', () {
      test('positive days', () {
        expect(Date(2025, 1, 1).addDays(7), Date(2025, 1, 8));
      });

      test('negative days', () {
        expect(Date(2025, 1, 8).addDays(-7), Date(2025, 1, 1));
      });

      test('cross month boundary', () {
        expect(Date(2025, 1, 31).addDays(1), Date(2025, 2, 1));
      });

      test('cross year boundary', () {
        expect(Date(2024, 12, 31).addDays(1), Date(2025, 1, 1));
      });

      test('cross leap day', () {
        expect(Date(2024, 2, 28).addDays(1), Date(2024, 2, 29));
        expect(Date(2024, 2, 28).addDays(2), Date(2024, 3, 1));
      });
    });

    // =============================================
    // Comparison
    // =============================================
    group('comparison', () {
      test('compareTo', () {
        final a = Date(2025, 1, 1);
        final b = Date(2025, 1, 2);
        expect(a.compareTo(b), lessThan(0));
        expect(b.compareTo(a), greaterThan(0));
        expect(a.compareTo(a), 0);
      });

      test('operators', () {
        final a = Date(2025, 1, 1);
        final b = Date(2025, 1, 2);
        expect(a < b, isTrue);
        expect(b > a, isTrue);
        expect(a <= a, isTrue);
        expect(a >= a, isTrue);
      });

      test('isSameDay', () {
        expect(Date(2025, 1, 1).isSameDay(Date(2025, 1, 1)), isTrue);
        expect(Date(2025, 1, 1).isSameDay(Date(2025, 1, 2)), isFalse);
      });
    });

    // =============================================
    // Equality
    // =============================================
    group('equality', () {
      test('same values are equal', () {
        final a = Date(2025, 1, 1);
        final b = Date(2025, 1, 1);
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different values are not equal', () {
        expect(Date(2025, 1, 1) == Date(2025, 1, 2), isFalse);
      });
    });

    // =============================================
    // Serialization
    // =============================================
    group('serialization', () {
      test('toString', () {
        expect(Date(2025, 1, 1).toString(), '2025-01-01');
        expect(Date(1, 1, 1).toString(), '0001-01-01');
      });

      test('toJson roundtrip', () {
        final d = Date(2025, 3, 14);
        expect(Date.fromJson(d.toJson()), d);
      });
    });

    // =============================================
    // Boundary
    // =============================================
    group('boundary', () {
      test('earliest date', () {
        final d = Date(0, 1, 1);
        expect(d.year, 0);
      });

      test('year 9999', () {
        final d = Date(9999, 12, 31);
        expect(d.year, 9999);
        expect(d.month, 12);
        expect(d.day, 31);
      });
    });
  });
}
