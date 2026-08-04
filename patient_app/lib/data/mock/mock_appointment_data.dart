import '../models/appointment.dart';

class MockAppointmentData {
  const MockAppointmentData._();

  static final List<Appointment> appointments = [
    Appointment(
      id: 'appointment-001',
      department: '호흡기내과',
      doctorName: '김호흡',
      hospitalName: '숨잇대학교병원',
      location: '본관 3층 호흡기내과',
      appointmentAt: DateTime(
        2026,
        8,
        5,
        10,
        30,
      ),
      status: AppointmentStatus.scheduled,
      purpose: '검사결과 상담',
      memo: '진료 전 문진표를 작성해주세요.',
    ),
    Appointment(
      id: 'appointment-002',
      department: '종양내과',
      doctorName: '이종양',
      hospitalName: '숨잇대학교병원',
      location: '암센터 2층 종양내과',
      appointmentAt: DateTime(
        2026,
        8,
        14,
        14,
      ),
      status: AppointmentStatus.scheduled,
      purpose: '치료계획 상담',
      memo: '현재 복용 중인 약 목록을 지참해주세요.',
    ),
    Appointment(
      id: 'appointment-003',
      department: '호흡기내과',
      doctorName: '김호흡',
      hospitalName: '숨잇대학교병원',
      location: '본관 3층 호흡기내과',
      appointmentAt: DateTime(
        2026,
        7,
        18,
        11,
      ),
      status: AppointmentStatus.completed,
      purpose: '정기 진료',
      memo: '다음 진료 전 혈액검사 예정',
    ),
    Appointment(
      id: 'appointment-004',
      department: '영상의학과',
      doctorName: '박영상',
      hospitalName: '숨잇대학교병원',
      location: '본관 1층 영상의학과',
      appointmentAt: DateTime(
        2026,
        7,
        4,
        9,
        20,
      ),
      status: AppointmentStatus.cancelled,
      purpose: '흉부 CT 검사',
      memo: '환자 요청으로 취소되었습니다.',
    ),
  ];
}