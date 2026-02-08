import 'package:sigan/sigan.dart';
import 'package:test/test.dart';

void main() {
  group('Time', () {
    // =============================================
    // Construction
    // =============================================
    group('construction', () {
      test('basic', () {
        final t = Time(14, 30);
        expect(t.hour, 14);
        expect(t.minute, 30);
      });

      test('midnight', () {
        final t = Time(0, 0);
        expect(t.hour, 0);
        expect(t.minute, 0);
      });

      test('end of day', () {
        final t = Time(23, 59);
        expect(t.hour, 23);
        expect(t.minute, 59);
      });

      test('fromDateTime', () {
        final t = Time.fromDateTime(DateTime(2025, 1, 1, 14, 30));
        expect(t.hour, 14);
        expect(t.minute, 30);
      });
    });

    // =============================================
    // fromJson
    // =============================================
    group('fromJson', () {
      test('int', () {
        final t = Time.fromJson(1430);
        expect(t.hour, 14);
        expect(t.minute, 30);
      });

      test('string', () {
        final t = Time.fromJson('1430');
        expect(t.hour, 14);
        expect(t.minute, 30);
      });

      test('midnight as 0', () {
        final t = Time.fromJson(0);
        expect(t.hour, 0);
        expect(t.minute, 0);
      });

      test('invalid type throws', () {
        expect(() => Time.fromJson(14.5), throwsArgumentError);
      });

      test('hour 24 throws', () {
        expect(() => Time.fromJson(2400), throwsA(anything));
      });

      test('minute 60 throws', () {
        expect(() => Time.fromJson(1260), throwsA(anything));
      });

      test('negative throws', () {
        expect(() => Time.fromJson(-1), throwsA(anything));
      });
    });

    // =============================================
    // Serialization roundtrip
    // =============================================
    group('serialization', () {
      test('toJson roundtrip', () {
        final t = Time(14, 30);
        final json = t.toJson();
        expect(json, 1430);
        expect(Time.fromJson(json), t);
      });

      test('midnight roundtrip', () {
        final t = Time(0, 0);
        expect(t.toJson(), 0);
        expect(Time.fromJson(0), t);
      });
    });

    // =============================================
    // Comparison
    // =============================================
    group('comparison', () {
      test('compareTo', () {
        final a = Time(14, 30);
        final b = Time(15, 0);
        expect(a.compareTo(b), lessThan(0));
        expect(b.compareTo(a), greaterThan(0));
        expect(a.compareTo(a), 0);
      });

      test('operators', () {
        final a = Time(14, 30);
        final b = Time(15, 0);
        expect(a < b, isTrue);
        expect(a <= b, isTrue);
        expect(b > a, isTrue);
        expect(b >= a, isTrue);
        expect(a <= a, isTrue);
        expect(a >= a, isTrue);
      });

      test('same hour different minute', () {
        final a = Time(14, 0);
        final b = Time(14, 30);
        expect(a < b, isTrue);
      });
    });

    // =============================================
    // Equality
    // =============================================
    group('equality', () {
      test('same values are equal', () {
        final a = Time(14, 30);
        final b = Time(14, 30);
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different values are not equal', () {
        final a = Time(14, 30);
        final b = Time(14, 31);
        expect(a == b, isFalse);
      });
    });

    // =============================================
    // toString
    // =============================================
    group('toString', () {
      test('formats as HH:mm', () {
        expect(Time(14, 30).toString(), '14:30');
        expect(Time(0, 0).toString(), '00:00');
        expect(Time(9, 5).toString(), '09:05');
      });
    });
  });
}
