import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/appointment/data/models/appointment_booking.dart';

void main() {
  test('parses department object', () {
    final value = AppointmentDepartment.fromJson(<String, dynamic>{
      'code': '호흡기내과',
      'name': '호흡기내과',
    });
    expect(value.code, '호흡기내과');
  });

  test('parses doctor nullable and list fields without reordering', () {
    final value = AppointmentDoctor.fromJson(<String, dynamic>{
      'id': 'doctor-id',
      'name': '김의사',
      'department': '호흡기내과',
      'photo_url': null,
      'specialty_tags': <String>[],
      'is_assigned': true,
      'weekly_schedule': <dynamic>[
        <String, dynamic>{
          'day_of_week': 'mon',
          'period': 'am',
          'available': true,
        },
      ],
    });
    expect(value.photoUrl, isNull);
    expect(value.specialtyTags, isEmpty);
    expect(value.weeklySchedule.single.dayOfWeek, 'mon');
  });

  test('parses available and closed slots while preserving status', () {
    final value = AppointmentSlots.fromJson(<String, dynamic>{
      'date': '2026-08-10',
      'timezone': 'Asia/Seoul',
      'slots': <dynamic>[
        <String, dynamic>{
          'time': '09:00',
          'datetime': '2026-08-10T09:00:00+09:00',
          'status': 'closed',
        },
        <String, dynamic>{
          'time': '09:30',
          'datetime': '2026-08-10T09:30:00+09:00',
          'status': 'available',
        },
      ],
    });
    expect(value.timezone, 'Asia/Seoul');
    expect(value.slots.map((slot) => slot.status), <String>[
      'closed',
      'available',
    ]);
    expect(value.slots.last.dateTimeValue, '2026-08-10T09:30:00+09:00');
  });
}
