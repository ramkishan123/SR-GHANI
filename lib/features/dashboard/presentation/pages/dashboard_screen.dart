import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sr_ghani/services/customer_repository.dart';
import 'package:sr_ghani/services/search_translator.dart';
import 'package:sr_ghani/features/dashboard/presentation/widgets/customer_card.dart';
import 'package:sr_ghani/features/dashboard/presentation/pages/customer_detail_screen.dart';
import 'package:sr_ghani/features/dashboard/presentation/widgets/search_filter_bar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _searchQuery = '';
  String? _filterStatus;
  DateTimeRange? _filterDateRange;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(customerRepositoryProvider);
    
    final bool isWideScreen = MediaQuery.of(context).size.width > 900;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWideScreen ? 1200 : 900),
          child: CustomScrollView(
            slivers: [
              _buildAppBar(context, ref),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildSummaryCards(),
                      const SizedBox(height: 32),
                      _buildSearchAndFilters(),
                    ],
                  ),
                ),
              ),
              _buildCustomerList(repository),
              const SliverToBoxAdapter(child: SizedBox(height: 120)), // Increased padding for FloatingDock
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'SR Ghani',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -1),
      ),
      actions: const [
        SizedBox(width: 12),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Business Tracker',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final repository = ref.read(customerRepositoryProvider);
    final all = repository.getAllCustomers();
    final pending = all.where((c) => c.status == 'pending').length;
    final processed = all.where((c) => c.status == 'completed_by_us').length;

    return Row(
      children: [
        _buildStatCard('Orders', all.length.toString(), Colors.deepOrange),
        const SizedBox(width: 12),
        _buildStatCard('Pending', pending.toString(), Colors.orange),
        const SizedBox(width: 12),
        _buildStatCard('Processed', processed.toString(), Colors.blue),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        SearchFilterBar(
          onSearch: (val) => setState(() => _searchQuery = val),
          onFilterDate: (range) => setState(() => _filterDateRange = range),
          onFilterStatus: (status) => setState(() => _filterStatus = status),
          currentStatus: _filterStatus,
        ),
      ],
    );
  }

  Widget _buildCustomerList(CustomerRepository repository) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 900;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: StreamBuilder(
        stream: repository.watchCustomers(),
        initialData: repository.getAllCustomers(),
        builder: (context, snapshot) {
          var customers = snapshot.data ?? [];
          
          if (_searchQuery.isNotEmpty) {
            customers = customers.where((c) => 
              SearchTranslator.isMatch(_searchQuery, c.name) || 
              (c.mobileNumber != null && SearchTranslator.isMatch(_searchQuery, c.mobileNumber!))
            ).toList();
          }

          if (_filterStatus != null) {
            customers = customers.where((c) => c.status == _filterStatus).toList();
          }

          if (_filterDateRange != null) {
            customers = customers.where((c) => 
              c.dateTime.isAfter(_filterDateRange!.start) &&
              c.dateTime.isBefore(_filterDateRange!.end.add(const Duration(days: 1)))
            ).toList();
          }
          
          if (customers.isEmpty) {
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 80, color: Color(0xFFE0E0E0)),
                    SizedBox(height: 16),
                    Text('No orders found', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }

          if (isWideScreen) {
            return SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final customer = customers[index];
                  return CustomerCard(
                    customer: customer,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => CustomerDetailScreen(customer: customer)),
                    ),
                    onDelete: () => repository.deleteCustomer(customer.id),
                  );
                },
                childCount: customers.length,
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final customer = customers[index];
                return CustomerCard(
                  customer: customer,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => CustomerDetailScreen(customer: customer)),
                  ),
                  onDelete: () => repository.deleteCustomer(customer.id),
                );
              },
              childCount: customers.length,
              addAutomaticKeepAlives: true,
            ),
          );
        },
      ),
    );
  }
}
