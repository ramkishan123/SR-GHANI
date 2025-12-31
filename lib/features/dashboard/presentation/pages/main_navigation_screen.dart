import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sr_ghani/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:sr_ghani/features/dashboard/presentation/pages/analytics_screen.dart';
import 'package:sr_ghani/features/dashboard/presentation/pages/settings_screen.dart';
import 'package:sr_ghani/features/dashboard/presentation/widgets/floating_dock.dart';
import 'package:sr_ghani/services/sync_service.dart';
import 'package:sr_ghani/features/dashboard/presentation/pages/add_customer_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize realtime sync listeners and timers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).initializeSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      extendBody: true,
      body: Row(
        children: [
          if (isWideScreen)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              indicatorColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              selectedIconTheme: IconThemeData(color: Theme.of(context).primaryColor),
              selectedLabelTextStyle: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.auto_graph_rounded),
                  label: Text('Analytics'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tune_rounded),
                  label: Text('Settings'),
                ),
              ],
            ),
          if (isWideScreen) const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 
        ? Padding(
            padding: EdgeInsets.only(bottom: isWideScreen ? 20 : 80), 
            child: FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
              ),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 8,
              label: const Text('New Order', style: TextStyle(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.add_rounded),
            ),
          )
        : null,
      floatingActionButtonLocation: isWideScreen 
          ? FloatingActionButtonLocation.endFloat 
          : FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: isWideScreen 
          ? null 
          : FloatingDock(
              currentIndex: _currentIndex,
              onIndexChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
    );
  }
}
