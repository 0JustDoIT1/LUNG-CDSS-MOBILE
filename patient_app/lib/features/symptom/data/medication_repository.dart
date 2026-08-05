import 'medication_api.dart';
import 'models/medication_log.dart';

class MedicationRepository {
  MedicationRepository(this._medicationApi);

  final MedicationApi _medicationApi;

  Future<List<MedicationLog>> getTodayMedicationLogs() async {
    final logs = await _medicationApi.getTodayMedicationLogs();
    return parseMedicationLogs(logs);
  }

  Future<MedicationLog> markAsTaken(String logId) async {
    final log = await _medicationApi.markAsTaken(logId);
    return MedicationLog.fromJson(log);
  }

  static List<MedicationLog> parseMedicationLogs(List<dynamic> logs) {
    return logs
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('오늘 복약 목록의 각 항목은 객체여야 합니다.');
          }

          return MedicationLog.fromJson(item);
        })
        .toList(growable: false);
  }
}
