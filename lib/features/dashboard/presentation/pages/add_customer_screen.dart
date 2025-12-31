import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sr_ghani/models/customer_model.dart';
import 'package:sr_ghani/services/customer_repository.dart';
import 'package:sr_ghani/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  final Customer? customerToEdit;

  const AddCustomerScreen({super.key, this.customerToEdit});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final List<SeedEntry> _seeds = [];


  @override
  void initState() {
    super.initState();
    if (widget.customerToEdit != null) {
      final c = widget.customerToEdit!;
      _nameController.text = c.name;
      _mobileController.text = c.mobileNumber?.replaceFirst('+91 ', '') ?? '';
      _addressController.text = c.address ?? '';
      _notesController.text = c.notes ?? '';
      _selectedDate = c.dateTime;
      _seeds.addAll(c.seeds);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          widget.customerToEdit == null ? 'Create New Order' : 'Edit Order Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            _buildSectionHeader('Customer Details'),
            const SizedBox(height: 16),
            _buildInputCard([
              _buildTextField(
                controller: _nameController,
                hint: 'Full Name',
                icon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
              ),
              const Divider(height: 1, indent: 50),
              _buildTextField(
                controller: _mobileController,
                hint: 'Mobile Number',
                icon: Icons.phone_outlined,
                prefixText: '+91 ',
                keyboardType: TextInputType.phone,
              ),
              const Divider(height: 1, indent: 50),
              _buildTextField(
                controller: _addressController,
                hint: 'Address (Optional)',
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),
              const Divider(height: 1, indent: 50),
              _buildTextField(
                controller: _notesController,
                hint: 'Notes (Optional)',
                icon: Icons.note_alt_outlined,
                maxLines: 3,
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('Order Timing'),
            const SizedBox(height: 16),
            _buildDateCard(),
            const SizedBox(height: 32),
            _buildSectionHeader('Seed Content'),
            const SizedBox(height: 16),
            ..._seeds.asMap().entries.map((entry) => _buildSeedEntryCard(entry.key, entry.value)),
            const SizedBox(height: 24),
            _buildAddSeedButton(),
            const SizedBox(height: 48),
            _buildSaveButton(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInputCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? prefixText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.normal),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          ),
          prefixText: prefixText,
          prefixStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectDateTime,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.calendar_today_rounded, color: Theme.of(context).primaryColor, size: 20),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM dd').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      DateFormat('hh:mm a').format(_selectedDate),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeedEntryCard(int index, SeedEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.grain_rounded, color: Theme.of(context).primaryColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seed Type',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: () => _showSeedPicker(index, entry),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              entry.seedType,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                ),
                onPressed: () => setState(() => _seeds.removeAt(index)),
              ),
            ],
          ),
          const Divider(height: 32),
          Text(
            'Quantity / Weight',
            style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextFormField(
              initialValue: entry.quantity > 0 ? entry.quantity.toString() : '',
              decoration: const InputDecoration(
                suffixText: 'KG',
                suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                border: InputBorder.none,
                hintText: 'Enter weight',
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) {
                final q = double.tryParse(val) ?? 0;
                setState(() => _seeds[index] = entry.copyWith(quantity: q));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSeedPicker(int index, SeedEntry entry) {
    final storage = ref.read(storageServiceProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Seed Type',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: storage.seedTypes.map((type) {
                final isSelected = entry.seedType == type;
                return InkWell(
                  onTap: () {
                    setState(() => _seeds[index] = entry.copyWith(seedType: type));
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200]!,
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSeedButton() {
    return OutlinedButton.icon(
      onPressed: _addSeedEntry,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Another Seed Type'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildSaveButton() {
    final isEdit = widget.customerToEdit != null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveCustomer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 68),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
        child: Text(
          isEdit ? 'Update Details' : 'Create Order & Receipt',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
    );
  }

  void _addSeedEntry() {
    setState(() => _seeds.add(SeedEntry.create(seedType: ref.read(storageServiceProvider).seedTypes.first, quantity: 0)));
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null) {
        setState(() => _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
      }
    }
  }

  void _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      if (_seeds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one seed type')));
        return;
      }
      if (_seeds.any((s) => s.quantity <= 0)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All seeds must have a weight greater than 0')));
        return;
      }
      final repo = ref.read(customerRepositoryProvider);
      final mobile = _mobileController.text.isNotEmpty ? '+91 ${_mobileController.text.trim()}' : null;

      if (widget.customerToEdit != null) {
        final updated = widget.customerToEdit!.copyWith(
          name: _nameController.text.trim(),
          mobileNumber: mobile,
          address: _addressController.text.trim(),
          notes: _notesController.text.trim(),
          dateTime: _selectedDate,
          seeds: _seeds,
        );
        await repo.updateCustomer(updated);
        if (mounted) Navigator.of(context).pop(updated);
      } else {
        final newCustomer = Customer(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          mobileNumber: mobile,
          address: _addressController.text.trim(),
          notes: _notesController.text.trim(),
          dateTime: _selectedDate,
          seeds: _seeds,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repo.addCustomer(newCustomer);
        if (mounted) Navigator.of(context).pop(newCustomer);
      }
    }
  }
}
