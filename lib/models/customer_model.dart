import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'customer_model.g.dart';

@HiveType(typeId: 0)
class Customer {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? mobileNumber;
  @HiveField(3)
  final String? address;
  @HiveField(4)
  final DateTime dateTime;
  @HiveField(5)
  final String status; // pending, completed_by_us, fully_completed
  @HiveField(6)
  final String? paymentMethod; // upi, cash, khali
  @HiveField(7)
  final List<SeedEntry> seeds;
  @HiveField(8)
  final DateTime createdAt;
  @HiveField(9)
  final DateTime updatedAt;
  @HiveField(10)
  final double? extraCharge;
  @HiveField(11)
  final String? notes;
  @HiveField(12)
  final bool? isAdvancePaid;
  @HiveField(13)
  final String? advancePaymentMethod;

  Customer({
    required this.id,
    required this.name,
    this.mobileNumber,
    this.address,
    required this.dateTime,
    this.status = 'pending',
    this.paymentMethod,
    required this.seeds,
    required this.createdAt,
    required this.updatedAt,
    this.extraCharge,
    this.notes,
    this.isAdvancePaid = false,
    this.advancePaymentMethod,
  });

  factory Customer.create({
    required String name,
    String? mobileNumber,
    String? address,
    DateTime? dateTime,
    List<SeedEntry>? seeds,
  }) {
    final now = DateTime.now();
    return Customer(
      id: const Uuid().v4(),
      name: name,
      mobileNumber: mobileNumber,
      address: address,
      dateTime: dateTime ?? now,
      seeds: seeds ?? [],
      createdAt: now,
      updatedAt: now,
    );
  }

  Customer copyWith({
    String? name,
    String? mobileNumber,
    String? address,
    DateTime? dateTime,
    String? status,
    String? paymentMethod,
    List<SeedEntry>? seeds,
    double? extraCharge,
    String? notes,
    bool? isAdvancePaid,
    String? advancePaymentMethod,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      address: address ?? this.address,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      seeds: seeds ?? this.seeds,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      extraCharge: extraCharge ?? this.extraCharge,
      notes: notes ?? this.notes,
      isAdvancePaid: isAdvancePaid ?? this.isAdvancePaid,
      advancePaymentMethod: advancePaymentMethod ?? this.advancePaymentMethod,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobileNumber': mobileNumber,
      'address': address,
      'dateTime': dateTime.toIso8601String(),
      'status': status,
      'paymentMethod': paymentMethod,
      'seeds': seeds.map((x) => x.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'extraCharge': extraCharge,
      'notes': notes,
      'isAdvancePaid': isAdvancePaid,
      'advancePaymentMethod': advancePaymentMethod,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      mobileNumber: map['mobileNumber'],
      address: map['address'],
      dateTime: DateTime.parse(map['dateTime']),
      status: map['status'] ?? 'pending',
      paymentMethod: map['paymentMethod'],
      seeds: (map['seeds'] as List).map((x) => SeedEntry.fromMap(x)).toList(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      extraCharge: (map['extraCharge'] as num?)?.toDouble(),
      notes: map['notes'],
      isAdvancePaid: map['isAdvancePaid'] as bool?,
      advancePaymentMethod: map['advancePaymentMethod'],
    );
  }

  double get totalQuantity => seeds.fold(0.0, (prev, s) => prev + s.quantity);

  double calculateEstimatedKhaliWeight(Map<String, double> ratios) {
    return seeds.fold(0.0, (prev, s) {
      final ratio = ratios[s.seedType] ?? 0.35;
      return prev + (s.quantity * ratio);
    });
  }

  bool get checkAdvancePaid => isAdvancePaid ?? false;
  bool get isFullyCompleted => seeds.every((s) => s.status == 'completed');
  bool get hasAnyCompleted => seeds.any((s) => s.status == 'completed');
}

@HiveType(typeId: 1)
class SeedEntry {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String seedType;
  @HiveField(2)
  final double quantity; // in kg
  @HiveField(3)
  final String status; // pending, completed
  @HiveField(4)
  final DateTime createdAt;

  SeedEntry({
    required this.id,
    required this.seedType,
    required this.quantity,
    this.status = 'pending',
    required this.createdAt,
  });

  factory SeedEntry.create({
    required String seedType,
    required double quantity,
  }) {
    return SeedEntry(
      id: const Uuid().v4(),
      seedType: seedType,
      quantity: quantity,
      createdAt: DateTime.now(),
    );
  }

  SeedEntry copyWith({
    String? seedType,
    double? quantity,
    String? status,
  }) {
    return SeedEntry(
      id: id,
      seedType: seedType ?? this.seedType,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seedType': seedType,
      'quantity': quantity,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SeedEntry.fromMap(Map<String, dynamic> map) {
    return SeedEntry(
      id: map['id'],
      seedType: map['seedType'],
      quantity: (map['quantity'] as num).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
