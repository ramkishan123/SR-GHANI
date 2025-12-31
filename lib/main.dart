import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:sr_ghani/services/auth_service.dart';
import 'package:sr_ghani/services/storage_service.dart';
import 'package:sr_ghani/core/app_theme.dart';
import 'package:sr_ghani/features/auth/presentation/pages/login_screen.dart';
import 'package:sr_ghani/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:sr_ghani/features/auth/presentation/pages/sync_loading_screen.dart';
import 'package:sr_ghani/features/dashboard/presentation/pages/main_navigation_screen.dart'; // Moved import
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sr_ghani/models/customer_model.dart';
import 'package:sr_ghani/models/history_model.dart';
import 'package:sr_ghani/services/monthly_reset_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start initializing non-critical services in background
  // but don't block main yet. We'll handle it in GlobalInitializer.
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SR Ghani Management',
      theme: AppTheme.lightTheme,
      home: const GlobalInitializer(),
    );
  }
}

class GlobalInitializer extends ConsumerStatefulWidget {
  const GlobalInitializer({super.key});

  @override
  ConsumerState<GlobalInitializer> createState() => _GlobalInitializerState();
}

class _GlobalInitializerState extends ConsumerState<GlobalInitializer> {
  bool _initialized = false;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    try {
      setState(() => _status = 'Starting SR Ghani...');
      
      // Parallelize heavy initializations
      await Future.wait([
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
        _initHive(),
        SharedPreferences.getInstance().then((prefs) {
          ref.read(storageServiceProvider).setPrefs(prefs);
        }),
      ]);

      setState(() => _initialized = true);
    } catch (e) {
      debugPrint('Init Error: $e');
      setState(() => _status = 'Initialization failed. Please restart.');
    }
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    // Register adapters only if not already registered (safety for hot restart)
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CustomerAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SeedEntryAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(MonthlyHistoryAdapter());
    
    await Future.wait([
      Hive.openBox<Customer>('customers'),
      Hive.openBox<MonthlyHistory>('monthly_history'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return const InitialAuthWrapper();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'logo',
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.business_center_rounded, size: 60, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 24),
            Text(
              _status,
              style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class InitialAuthWrapper extends ConsumerWidget {
  const InitialAuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          final isSynced = ref.watch(syncStatusProvider);
          if (isSynced) {
            // Check and perform monthly reset if needed
            ref.read(monthlyResetServiceProvider).checkAndPerformReset();
            return const MainNavigationScreen();
          } else {
            return const SyncLoadingScreen();
          }
        } else {
          final isOnboarded = ref.watch(onboardingStatusProvider);
          if (isOnboarded) {
            return const LoginScreen();
          } else {
            return const OnboardingScreen();
          }
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(authStateProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
