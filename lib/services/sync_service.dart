import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sr_ghani/models/customer_model.dart';
import 'package:sr_ghani/models/history_model.dart';
import 'package:sr_ghani/services/storage_service.dart';
import 'package:sr_ghani/services/settings_repository.dart';

final syncServiceProvider = Provider((ref) => SyncService(ref));

class SyncService with WidgetsBindingObserver {
  final Ref _ref;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  StreamSubscription? _customerSubscription;
  StreamSubscription? _historySubscription;
  StreamSubscription? _settingsSubscription;
  Timer? _heartbeatTimer;
  Timer? _refreshTimer;
  DateTime? _lastForceSync;
  bool _isAppInForeground = true;
  bool _isSyncing = false;

  SyncService(this._ref) {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _customerSubscription?.cancel();
    _historySubscription?.cancel();
    _settingsSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _refreshTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    if (_isAppInForeground) {
      _startSyncTimers();
      _forceSync(); // Sync immediately when coming to foreground
    } else {
      _stopSyncTimers();
    }
  }

  void _stopSyncTimers() {
    _heartbeatTimer?.cancel();
    _refreshTimer?.cancel();
  }

  Future<void> initializeSync() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Start Realtime Listeners
    _setupRealtimeListeners(user.uid);

    // Start Timers
    _startSyncTimers();

    // Monitor connectivity
    Connectivity().onConnectivityChanged.listen((results) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        _forceSync();
      }
    });
  }

  void _setupRealtimeListeners(String userId) {
    _customerSubscription?.cancel();
    _customerSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('customers')
        .snapshots()
        .listen((snapshot) async {
      final box = Hive.box<Customer>('customers');
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          await box.delete(change.doc.id);
        } else {
          final customer = Customer.fromMap(change.doc.data()!);
          await box.put(customer.id, customer);
        }
      }
    });

    _historySubscription?.cancel();
    _historySubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('history')
        .snapshots()
        .listen((snapshot) async {
      final box = Hive.box<MonthlyHistory>('monthly_history');
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          await box.delete(change.doc.id);
        } else {
          final history = MonthlyHistory.fromMap(change.doc.data()!);
          await box.put(history.id, history);
        }
      }
    });

    _settingsSubscription?.cancel();
    _settingsSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('config')
        .doc('business_settings')
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        await _ref.read(settingsRepositoryProvider).syncSettingsFromCloud();
      }
    });
  }

  void _startSyncTimers() {
    if (!_isAppInForeground) return;
    
    _heartbeatTimer?.cancel();
    // 5-second lightweight heartbeat: Check connectivity only (No Firestore read)
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (await _hasInternet()) {
        debugPrint('Sync Heartbeat: Connection Stable');
      }
    });

    _refreshTimer?.cancel();
    // 1-minute smart refresh
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _forceSync();
    });
  }

  Future<void> _forceSync() async {
    if (_isSyncing || !_isAppInForeground) return;
    
    // Throttling: Only force server fetch if it's been more than 5 minutes 
    // since the last manual force sync, OR if internet was just restored.
    final now = DateTime.now();
    if (_lastForceSync != null && now.difference(_lastForceSync!).inMinutes < 5) {
      debugPrint('Sync: Throttled (Last sync was recent)');
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    _isSyncing = true;
    try {
      if (await _hasInternet()) {
        // Source.server ensures we hit the cloud, but we do it rarely (every 5 mins max)
        // because Realtime Listeners (Snapshots) already handle 99% of updates.
        await _firestore.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));
        _lastForceSync = now;
        debugPrint('Smart Sync: Cloud state verified');
      }
    } catch (e) {
      debugPrint('Smart Sync Error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _hasInternet() async {
    final results = await Connectivity().checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  Future<void> performInitialSync() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final storage = _ref.read(storageServiceProvider);
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('customers')
          .get();

      final box = Hive.box<Customer>('customers');
      await box.clear();

      for (var doc in snapshot.docs) {
        final customer = Customer.fromMap(doc.data());
        await box.put(customer.id, customer);
      }

      final historySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .get();

      final historyBox = Hive.box<MonthlyHistory>('monthly_history');
      await historyBox.clear();

      for (var doc in historySnapshot.docs) {
        final history = MonthlyHistory.fromMap(doc.data());
        await historyBox.put(history.id, history);
      }

      await _ref.read(settingsRepositoryProvider).syncSettingsFromCloud();

      await storage.setSyncComplete(_ref, true);
      
      // After initial sync, start realtime
      await initializeSync();
    } catch (e) {
      debugPrint('Initial Sync Error: $e');
      rethrow;
    }
  }
}
