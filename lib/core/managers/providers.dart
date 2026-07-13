import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/core/data/token_storage.dart';
import 'package:customer_app/core/data/app_storage.dart';
import 'package:customer_app/core/data/api_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Create a global provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main.dart');
});

// Create a global provider for AppStorage
final appStorageProvider = Provider<AppStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppStorage(prefs);
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TokenStorage(prefs);
});

// Create a global provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiService(tokenStorage, ref);
});

// Central API Repository provider
final apiRepositoryProvider = Provider<ApiRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ApiRepository(apiService.dio);
});

