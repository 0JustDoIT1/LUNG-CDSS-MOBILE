abstract final class RouteNames {
  static const String splash = '/';
  static const String login = '/login';
  static const String phoneVerification = '/phone-verification';
  static const String otpVerification = '/otp-verification';
  static const String home = '/home';

  static const String symptoms = '/symptoms';
  static const String medication = '/medication';
  static const String appointments = '/appointments';
  static const String results = '/results';
  static const String more = '/more';

  static const String chatbot = '/chatbot';
  static const String notifications = '/notifications';
  static const String patientQr = '/patient-qr';
  static const String intakeForm = '/intake-form';
  static const String settings = '/settings';
  static const String pinLock = '/pin-lock'; //pin 잠금
  static const String biometricAuth = '/biometric-auth'; // 생체인증
  static const String resultDetail = '/results/:resultId'; //상세 화면 라우터 연결
  static const String symptomRecordForm = '/symptom-record'; //증상 기록 
  static const String symptomRecordList = '/symptom-records'; // 전체 증상 기록
  static const String appointmentDetail =
    '/appointments/:appointmentId'; // 예약
  static const String intakeIntro = '/intake'; // 문진
  static const String intakeFormWrite = '/intake/write'; // 문진작성
  static const String intakeCompleted = '/intake/completed'; // 문진완료
  static const String intakeAnswers = '/intake/answers'; // 문진답변
  static const String profile = '/profile'; // 환자 프로필
  static const String appointmentCreate = '/appointments/create';
  static const String guardianLogin = '/guardian-login';
  static const String guardianHome = '/guardian-home';
  static const String guardianLink = '/guardian-link';
}