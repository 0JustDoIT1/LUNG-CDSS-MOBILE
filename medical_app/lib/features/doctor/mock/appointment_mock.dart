import '../models/appointment.dart';

/// 화면 확인용 mock 예약 데이터 (이번 달 기준으로 몇 건 흩어놓음).
List<Appointment> mockAppointments() {
  final now = DateTime.now();
  DateTime d(int day, int hour, int minute) =>
      DateTime(now.year, now.month, day, hour, minute);

  return [
    Appointment(
      id: 'A-1',
      patientName: '김O수',
      dateTime: d(now.day, 10, 30),
      status: AppointmentStatus.scheduled,
    ),
    Appointment(
      id: 'A-2',
      patientName: '이O진',
      dateTime: d(now.day, 14, 0),
      status: AppointmentStatus.scheduled,
    ),
    Appointment(
      id: 'A-3',
      patientName: '최O수',
      dateTime: d((now.day + 2).clamp(1, 28), 9, 0),
      status: AppointmentStatus.scheduled,
    ),
    Appointment(
      id: 'A-4',
      patientName: '박O훈',
      dateTime: d((now.day - 1).clamp(1, 28), 11, 0),
      status: AppointmentStatus.visited,
    ),
    Appointment(
      id: 'A-5',
      patientName: '정O아',
      dateTime: d((now.day - 3).clamp(1, 28), 15, 30),
      status: AppointmentStatus.noShow,
    ),
  ];
}