import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sr_ghani/services/storage_service.dart';
import 'package:sr_ghani/services/settings_repository.dart';
import 'package:sr_ghani/features/dashboard/presentation/pages/seed_management_screen.dart';

class BusinessConfigScreen extends ConsumerStatefulWidget {
  const BusinessConfigScreen({super.key});

  @override
  ConsumerState<BusinessConfigScreen> createState() => _BusinessConfigScreenState();
}

class _BusinessConfigScreenState extends ConsumerState<BusinessConfigScreen> {
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(storageServiceProvider);
    _priceController = TextEditingController(text: storage.standardPrice.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Business Configuration'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildCard(
            title: 'Extraction Pricing',
            children: [
              const Text(
                'Set the standard rate charged per KG of seed extraction.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Standard Price (₹/kg)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (val) {
                  final price = double.tryParse(val);
                  if (price != null) {
                    ref.read(storageServiceProvider).setStandardPrice(price);
                    ref.read(settingsRepositoryProvider).syncSettingsToCloud();
                    if (price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Warning: Standard price is set to ₹0. Estimates will be zero.'),
                          backgroundColor: Colors.orange,
                        )
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCard(
            title: 'Seed & Khali Management',
            children: [
              const Text(
                'Add or remove seed types and customize their individual Khali (residue) weight ratios.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SeedManagementScreen()),
                  );
                },
                icon: const Icon(Icons.grain_outlined),
                label: const Text('Manage Seeds & Ratios'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
