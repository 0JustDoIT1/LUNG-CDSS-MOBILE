import '../../../../core/network/api_exception.dart';

String guardianErrorMessage(Object error) {
  if (error is ApiException) {
    if (error.statusCode == 401) return '로그인 정보가 만료되었습니다.';
    if (error.statusCode == 403) return '연결된 환자 정보를 조회할 권한이 없습니다.';
    if (error.statusCode == 404) return '연결된 환자 정보를 찾을 수 없습니다.';
    if (error.code == 'TIMEOUT') return '서버 응답 시간이 초과되었습니다.';
    if (error.code == 'CONNECTION_ERROR') return '네트워크 연결을 확인해주세요.';
    if (error.statusCode == 500 ||
        error.statusCode == 502 ||
        error.statusCode == 503) {
      return '서버에서 정보를 불러오지 못했습니다.';
    }
  }
  if (error is FormatException) return '보호자 정보 형식을 확인할 수 없습니다.';
  return '정보를 불러오지 못했습니다.';
}

String guardianDateTimeLabel(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}.${two(local.month)}.${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

String guardianDateLabel(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}.${two(local.month)}.${two(local.day)}';
}

String guardianAppointmentStatusLabel(String status) {
  return switch (status) {
    'requested' => '예약 요청',
    'confirmed' || 'reminded_d7' || 'reminded_d1' => '예약 확정',
    'checked_in' => '접수 완료',
    'completed' => '진료 완료',
    'cancelled' => '예약 취소',
    'no_show' => '미방문',
    _ => '상태 확인 필요',
  };
}

String guardianSubtypeLabel(String? subtype) {
  return switch (subtype?.toUpperCase()) {
    'LUAD' => '폐선암(LUAD)',
    'LUSC' => '편평상피세포암(LUSC)',
    null || '' => '최종 결과 확인 중',
    _ => '확정 결과 확인 필요',
  };
}
