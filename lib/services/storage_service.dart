import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final onboardingStatusProvider = StateProvider<bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.isOnboardingComplete;
});

final syncStatusProvider = StateProvider<bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.isSyncComplete;
});

class StorageService {
  SharedPreferences? _prefs;

  StorageService();

  void setPrefs(SharedPreferences prefs) {
    _prefs = prefs;
  }

  static const String _onboardingKey = 'onboarding_complete';
  static const String _standardPriceKey = 'standard_price';
  static const String _seedTypesKey = 'seed_types';
  static const String _khaliChargesKey = 'khali_charges';
  static const String _syncCompleteKey = 'sync_complete';
  static const String _lastResetDateKey = 'last_reset_date';

  bool get isOnboardingComplete => _prefs?.getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingComplete(dynamic ref) async {
    await _prefs?.setBool(_onboardingKey, true);
    ref.read(onboardingStatusProvider.notifier).state = true;
  }

  bool get isSyncComplete => _prefs?.getBool(_syncCompleteKey) ?? false;

  Future<void> setSyncComplete(dynamic ref, bool complete) async {
    await _prefs?.setBool(_syncCompleteKey, complete);
    ref.read(syncStatusProvider.notifier).state = complete;
  }

  // Standard Price
  double get standardPrice => _prefs?.getDouble(_standardPriceKey) ?? 20.0;
  Future<void> setStandardPrice(double price) async {
    await _prefs?.setDouble(_standardPriceKey, price);
  }

  // Seed Types
  List<String> get seedTypes {
    return _prefs?.getStringList(_seedTypesKey) ?? ['Mungfali', 'Til', 'Sarso', 'Castor', 'Soybean'];
  }

  Future<void> setSeedTypes(List<String> types) async {
    await _prefs?.setStringList(_seedTypesKey, types);
  }

  // Khali Charges
  Map<String, double> get khaliCharges {
    final raw = _prefs?.getString(_khaliChargesKey);
    if (raw == null) {
      return {
        'Til': 0.0,
        'Mungfali': 5.0,
        'Sarso': 5.0,
        'Castor': 5.0,
        'Soybean': 5.0,
      };
    }
    try {
      final Map<String, dynamic> decoded = json.decode(raw);
      return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (_) {
      return {};
    }
  }

  Future<void> setKhaliCharges(Map<String, double> charges) async {
    await _prefs?.setString(_khaliChargesKey, json.encode(charges));
  }

  // Last Reset Date
  DateTime? get lastResetDate {
    final timestamp = _prefs?.getInt(_lastResetDateKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> setLastResetDate(DateTime date) async {
    await _prefs?.setInt(_lastResetDateKey, date.millisecondsSinceEpoch);
  }

  Future<void> clearAll(Ref ref) async {
    await _prefs?.clear();
    ref.read(syncStatusProvider.notifier).state = false;
  }
}
