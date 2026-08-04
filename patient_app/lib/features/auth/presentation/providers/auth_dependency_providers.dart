import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/token_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../data/auth_api.dart';
import '../../data/auth_repository.dart';
import '../../data/google_sign_in_service.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  return ApiClient(
    tokenStorage: tokenStorage,
  );
});

final authApiProvider = Provider<AuthApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);

  return AuthApi(
    apiClient: apiClient,
  );
});

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authApi = ref.watch(authApiProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);

  return AuthRepository(
    authApi: authApi,
    tokenStorage: tokenStorage,
  );
});