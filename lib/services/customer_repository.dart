import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sr_ghani/models/customer_model.dart';
import 'package:sr_ghani/services/auth_service.dart';
import 'package:sr_ghani/services/search_translator.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.uid;
  return CustomerRepository(userId);
});

class CustomerRepository {
  final String? _userId;
  final String _boxName = 'customers';

  CustomerRepository(this._userId);

  Box<Customer> get _box => Hive.box<Customer>(_boxName);

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference get _userCollection =>
      _firestore.collection('users').doc(_userId).collection('customers');

  Future<void> addCustomer(Customer customer) async {
    // Save to Hive first
    await _box.put(customer.id, customer);
    
    // Sync to Firestore if user ID exists
    if (_userId != null) {
      await _userCollection.doc(customer.id).set(customer.toMap());
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    await _box.put(customer.id, customer);
    if (_userId != null) {
      await _userCollection.doc(customer.id).update(customer.toMap());
    }
  }

  Future<void> deleteCustomer(String id) async {
    await _box.delete(id);
    if (_userId != null) {
      await _userCollection.doc(id).delete();
    }
  }

  List<Customer> getAllCustomers([String query = '']) {
    final all = _box.values.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    
    if (query.isEmpty) return all;

    return all.where((c) => 
      SearchTranslator.isMatch(query, c.name) || 
      (c.mobileNumber != null && SearchTranslator.isMatch(query, c.mobileNumber!))
    ).toList();
  }

  Stream<List<Customer>> watchCustomers([String query = '']) {
    return _box.watch().map((_) => getAllCustomers(query));
  }

  // Firestore persistence is handled automatically by the SDK on mobile.
  // Initial sync is managed by SyncService during the login flow.
}
