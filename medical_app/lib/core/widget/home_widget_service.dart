import 'package:home_widget/home_widget.dart';

/// 홈스크린 위젯(안드로이드 전용, PendingCasesWidgetProvider.kt)에 검토대기 건수를 반영.
/// 데이터 저장 + 위젯 갱신 브로드캐스트를 함께 호출해야 화면에 실제로 반영됨.
Future<void> updatePendingCasesWidget({
  required int pendingCount,
  required int urgentCount,
}) async {
  await HomeWidget.saveWidgetData<int>('pending_count', pendingCount);
  await HomeWidget.saveWidgetData<int>('urgent_count', urgentCount);
  await HomeWidget.updateWidget(androidName: 'PendingCasesWidgetProvider');
}

/// 홈스크린 위젯(안드로이드 전용, PendingAppointmentsWidgetProvider.kt)에 예약요청 대기 건수를 반영.
Future<void> updatePendingAppointmentsWidget({required int requestCount}) async {
  await HomeWidget.saveWidgetData<int>('appointment_request_count', requestCount);
  await HomeWidget.updateWidget(androidName: 'PendingAppointmentsWidgetProvider');
}
