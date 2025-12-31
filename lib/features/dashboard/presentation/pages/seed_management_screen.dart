import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sr_ghani/services/storage_service.dart';
import 'package:sr_ghani/services/settings_repository.dart';

class SeedManagementScreen extends ConsumerStatefulWidget {
  const SeedManagementScreen({super.key});

  @override
  ConsumerState<SeedManagementScreen> createState() => _SeedManagementScreenState();
}

class _SeedManagementScreenState extends ConsumerState<SeedManagementScreen> {
  late List<String> _seeds;
  late Map<String, double> _charges;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(storageServiceProvider);
    _seeds = List.from(storage.seedTypes);
    _charges = Map.from(storage.khaliCharges);
  }

  void _save() {
    final storage = ref.read(storageServiceProvider);
    storage.setSeedTypes(_seeds);
    storage.setKhaliCharges(_charges);
    ref.read(settingsRepositoryProvider).syncSettingsToCloud();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seed configuration saved to cloud')),
    );
  }

  void _addNewSeed() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add New Seed'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'e.g. Mustard, Cotton Seed'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty && !_seeds.contains(name)) {
                  setState(() {
                    _seeds.add(name);
                    _charges[name] = 5.0; // Default charge
                  });
                  _save();
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Seed Management'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewSeed,
        icon: const Icon(Icons.add),
        label: const Text('Add Seed'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _seeds.length,
        itemBuilder: (context, index) {
          final seed = _seeds[index];
          final charge = _charges[seed] ?? 5.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.grain, color: Colors.blue, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        seed,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          _seeds.removeAt(index);
                          _charges.remove(seed);
                        });
                        _save();
                      },
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Extraction Price if Khali remains with us (Rs/kg seed)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '0.35',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          final r = double.tryParse(val);
                          if (r != null) {
                            _charges[seed] = r;
                            _save();
                          }
                        },
                        controller: TextEditingController(text: charge.toString()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Rs/kg', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
