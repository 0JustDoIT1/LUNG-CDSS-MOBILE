import '../models/reservation.dart';

/// 화면 확인용 mock 신청 목록.
List<ReservationRequest> mockReservationRequests() {
  final now = DateTime.now();
  return [
    ReservationRequest(
      id: 'R-1',
      patientName: '김O수',
      department: '호흡기내과',
      doctorName: '김의사',
      desiredDateTime: now.add(const Duration(days: 2, hours: 3)),
      requestedAt: now.subtract(const Duration(hours: 1)),
    ),
    ReservationRequest(
      id: 'R-2',
      patientName: '이O진',
      department: '호흡기내과',
      doctorName: '박의사',
      desiredDateTime: now.add(const Duration(days: 3, hours: 5)),
      requestedAt: now.subtract(const Duration(hours: 4)),
    ),
  ];
}

/// 화면 확인용 mock 오늘 예약 목록.
List<TodayAppointment> mockTodayAppointments() {
  final now = DateTime.now();
  DateTime t(int hour, int minute) =>
      DateTime(now.year, now.month, now.day, hour, minute);

  return [
    TodayAppointment(
      id: 'T-1',
      patientName: '최O수',
      dateTime: t(9, 30),
      status: CheckInStatus.checkedIn,
    ),
    TodayAppointment(
      id: 'T-2',
      patientName: '정O아',
      dateTime: t(10, 30),
      status: CheckInStatus.waiting,
    ),
    TodayAppointment(
      id: 'T-3',
      patientName: '박O훈',
      dateTime: t(11, 0),
      status: CheckInStatus.noShow,
    ),
    TodayAppointment(
      id: 'T-4',
      patientName: '한O영',
      dateTime: t(14, 0),
      status: CheckInStatus.waiting,
    ),
  ];
}