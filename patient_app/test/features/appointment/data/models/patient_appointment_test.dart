import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/appointment/data/models/patient_appointment.dart';

void main() {
  group('PatientAppointment.fromJson', () {
    test('parses valid JSON and all dates', () {
      final appointment = PatientAppointment.fromJson(_validJson);

      expect(appointment.id, 'appointment-uuid');
      expect(appointment.patientName, 'Patient');
      expect(appointment.doctorName, 'Doctor');
      expect(appointment.department, 'Pulmonology');
      expect(appointment.requestedAtSlot.year, 2026);
      expect(appointment.confirmedSlot, isNotNull);
      expect(appointment.createdAt.year, 2026);
      expect(appointment.status, 'confirmed');
    });

    test('keeps a null confirmed_slot as null', () {
      final appointment = PatientAppointment.fromJson({
        ..._validJson,
        'confirmed_slot': null,
      });

      expect(appointment.confirmedSlot, isNull);
    });

    test('rejects an invalid required field type', () {
      expect(
        () => PatientAppointment.fromJson({..._validJson, 'id': 1}),
        throwsFormatException,
      );
    });

    test('rejects an invalid requested_at_slot', () {
      expect(
        () => PatientAppointment.fromJson({
          ..._validJson,
          'requested_at_slot': 'invalid',
        }),
        throwsFormatException,
      );
    });

    test('rejects an invalid confirmed_slot', () {
      expect(
        () => PatientAppointment.fromJson({
          ..._validJson,
          'confirmed_slot': 'invalid',
        }),
        throwsFormatException,
      );
    });

    test('rejects an invalid created_at', () {
      expect(
        () => PatientAppointment.fromJson({
          ..._validJson,
          'created_at': 'invalid',
        }),
        throwsFormatException,
      );
    });

    test('preserves an unknown status', () {
      final appointment = PatientAppointment.fromJson({
        ..._validJson,
        'status': 'future_status',
      });

      expect(appointment.status, 'future_status');
    });
  });
}

const _validJson = <String, dynamic>{
  'id': 'appointment-uuid',
  'patient_name': 'Patient',
  'doctor_name': 'Doctor',
  'department': 'Pulmonology',
  'requested_at_slot': '2026-08-10T09:00:00+09:00',
  'confirmed_slot': '2026-08-10T10:00:00+09:00',
  'status': 'confirmed',
  'created_at': '2026-08-05T10:00:00+09:00',
};
