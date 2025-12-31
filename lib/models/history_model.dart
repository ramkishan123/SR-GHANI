import 'package:hive/hive.dart';
import 'package:sr_ghani/models/customer_model.dart';
// Model for monthly history storage

part 'history_model.g.dart';

@HiveType(typeId: 2)
class MonthlyHistory {
  @HiveField(0)
  final String id; // Format: "2025-01" for January 2025

  @HiveField(1)
  final int year;

  @HiveField(2)
  final int month;

  @HiveField(3)
  final List<Customer> customers;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  MonthlyHistory({
    required this.id,
    required this.year,
    required this.month,
    required this.customers,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MonthlyHistory.create({
    required int year,
    required int month,
    List<Customer>? customers,
  }) {
    final now = DateTime.now();
    final id = '$year-${month.toString().padLeft(2, '0')}';
    return MonthlyHistory(
      id: id,
      year: year,
      month: month,
      customers: customers ?? [],
      createdAt: now,
      updatedAt: now,
    );
  }

  MonthlyHistory copyWith({
    List<Customer>? customers,
  }) {
    return MonthlyHistory(
      id: id,
      year: year,
      month: month,
      customers: customers ?? this.customers,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'month': month,
      'customers': customers.map((x) => x.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MonthlyHistory.fromMap(Map<String, dynamic> map) {
    return MonthlyHistory(
      id: map['id'],
      year: map['year'],
      month: map['month'],
      customers: (map['customers'] as List)
          .map((x) => Customer.fromMap(x as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Utility getters
  String get displayName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[month - 1]} $year';
  }

  int get customerCount => customers.length;

  double get totalQuantity {
    return customers.fold(0.0, (sum, customer) => sum + customer.totalQuantity);
  }

  int get pendingCount {
    return customers.where((c) => c.status == 'pending').length;
  }

  int get completedCount {
    return customers.where((c) => c.status != 'pending').length;
  }
}
