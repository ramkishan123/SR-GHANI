import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sr_ghani/models/customer_model.dart';
import 'package:sr_ghani/services/customer_repository.dart';
import 'package:sr_ghani/services/storage_service.dart';
import 'package:sr_ghani/features/dashboard/presentation/pages/add_customer_screen.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  late Customer _currentCustomer;

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusOverview(),
                  const SizedBox(height: 24),
                  _buildCustomerInfoCard(),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Seed Items',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                      Text(
                        'Tap to toggle status',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._currentCustomer.seeds.map((seed) => _buildSeedItem(seed)),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _currentCustomer.name,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
        ),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withValues(alpha: 0.08),
                const Color(0xFFF8F9FD),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Icon(Icons.person_rounded, size: 48, color: Theme.of(context).primaryColor),
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_note_rounded),
          onPressed: () async {
            final updated = await Navigator.of(context).push<Customer>(
              MaterialPageRoute(
                builder: (context) => AddCustomerScreen(customerToEdit: _currentCustomer),
              ),
            );
            if (updated != null) {
              setState(() => _currentCustomer = updated);
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          onPressed: _showDeleteConfirmation,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatusOverview() {
    final isDone = _currentCustomer.status == 'fully_completed';
    final isProcessed = _currentCustomer.status == 'completed_by_us';
    
    return Row(
      children: [
        _buildStatusChip(
          label: isDone ? 'FULLY COMPLETED' : (isProcessed ? 'PROCESSED' : 'PENDING'),
          color: isDone ? Colors.green : (isProcessed ? Colors.blue : Colors.orange),
          icon: isDone ? Icons.check_circle_rounded : (isProcessed ? Icons.engineering_rounded : Icons.pending_actions_rounded),
        ),
        const SizedBox(width: 12),
        if (_currentCustomer.checkAdvancePaid)
          _buildStatusChip(
            label: 'ADVANCE PAID',
            color: Colors.purple,
            icon: Icons.payments_rounded,
          )
        else if (_currentCustomer.status == 'pending')
          _buildAddAdvanceChip(),
      ],
    );
  }

  Widget _buildAddAdvanceChip() {
    return InkWell(
      onTap: _showAdvancePaymentSheet,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 16, color: Colors.purple),
            SizedBox(width: 8),
            Text(
              'PAY ADVANCE',
              style: TextStyle(color: Colors.purple, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({required String label, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.phone_rounded, _currentCustomer.mobileNumber ?? 'No mobile provided', Colors.green),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          _buildInfoRow(Icons.location_on_rounded, _currentCustomer.address ?? 'No address provided', Colors.orange),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          _buildInfoRow(
            Icons.access_time_filled_rounded,
            DateFormat('dd MMM yyyy • hh:mm a').format(_currentCustomer.dateTime),
            Colors.blue,
          ),
          if (_currentCustomer.notes != null && _currentCustomer.notes!.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            _buildInfoRow(Icons.description_rounded, _currentCustomer.notes!, Colors.purple),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color.withValues(alpha: 0.6)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildSeedItem(SeedEntry seed) {
    final isDone = seed.status == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDone ? Colors.green.withValues(alpha: 0.3) : Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleSeedStatus(seed),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDone ? Colors.green : Colors.blue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(isDone ? Icons.check_rounded : Icons.grain_rounded, color: isDone ? Colors.green : Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seed.seedType,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Quantity: ${seed.quantity} kg',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(seed.status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isDone = status == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isDone ? Colors.green : Colors.orange,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_currentCustomer.status == 'pending') {
      return Column(
        children: [
          if (_currentCustomer.hasAnyCompleted) 
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Some items are completed. Continue processing?',
                style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ElevatedButton.icon(
            onPressed: _markAsProcessed,
            icon: const Icon(Icons.engineering_outlined),
            label: const Text('Mark Processed (by Us)'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      );
    } else if (_currentCustomer.status == 'completed_by_us') {
      return ElevatedButton.icon(
        onPressed: _showPaymentDialog,
        icon: const Icon(Icons.payments_outlined),
        label: const Text('Confirm Collection & Final Payment'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
          const SizedBox(height: 12),
          Text(
            'ORDER COMPLETED',
            style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
          ),
          Text(
            'Paid via ${_currentCustomer.paymentMethod?.toUpperCase()}',
            style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600),
          ),
          if (_currentCustomer.extraCharge != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(
                'Amount: ₹${_currentCustomer.extraCharge!.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.green),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleSeedStatus(SeedEntry seed) async {
    final updatedSeeds = _currentCustomer.seeds.map((s) {
      if (s.id == seed.id) {
        return s.copyWith(status: s.status == 'completed' ? 'pending' : 'completed');
      }
      return s;
    }).toList();
    
    final messenger = ScaffoldMessenger.of(context);
    
    final updated = _currentCustomer.copyWith(seeds: updatedSeeds);
    await ref.read(customerRepositoryProvider).updateCustomer(updated);
    if (!mounted) return;
    setState(() => _currentCustomer = updated);
    
    messenger.showSnackBar(
      SnackBar(
        content: Text('${seed.seedType} marked as ${seed.status == 'completed' ? 'Pending' : 'Completed'}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAdvancePaymentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Advance Payment', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text('Record payment received before collection.', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            _buildAdvancePayOption('upi', Icons.qr_code_scanner_rounded, 'UPI / Online'),
            const SizedBox(height: 12),
            _buildAdvancePayOption('cash', Icons.payments_rounded, 'Cash Payment'),
            const SizedBox(height: 12),
            _buildAdvancePayOption('khali', Icons.shopping_basket_rounded, 'Payment via Khali'),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancePayOption(String id, IconData icon, String label) {
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        _showAdvanceConfirmDialog(id);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: const Color(0xFFF8F9FD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.purple),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
    );
  }

  void _showAdvanceConfirmDialog(String method) {
    if (method == 'khali') {
      _showKhaliAdvanceDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Confirm ${method.toUpperCase()} Advance?'),
        content: Text('Are you sure you want to mark this order as "Advance Paid" via ${method.toUpperCase()}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markAdvancePayment(method);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showKhaliAdvanceDialog() {
    final storage = ref.read(storageServiceProvider);
    final totalWeight = _currentCustomer.totalQuantity;
    double defaultPrice = 0;
    
    final charges = storage.khaliCharges;
    for (var s in _currentCustomer.seeds) {
      final chargePerKg = charges[s.seedType] ?? 5.0;
      defaultPrice += s.quantity * chargePerKg;
    }
    
    final controller = TextEditingController(text: defaultPrice.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Khali Advance Payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Weight: ${totalWeight.toStringAsFixed(1)} kg', style: TextStyle(color: Colors.grey[600])),
              Text('Calc Price: ₹${defaultPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Extra Money if any (₹)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0;
              Navigator.pop(context);
              _markAdvancePayment('khali', extraCharge: val);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            child: const Text('Confirm Khali Advance'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAdvancePayment(String method, {double? extraCharge}) async {
    final updated = _currentCustomer.copyWith(
      isAdvancePaid: true, 
      advancePaymentMethod: method,
      extraCharge: extraCharge ?? _currentCustomer.extraCharge,
    );
    await ref.read(customerRepositoryProvider).updateCustomer(updated);
    if (!mounted) return;
    setState(() => _currentCustomer = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Advance payment via ${method.toUpperCase()} recorded.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.purple,
      ),
    );
  }

  Future<void> _markAsProcessed() async {
    final updated = _currentCustomer.copyWith(status: 'completed_by_us');
    await ref.read(customerRepositoryProvider).updateCustomer(updated);
    setState(() => _currentCustomer = updated);
  }

  void _showPaymentDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Collection & Payment', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text('Select how the remaining payment was made.', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            _buildPayOption('upi', Icons.qr_code_scanner_rounded, 'UPI / Online'),
            const SizedBox(height: 12),
            _buildPayOption('cash', Icons.payments_rounded, 'Cash Payment'),
            const SizedBox(height: 12),
            _buildPayOption('khali', Icons.shopping_basket_rounded, 'Payment via Khali'),
          ],
        ),
      ),
    );
  }

  Widget _buildPayOption(String id, IconData icon, String label) {
    final storage = ref.read(storageServiceProvider);
    final totalWeight = _currentCustomer.totalQuantity;
    String subtitle;
    if (id == 'khali') {
      final charges = storage.khaliCharges;
      double totalCharge = 0;
      List<String> breakdown = [];
      for (var s in _currentCustomer.seeds) {
        final chargePerKg = charges[s.seedType] ?? 5.0;
        final itemCharge = s.quantity * chargePerKg;
        totalCharge += itemCharge;
        if (s.quantity > 0) {
          breakdown.add('${s.quantity}kg x ₹$chargePerKg');
        }
      }
      subtitle = 'Est: ₹${totalCharge.toStringAsFixed(0)} ${breakdown.isNotEmpty ? "(${breakdown.join(' + ')})" : "(0 kg)"}';
    } else {
      final standardPrice = storage.standardPrice;
      subtitle = 'Est: ₹${(totalWeight * standardPrice).toStringAsFixed(0)} (${totalWeight.toStringAsFixed(1)}kg x ₹${standardPrice.toStringAsFixed(0)})';
    }

    return ListTile(
      onTap: () {
        Navigator.pop(context); // Close selection sheet
        _showPaymentCompletionDialog(id);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: const Color(0xFFF8F9FD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
    );
  }

  void _showPaymentCompletionDialog(String method) {
    final isKhali = method == 'khali';
    final storage = ref.read(storageServiceProvider);
    final totalWeight = _currentCustomer.totalQuantity;
    final standardPrice = storage.standardPrice;
    double defaultPrice = 0;
    
    if (isKhali) {
      final charges = storage.khaliCharges;
      for (var s in _currentCustomer.seeds) {
        final chargePerKg = charges[s.seedType] ?? 5.0;
        defaultPrice += s.quantity * chargePerKg;
      }
    } else {
      defaultPrice = totalWeight * standardPrice;
    }
    
    final controller = TextEditingController(text: defaultPrice.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(isKhali ? 'Khali Collection' : 'Payment Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentCustomer.checkAdvancePaid)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: Colors.purple),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Advance already paid. Enter remaining amount if any.', style: TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              Text('Total Weight: ${totalWeight.toStringAsFixed(1)} kg', style: TextStyle(color: Colors.grey[600])),
              Text('Calc Price: ₹${defaultPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: isKhali ? 'Extra Money (₹)' : 'Final Price (₹)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text) ?? 0;
              final updated = _currentCustomer.copyWith(
                status: 'fully_completed',
                paymentMethod: method,
                extraCharge: val,
              );
              final navigator = Navigator.of(context);
              await ref.read(customerRepositoryProvider).updateCustomer(updated);
              if (mounted) {
                setState(() => _currentCustomer = updated);
                navigator.pop();
              }
            },
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Complete Order'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Delete Customer?'),
        content: const Text('All order data and history for this customer will be removed permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await ref.read(customerRepositoryProvider).deleteCustomer(_currentCustomer.id);
              if (mounted) {
                navigator.pop(); // Dialog
                navigator.pop(); // Detail Screen
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
