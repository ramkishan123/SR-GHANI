import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sr_ghani/models/customer_model.dart';
import 'package:sr_ghani/models/history_model.dart';
import 'package:sr_ghani/services/history_repository.dart';
import 'package:sr_ghani/services/search_translator.dart';
import 'package:sr_ghani/features/dashboard/presentation/pages/customer_detail_screen.dart';
import 'package:sr_ghani/services/export_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';
  String? _filterStatus;
  final Set<String> _expandedMonths = {};

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(historyRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'History',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -1),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              _buildSearchAndFilters(),
              Expanded(
                child: StreamBuilder<List<MonthlyHistory>>(
                  stream: repository.watchHistory(),
                  initialData: repository.getAllHistory(),
                  builder: (context, snapshot) {
                    var histories = snapshot.data ?? [];

                    // Filter logic
                    histories = histories.map((h) {
                      var filteredCustomers = h.customers;

                      if (_searchQuery.isNotEmpty) {
                        filteredCustomers = filteredCustomers.where((c) =>
                          SearchTranslator.isMatch(_searchQuery, c.name) ||
                          (c.mobileNumber != null && SearchTranslator.isMatch(_searchQuery, c.mobileNumber!))
                        ).toList();
                      }

                      if (_filterStatus != null) {
                        filteredCustomers = filteredCustomers.where((c) => c.status == _filterStatus).toList();
                      }

                      return filteredCustomers.isEmpty ? null : h.copyWith(customers: filteredCustomers);
                    }).whereType<MonthlyHistory>().toList();

                    if (histories.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'No history yet' : 'No results found',
                              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: histories.length,
                      itemBuilder: (context, index) {
                        final history = histories[index];
                        final isExpanded = _expandedMonths.contains(history.id);
                        return _buildMonthCard(history, isExpanded);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search history...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF8F9FD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(null, 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Pending'),
                const SizedBox(width: 8),
                _buildFilterChip('completed_by_us', 'Processed'),
                const SizedBox(width: 8),
                _buildFilterChip('fully_completed', 'Completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? status, String label) {
    final isSelected = _filterStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = selected ? status : null);
      },
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      backgroundColor: const Color(0xFFF8F9FD),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildMonthCard(MonthlyHistory history, bool isExpanded) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedMonths.remove(history.id);
                } else {
                  _expandedMonths.add(history.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: Colors.blue, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              history.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${history.customerCount} customers • ${history.totalQuantity.toStringAsFixed(1)} kg',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatChip('Pending', history.pendingCount.toString(), Colors.orange),
                      const SizedBox(width: 8),
                      _buildStatChip('Completed', history.completedCount.toString(), Colors.green),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.blueGrey, size: 20),
                        onPressed: () => ExportService.exportToPdf(history.customers),
                        tooltip: 'Export PDF',
                      ),
                      IconButton(
                        icon: const Icon(Icons.table_view_outlined, color: Colors.blueGrey, size: 20),
                        onPressed: () => ExportService.exportToExcel(history.customers),
                        tooltip: 'Export Excel',
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: () => _confirmDeleteMonth(history),
                        tooltip: 'Delete month',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildCustomerList(history),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(MonthlyHistory history) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: history.customers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final customer = history.customers[index];
          return _buildCustomerCard(customer, history.id);
        },
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer, String monthId) {
    final statusColor = customer.status == 'pending'
        ? Colors.orange
        : customer.status == 'completed_by_us'
            ? Colors.blue
            : Colors.green;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CustomerDetailScreen(customer: customer),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${customer.totalQuantity.toStringAsFixed(1)} kg • ${DateFormat('MMM d, y').format(customer.dateTime)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_rounded, color: Colors.grey[600]),
                onPressed: () => _showEditDialog(customer, monthId),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: () => _confirmDeleteCustomer(customer, monthId),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(Customer customer, String monthId) {
    final nameController = TextEditingController(text: customer.name);
    final mobileController = TextEditingController(text: customer.mobileNumber);
    final addressController = TextEditingController(text: customer.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Customer', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedCustomer = customer.copyWith(
                name: nameController.text,
                mobileNumber: mobileController.text.isEmpty ? null : mobileController.text,
                address: addressController.text.isEmpty ? null : addressController.text,
              );
              ref.read(historyRepositoryProvider).updateCustomerInHistory(monthId, updatedCustomer);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Customer updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCustomer(Customer customer, String monthId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete ${customer.name} from history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(historyRepositoryProvider).deleteCustomerFromHistory(monthId, customer.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Customer deleted from history')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMonth(MonthlyHistory history) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Month', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete all data for ${history.displayName}?\n\n'
          'This will permanently delete ${history.customerCount} customers and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(historyRepositoryProvider).deleteMonthHistory(history.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Month deleted from history')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
