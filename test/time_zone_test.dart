import 'package:sigan/sigan.dart';
import 'package:test/test.dart';

void main() {
  group('TimeZone', () {
    // =============================================
    // Constants
    // =============================================
    group('constants', () {
      test('UTC is +00:00', () {
        expect(TimeZone.utc.totalMinutes, 0);
        expect(TimeZone.utc.isoOffset, '+00:00');
      });

      test('KST is +09:00', () {
        expect(TimeZone.kst.hours, 9);
        expect(TimeZone.kst.minutes, 0);
        expect(TimeZone.kst.totalMinutes, 540);
        expect(TimeZone.kst.isoOffset, '+09:00');
      });

      test('IST is +05:30', () {
        expect(TimeZone.ist.hours, 5);
        expect(TimeZone.ist.minutes, 30);
        expect(TimeZone.ist.totalMinutes, 330);
        expect(TimeZone.ist.isoOffset, '+05:30');
      });

      test('EST is -05:00', () {
        expect(TimeZone.est.hours, -5);
        expect(TimeZone.est.minutes, 0);
        expect(TimeZone.est.totalMinutes, -300);
        expect(TimeZone.est.isoOffset, '-05:00');
      });

      test('PST is -08:00', () {
        expect(TimeZone.pst.totalMinutes, -480);
      });
    });

    // =============================================
    // DST constants
    // =============================================
    group('DST constants', () {
      test('EDT is -04:00', () {
        expect(TimeZone.edt.totalMinutes, -240);
      });

      test('CDT is -05:00', () {
        expect(TimeZone.cdt.totalMinutes, -300);
      });

      test('PDT is -07:00', () {
        expect(TimeZone.pdt.totalMinutes, -420);
      });

      test('CEST is +02:00', () {
        expect(TimeZone.cest.totalMinutes, 120);
      });

      test('BST is +01:00', () {
        expect(TimeZone.bst.totalMinutes, 60);
      });

      test('NZDT is +13:00', () {
        expect(TimeZone.nzdt.totalMinutes, 780);
      });
    });

    // =============================================
    // CST collision
    // =============================================
    group('CST collision', () {
      test('fromName CST returns US Central (-6)', () {
        final tz = TimeZone.fromName('CST');
        expect(tz.totalMinutes, -360);
      });

      test('cstChina is +08:00', () {
        expect(TimeZone.cstChina.totalMinutes, 480);
      });

      test('CST and cstChina have same name but different offsets', () {
        expect(TimeZone.cst.name, 'CST');
        expect(TimeZone.cstChina.name, 'CST');
        expect(TimeZone.cst == TimeZone.cstChina, isFalse);
      });
    });

    // =============================================
    // fromName
    // =============================================
    group('fromName', () {
      test('known zones', () {
        expect(TimeZone.fromName('UTC'), TimeZone.utc);
        expect(TimeZone.fromName('KST'), TimeZone.kst);
        expect(TimeZone.fromName('EST'), TimeZone.est);
      });

      test('unknown throws', () {
        expect(() => TimeZone.fromName('FAKE'), throwsArgumentError);
      });
    });

    // =============================================
    // fromOffset
    // =============================================
    group('fromOffset', () {
      test('Z returns UTC', () {
        expect(TimeZone.fromOffset('Z'), TimeZone.utc);
      });

      test('+09:00 returns KST', () {
        expect(TimeZone.fromOffset('+09:00'), TimeZone.kst);
      });

      test('+0900 returns KST', () {
        expect(TimeZone.fromOffset('+0900'), TimeZone.kst);
      });

      test('+09 returns KST', () {
        expect(TimeZone.fromOffset('+09'), TimeZone.kst);
      });

      test('-05:00 returns EST', () {
        expect(TimeZone.fromOffset('-05:00'), TimeZone.est);
      });

      test('+05:45 (Nepal) creates anonymous zone', () {
        final tz = TimeZone.fromOffset('+05:45');
        expect(tz.totalMinutes, 345);
        expect(tz.isoOffset, '+05:45');
      });

      test('+14:00 (Kiribati) creates anonymous zone', () {
        final tz = TimeZone.fromOffset('+14:00');
        expect(tz.totalMinutes, 840);
      });

      test('-12:00 (Baker Island) creates anonymous zone', () {
        final tz = TimeZone.fromOffset('-12:00');
        expect(tz.totalMinutes, -720);
      });

      test('invalid format throws', () {
        expect(() => TimeZone.fromOffset('invalid'), throwsArgumentError);
      });
    });

    // =============================================
    // Properties
    // =============================================
    group('properties', () {
      test('offset returns Duration', () {
        expect(TimeZone.kst.offset, const Duration(hours: 9));
        expect(TimeZone.est.offset, const Duration(hours: -5));
        expect(TimeZone.ist.offset, const Duration(hours: 5, minutes: 30));
      });

      test('name returns identifier', () {
        expect(TimeZone.kst.name, 'KST');
      });
    });

    // =============================================
    // Equality
    // =============================================
    group('equality', () {
      test('same offset = equal (KST == JST)', () {
        expect(TimeZone.kst == TimeZone.jst, isTrue);
        expect(TimeZone.kst.hashCode, TimeZone.jst.hashCode);
      });

      test('different offset = not equal', () {
        expect(TimeZone.kst == TimeZone.utc, isFalse);
      });

      test('anonymous zone with matching offset equals predefined', () {
        final anon = TimeZone.fromOffset('+09:00');
        expect(anon == TimeZone.kst, isTrue);
      });
    });

    // =============================================
    // toString
    // =============================================
    group('toString', () {
      test('returns name', () {
        expect(TimeZone.kst.toString(), 'KST');
        expect(TimeZone.utc.toString(), 'UTC');
      });
    });

    // =============================================
    // Values list
    // =============================================
    group('values', () {
      test('contains 33 entries', () {
        expect(TimeZone.values.length, 33);
      });

      test('all have non-empty names', () {
        for (final tz in TimeZone.values) {
          expect(tz.name.isNotEmpty, isTrue);
        }
      });
    });
  });
}
