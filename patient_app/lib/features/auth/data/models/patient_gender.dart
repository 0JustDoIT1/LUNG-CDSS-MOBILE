enum PatientGender {
  female('female', '여성'),
  male('male', '남성');

  const PatientGender(this.apiValue, this.label);

  final String apiValue;
  final String label;
}
