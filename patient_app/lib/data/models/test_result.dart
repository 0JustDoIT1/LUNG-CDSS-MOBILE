class TestResult {
  const TestResult({
    required this.id,
    required this.testName,
    required this.testDate,
    required this.resultStatus,
    required this.cancerSubtype,
    required this.luadProbability,
    required this.luscProbability,
    required this.genePredictions,
    required this.doctorOpinion,
    required this.reviewedBy,
    required this.reviewedAt,
  });

  final String id;
  final String testName;
  final DateTime testDate;
  final String resultStatus;

  final String cancerSubtype;
  final double luadProbability;
  final double luscProbability;

  final List<GenePredictionResult> genePredictions;

  final String doctorOpinion;
  final String reviewedBy;
  final DateTime reviewedAt;
}

class GenePredictionResult {
  const GenePredictionResult({
    required this.geneName,
    required this.probability,
  });

  final String geneName;
  final double probability;
}