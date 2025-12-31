import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sr_ghani/services/auth_service.dart';
import 'package:sr_ghani/services/storage_service.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid;
  return SettingsRepository(userId, ref);
});

class SettingsRepository {
  final String? _userId;
  final Ref _ref;

  SettingsRepository(this._userId, this._ref);

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  DocumentReference get _settingsDoc => _firestore.collection('users').doc(_userId).collection('config').doc('business_settings');

  Future<void> syncSettingsToCloud() async {
    if (_userId == null) return;
    
    final storage = _ref.read(storageServiceProvider);
    await _settingsDoc.set({
      'standardPrice': storage.standardPrice,
      'seedTypes': storage.seedTypes,
      'khaliCharges': storage.khaliCharges,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> syncSettingsFromCloud() async {
    if (_userId == null) return;

    final doc = await _settingsDoc.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final storage = _ref.read(storageServiceProvider);
      
      if (data.containsKey('standardPrice')) {
        await storage.setStandardPrice(data['standardPrice']);
      }
      if (data.containsKey('seedTypes')) {
        await storage.setSeedTypes(List<String>.from(data['seedTypes']));
      }
      if (data.containsKey('khaliCharges')) {
        await storage.setKhaliCharges(Map<String, double>.from(data['khaliCharges']));
      }
    }
  }

  Future<void> clearCloudSettings() async {
    if (_userId == null) return;
    await _settingsDoc.delete();
  }
}
