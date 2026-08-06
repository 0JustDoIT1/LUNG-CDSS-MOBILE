/// 서버는 항상 한국시간(+09:00) 오프셋을 붙여서 시각을 내려줌(예: "2026-08-06T14:00:00+09:00").
/// 이 앱은 한국 병원 하나만 다루는 단일 시간대 앱이라, 보는 사람 기기의 시스템 시간대와 무관하게
/// "서버가 적어준 시각 그대로"를 보여줘야 함(DateTime.parse(...).toLocal()은 기기 시간대에 따라
/// 값이 달라져서 기기가 한국 시간대가 아니면 엉뚱한 시각으로 보임).
///
/// 그래서 문자열 끝의 타임존 오프셋(Z 또는 +09:00 등)을 떼어내고, 적힌 숫자 그대로를
/// "naive"(타임존 정보 없는) DateTime으로 파싱함 — 기기 시간대 설정과 완전히 무관해짐.
DateTime parseServerDateTime(String raw) {
  final withoutOffset = raw.replaceFirst(RegExp(r'(Z|[+-]\d{2}:?\d{2})$'), '');
  return DateTime.parse(withoutOffset);
}
