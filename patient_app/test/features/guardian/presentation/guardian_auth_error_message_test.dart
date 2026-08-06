import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/guardian/presentation/guardian_auth_error_message.dart';

void main() {
  test('maps guardian registration HTTP failures safely', () {
    expect(
      guardianRegistrationErrorMessage(
        const ApiException(message: 'raw', statusCode: 400),
      ),
      '초대코드 또는 입력값을 확인해주세요.',
    );
    expect(
      guardianRegistrationErrorMessage(
        const ApiException(message: 'raw', statusCode: 404),
      ),
      '유효하지 않은 초대코드입니다.',
    );
    expect(
      guardianRegistrationErrorMessage(
        const ApiException(message: 'raw', statusCode: 409),
      ),
      '이미 사용된 초대코드입니다.',
    );
    for (final statusCode in <int>[500, 503]) {
      expect(
        guardianRegistrationErrorMessage(
          ApiException(message: 'raw', statusCode: statusCode),
        ),
        '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
      );
    }
  });

  test('maps timeout and connection failures safely', () {
    expect(
      guardianRegistrationErrorMessage(
        const ApiException(message: 'raw', code: 'TIMEOUT'),
      ),
      '서버 응답 시간이 초과되었습니다.',
    );
    expect(
      guardianRegistrationErrorMessage(
        const ApiException(message: 'raw', code: 'CONNECTION_ERROR'),
      ),
      '네트워크 연결을 확인해주세요.',
    );
  });
}
