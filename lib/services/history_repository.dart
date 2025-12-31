import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sr_ghani/models/history_model.dart';
import 'package:sr_ghani/models/customer_model.dart';
import 'package:sr_ghani/services/auth_service.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid;
  return HistoryRepository(userId);
});

class HistoryRepository {
  final String? _userId;
  final String _boxName = 'monthly_history';

  HistoryRepository(this._userId);

  Box<MonthlyHistory> get _box => Hive.box<MonthlyHistory>(_boxName);

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference get _historyCollection =>
      _firestore.collection('users').doc(_userId).collection('history');

  /// Add or update history for a specific month
  Future<void> saveMonthHistory(MonthlyHistory history) async {
    // Save to Hive first
    await _box.put(history.id, history);

    // Sync to Firestore if user ID exists
    if (_userId != null) {
      await _historyCollection.doc(history.id).set(history.toMap());
    }
  }

  /// Add a customer to a specific month's history
  Future<void> addCustomerToHistory(Customer customer, {int? year, int? month}) async {
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;
    final monthId = '$targetYear-${targetMonth.toString().padLeft(2, '0')}';

    // Get existing history or create new
    MonthlyHistory? history = _box.get(monthId);
    
    if (history == null) {
      history = MonthlyHistory.create(
        year: targetYear,
        month: targetMonth,
        customers: [customer],
      );
    } else {
      final updatedCustomers = List<Customer>.from(history.customers)..add(customer);
      history = history.copyWith(customers: updatedCustomers);
    }

    await saveMonthHistory(history);
  }

  /// Update a customer in history
  Future<void> updateCustomerInHistory(String monthId, Customer updatedCustomer) async {
    final history = _box.get(monthId);
    if (history == null) return;

    final updatedCustomers = history.customers.map((c) {
      return c.id == updatedCustomer.id ? updatedCustomer : c;
    }).toList();

    final newHistory = history.copyWith(customers: updatedCustomers);
    await saveMonthHistory(newHistory);
  }

  /// Delete a customer from history
  Future<void> deleteCustomerFromHistory(String monthId, String customerId) async {
    final history = _box.get(monthId);
    if (history == null) return;

    final updatedCustomers = history.customers.where((c) => c.id != customerId).toList();

    if (updatedCustomers.isEmpty) {
      // If no customers left, delete the entire month
      await deleteMonthHistory(monthId);
    } else {
      final newHistory = history.copyWith(customers: updatedCustomers);
      await saveMonthHistory(newHistory);
    }
  }

  /// Delete entire month's history
  Future<void> deleteMonthHistory(String monthId) async {
    await _box.delete(monthId);
    if (_userId != null) {
      await _historyCollection.doc(monthId).delete();
    }
  }

  /// Archive all current customers to history
  Future<void> archiveCustomersToHistory(List<Customer> customers, {int? year, int? month}) async {
    if (customers.isEmpty) return;

    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;

    final history = MonthlyHistory.create(
      year: targetYear,
      month: targetMonth,
      customers: customers,
    );

    await saveMonthHistory(history);
  }

  /// Get history for a specific month
  MonthlyHistory? getMonthHistory(String monthId) {
    return _box.get(monthId);
  }

  /// Get all history months (sorted newest first)
  List<MonthlyHistory> getAllHistory() {
    final histories = _box.values.toList();
    histories.sort((a, b) {
      if (a.year != b.year) return b.year.compareTo(a.year);
      return b.month.compareTo(a.month);
    });
    return histories;
  }

  /// Stream of all history changes
  Stream<List<MonthlyHistory>> watchHistory() {
    return _box.watch().map((_) => getAllHistory());
  }

  /// Delete a customer from history by ID (searches all months)
  Future<void> deleteCustomerFromAllHistory(String customerId) async {
    final histories = _box.values.toList();
    for (final history in histories) {
      if (history.customers.any((c) => c.id == customerId)) {
        await deleteCustomerFromHistory(history.id, customerId);
      }
    }
  }

  /// Clear all history (for factory reset)
  Future<void> clearAllHistory() async {
    await _box.clear();
    if (_userId != null) {
      final snapshot = await _historyCollection.get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }
}
