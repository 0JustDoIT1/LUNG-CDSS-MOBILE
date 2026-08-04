import '../models/test_result.dart';

class MockTestResultData {
  const MockTestResultData._();

  static final List<TestResult> results = [
    TestResult(
      id: 'test-001',
      testName: '폐암 조직병리 AI 분석',
      testDate: DateTime(2026, 7, 30),
      resultStatus: '결과 확인 가능',
      cancerSubtype: 'LUAD',
      luadProbability: 0.87,
      luscProbability: 0.13,
      genePredictions: const [
        GenePredictionResult(
          geneName: 'TP53',
          probability: 0.91,
        ),
        GenePredictionResult(
          geneName: 'KEAP1',
          probability: 0.68,
        ),
        GenePredictionResult(
          geneName: 'KRAS',
          probability: 0.07,
        ),
      ],
      doctorOpinion:
          'AI 분석 결과 폐선암 가능성이 높게 확인되었습니다. '
          '유전자 변이 예측 결과는 확진 검사를 대체하지 않으며, '
          '추가 분자검사 결과와 함께 담당 의료진의 판단이 필요합니다.',
      reviewedBy: '김호흡',
      reviewedAt: DateTime(
        2026,
        7,
        31,
        14,
        20,
      ),
    ),
    TestResult(
      id: 'test-002',
      testName: '폐암 유전자 변이 검사',
      testDate: DateTime(2026, 6, 18),
      resultStatus: '의료진 검토 완료',
      cancerSubtype: 'LUSC',
      luadProbability: 0.18,
      luscProbability: 0.82,
      genePredictions: const [
        GenePredictionResult(
          geneName: 'TP53',
          probability: 0.86,
        ),
        GenePredictionResult(
          geneName: 'KEAP1',
          probability: 0.21,
        ),
        GenePredictionResult(
          geneName: 'KRAS',
          probability: 0.73,
        ),
      ],
      doctorOpinion:
          '편평상피암 가능성이 높게 확인되었습니다. '
          '예측 결과는 참고 정보이며 최종 진단은 병리검사와 '
          '분자검사 결과를 종합하여 결정합니다.',
      reviewedBy: '김호흡',
      reviewedAt: DateTime(
        2026,
        6,
        19,
        11,
        10,
      ),
    ),
  ];
}