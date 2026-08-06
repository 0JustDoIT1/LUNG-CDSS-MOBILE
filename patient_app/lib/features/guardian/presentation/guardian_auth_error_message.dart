import '../../../core/network/api_exception.dart';

String guardianRegistrationErrorMessage(Object? error) {
  if (error is ApiException) {
    if (error.statusCode == 400) return '초대코드 또는 입력값을 확인해주세요.';
    if (error.statusCode == 404) return '유효하지 않은 초대코드입니다.';
    if (error.statusCode == 409) return '이미 사용된 초대코드입니다.';
    if (error.statusCode == 500 || error.statusCode == 503) {
      return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }
    if (error.code == 'TIMEOUT') return '서버 응답 시간이 초과되었습니다.';
    if (error.code == 'CONNECTION_ERROR') return '네트워크 연결을 확인해주세요.';
  }
  return '보호자 연동에 실패했습니다.';
}
