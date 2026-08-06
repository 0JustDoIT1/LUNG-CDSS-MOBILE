import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/app/routes/route_names.dart';
import 'package:patient_app/core/auth/auth_role.dart';

void main() {
  test('patient role restores the patient home', () {
    expect(RouteNames.homeForRole(AuthRole.patient), RouteNames.home);
  });

  test('guardian role restores the guardian home', () {
    expect(RouteNames.homeForRole(AuthRole.guardian), RouteNames.guardianHome);
  });

  test('missing or unknown stored role has no home route', () {
    expect(RouteNames.homeForRole(null), isNull);
    expect(AuthRole.fromStorage('unknown'), isNull);
  });
}
