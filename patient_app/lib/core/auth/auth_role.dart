enum AuthRole {
  patient('patient'),
  guardian('guardian');

  const AuthRole(this.storageValue);

  final String storageValue;

  static AuthRole? fromStorage(String? value) {
    for (final role in values) {
      if (role.storageValue == value) return role;
    }
    return null;
  }
}
