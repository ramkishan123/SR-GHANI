import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sr_ghani/services/storage_service.dart';
import 'package:sr_ghani/services/customer_repository.dart';
import 'package:sr_ghani/services/history_repository.dart';

final monthlyResetServiceProvider = Provider((ref) => MonthlyResetService(ref));

class MonthlyResetService {
  final Ref _ref;

  MonthlyResetService(this._ref);

  /// Check and perform monthly reset if needed
  Future<bool> checkAndPerformReset() async {
    final storage = _ref.read(storageServiceProvider);
    final lastResetDate = storage.lastResetDate;
    final now = DateTime.now();

    // If no last reset date, set it to now and skip reset
    if (lastResetDate == null) {
      await storage.setLastResetDate(now);
      return false;
    }

    // Check if we're in a new month
    final isNewMonth = now.year > lastResetDate.year ||
        (now.year == lastResetDate.year && now.month > lastResetDate.month);

    if (isNewMonth) {
      await _performMonthlyReset(lastResetDate);
      await storage.setLastResetDate(now);
      return true;
    }

    return false;
  }

  /// Perform the actual monthly reset
  Future<void> _performMonthlyReset(DateTime lastResetDate) async {
    try {
      final customerRepo = _ref.read(customerRepositoryProvider);
      final historyRepo = _ref.read(historyRepositoryProvider);

      // Get all current customers
      final customers = customerRepo.getAllCustomers();

      if (customers.isEmpty) {
        // No customers to archive, just update the reset date
        return;
      }

      // Archive customers to the previous month's history
      // We use lastResetDate's month/year because that's when these customers were active
      await historyRepo.archiveCustomersToHistory(
        customers,
        year: lastResetDate.year,
        month: lastResetDate.month,
      );

      // Clear all current customers from active dashboard
      for (final customer in customers) {
        await customerRepo.deleteCustomer(customer.id);
      }

      debugPrint('Monthly reset completed: ${customers.length} customers archived to ${lastResetDate.year}-${lastResetDate.month}');
    } catch (e) {
      debugPrint('Error during monthly reset: $e');
      rethrow;
    }
  }

  /// Manually trigger reset (for testing or manual operations)
  Future<void> forceReset() async {
    final storage = _ref.read(storageServiceProvider);
    final lastResetDate = storage.lastResetDate ?? DateTime.now();
    await _performMonthlyReset(lastResetDate);
    await storage.setLastResetDate(DateTime.now());
  }
}
