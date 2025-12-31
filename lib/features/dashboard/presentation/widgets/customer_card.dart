import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sr_ghani/models/customer_model.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildStatusIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                         children: [
                           Expanded(
                             child: Text(
                              customer.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                             ),
                           ),
                           if (customer.checkAdvancePaid)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.payments_rounded, color: Colors.purple, size: 12),
                              ),
                         ],
                       ),
                      const SizedBox(height: 4),
                      Text(
                        customer.status == 'fully_completed' && customer.extraCharge != null
                            ? 'Paid: ₹${customer.extraCharge!.toStringAsFixed(0)} (${customer.paymentMethod})'
                            : customer.mobileNumber ?? 'No mobile',
                        style: TextStyle(
                          color: customer.status == 'fully_completed' ? Colors.green[700] : Colors.grey[600],
                          fontSize: 14,
                          fontWeight: customer.status == 'fully_completed' ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusBadge(),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd MMM').format(customer.dateTime),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final color = _getStatusColor();
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getStatusIcon(),
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusLabel().toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (customer.status) {
      case 'pending': return Colors.orange;
      case 'completed_by_us': return Colors.blue;
      case 'fully_completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (customer.status) {
      case 'pending': return Icons.timer_outlined;
      case 'completed_by_us': return Icons.engineering_outlined;
      case 'fully_completed': return Icons.check_circle_outline;
      default: return Icons.help_outline;
    }
  }

  String _getStatusLabel() {
    switch (customer.status) {
      case 'pending': return 'Pending';
      case 'completed_by_us': return 'Processed';
      case 'fully_completed': return 'Finished';
      default: return 'Unknown';
    }
  }
}
