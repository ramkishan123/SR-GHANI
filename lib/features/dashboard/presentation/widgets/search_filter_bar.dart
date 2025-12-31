import 'package:flutter/material.dart';

class SearchFilterBar extends StatelessWidget {
  final Function(String) onSearch;
  final Function(DateTimeRange?) onFilterDate;
  final Function(String?) onFilterStatus;
  final String? currentStatus;

  const SearchFilterBar({
    super.key,
    required this.onSearch,
    required this.onFilterDate,
    required this.onFilterStatus,
    this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Search by name or mobile...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
              prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).primaryColor),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildFilterButton(
              context,
              icon: Icons.filter_list_rounded,
              label: _getStatusLabel(),
              isActive: currentStatus != null,
              onTap: () => _showStatusPicker(context),
            ),
            const SizedBox(width: 12),
            _buildFilterButton(
              context,
              icon: Icons.calendar_today_rounded,
              label: 'Date Range',
              isActive: false, // State handling can be improved
              onTap: () => _showDatePicker(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? Theme.of(context).primaryColor : Colors.white;
    final textColor = isActive ? Colors.white : Colors.grey[700];

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? Colors.transparent : Colors.grey[200]!,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel() {
    if (currentStatus == null) return 'All Status';
    switch (currentStatus) {
      case 'pending': return 'Pending';
      case 'completed_by_us': return 'Processed';
      case 'fully_completed': return 'Finished';
      default: return 'Status';
    }
  }

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by Status',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildStatusItem(context, null, 'Display All Orders', Icons.all_inclusive_rounded, Colors.grey),
              _buildStatusItem(context, 'pending', 'Pending Extraction', Icons.timer_outlined, Colors.orange),
              _buildStatusItem(context, 'completed_by_us', 'Ready for Collection', Icons.engineering_outlined, Colors.blue),
              _buildStatusItem(context, 'fully_completed', 'Order Finished', Icons.check_circle_outline, Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(BuildContext context, String? value, String label, IconData icon, Color color) {
    final isSelected = currentStatus == value;
    return ListTile(
      onTap: () {
        onFilterStatus(value);
        Navigator.pop(context);
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? color : Colors.black87,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: color) : null,
    );
  }

  void _showDatePicker(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    onFilterDate(range);
  }
}
