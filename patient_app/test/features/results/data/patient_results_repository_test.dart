import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/results/data/patient_results_repository.dart';

void main() {
  group('PatientResultsRepository.parseResults', () {
    test('rejects an array item that is not an object', () {
      expect(
        () => PatientResultsRepository.parseResults(<dynamic>['invalid']),
        throwsFormatException,
      );
    });

    test('parses an empty array', () {
      final results = PatientResultsRepository.parseResults(<dynamic>[]);

      expect(results, isEmpty);
    });
  });
}
