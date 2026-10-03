import '../models/app_settings_model.dart';
import '../services/firestore_service.dart';

/// Repository for app settings (payment methods, VIP prices).
class SettingsRepository {
  SettingsRepository({required this._firestoreService});

  final FirestoreService _firestoreService;

  /// Gets the app settings document.
  Future<AppSettingsModel?> getAppSettings() async {
    try {
      final doc = await _firestoreService.appSettings.get();
      if (!doc.exists) return null;
      return AppSettingsModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get app settings: ${e.toString()}');
    }
  }

  /// Updates app settings (admin only).
  Future<void> updateAppSettings(AppSettingsModel settings) async {
    try {
      await _firestoreService.appSettings.set(settings.toMap());
    } catch (e) {
      throw Exception('Failed to update app settings: ${e.toString()}');
    }
  }
}
