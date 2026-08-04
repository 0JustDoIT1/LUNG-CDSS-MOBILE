/// medical_app 안에서 로그인한 사용자의 역할.
/// 의사 / 간호사 두 역할을 이 앱 하나에서 분기 처리한다.
enum UserRole {
  doctor,
  nurse;

  String get label => switch (this) {
        UserRole.doctor => '의사',
        UserRole.nurse => '간호사',
      };
}
