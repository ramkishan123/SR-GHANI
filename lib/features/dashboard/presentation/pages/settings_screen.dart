import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sr_ghani/services/customer_repository.dart';
import 'package:sr_ghani/services/auth_service.dart';
import 'package:sr_ghani/models/customer_model.dart';
import 'package:sr_ghani/models/history_model.dart';
import 'package:sr_ghani/features/dashboard/presentation/pages/business_config_screen.dart';
import 'package:sr_ghani/features/dashboard/presentation/pages/history_screen.dart';
import 'package:sr_ghani/services/export_service.dart';
import 'package:sr_ghani/services/history_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWideScreen ? 1100 : 700),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              _buildSectionHeader('Marketing & Tools'),
              const SizedBox(height: 16),
              if (isWideScreen)
                Row(
                  children: [
                    Expanded(
                      child: _buildSettingsTile(
                        context,
                        icon: Icons.history_rounded,
                        title: 'Transaction History',
                        subtitle: 'View previous months data',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
                        color: Colors.purple,
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSettingsTile(
                        context,
                        icon: Icons.contact_phone_outlined,
                        title: 'Mobile Scraper',
                        subtitle: 'Extract customer numbers',
                        onTap: () => _scrapeNumbers(context, ref),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSettingsTile(
                        context,
                        icon: Icons.analytics_outlined,
                        title: 'Lifetime Report',
                        subtitle: 'All-time PDF/Excel report',
                        onTap: () => _showLifetimeExportOptions(context, ref),
                        color: Colors.indigo,
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    ),
                  ],
                )
              else ...[
                _buildSettingsTile(
                  context,
                  icon: Icons.history_rounded,
                  title: 'Transaction History',
                  subtitle: 'View and manage previous months data',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
                  color: Colors.purple,
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  context,
                  icon: Icons.analytics_outlined,
                  title: 'Lifetime Business Report',
                  subtitle: 'Full PDF & Excel of all records',
                  onTap: () => _showLifetimeExportOptions(context, ref),
                  color: Colors.indigo,
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  context,
                  icon: Icons.contact_phone_outlined,
                  title: 'Mobile Scraper',
                  subtitle: 'Extract customer numbers for marketing',
                  onTap: () => _scrapeNumbers(context, ref),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 12),
              _buildSettingsTile(
                context,
                icon: Icons.business_center_outlined,
                title: 'Business Configuration',
                subtitle: 'Set extraction rates and seed types',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BusinessConfigScreen()),
                  );
                },
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader('Account Safety'),
              const SizedBox(height: 16),
              if (isWideScreen)
                Row(
                  children: [
                    Expanded(
                      child: _buildSettingsTile(
                        context,
                        icon: Icons.logout_outlined,
                        title: 'Sign Out',
                        subtitle: 'Log out of current session',
                        onTap: () => ref.read(authServiceProvider).signOut(),
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSettingsTile(
                        context,
                        icon: Icons.delete_forever_outlined,
                        title: 'Factory Registration',
                        subtitle: 'Wipe all data permanently',
                        onTap: () => _showResetConfirmation(context, ref),
                        color: Colors.red,
                      ),
                    ),
                  ],
                )
              else ...[
                _buildSettingsTile(
                  context,
                  icon: Icons.logout_outlined,
                  title: 'Sign Out',
                  subtitle: 'Log out of your current session',
                  onTap: () => ref.read(authServiceProvider).signOut(),
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  context,
                  icon: Icons.delete_forever_outlined,
                  title: 'Factory registration',
                  subtitle: 'Wipe all local and cloud data permanently',
                  onTap: () => _showResetConfirmation(context, ref),
                  color: Colors.red,
                ),
              ],
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  'SR Ghani v1.0.0',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 120), // Padding for FloatingDock
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? color,
  }) {
    final themeColor = color ?? Theme.of(context).primaryColor;

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
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: themeColor),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          trailing: trailing,
        ),
      ),
    );
  }

  void _scrapeNumbers(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Processing Numbers...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    final customers = ref.read(customerRepositoryProvider).getAllCustomers();
    final history = ref.read(historyRepositoryProvider).getAllHistory();
    
    await ExportService.exportMobileNumbers(customers, history);
    
    if (context.mounted) Navigator.pop(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile numbers extracted successfully')),
      );
    }
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Factory Reset?'),
        content: const Text('This will delete all local data and cloud records. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Proceed', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm1 == true) {
      if (!context.mounted) return;

      final confirm2 = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('FINAL WARNING'),
          content: const Text('Are you absolutely sure? All business data, history, and settings will be permanently wiped.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Safety First')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('YES, WIPE EVERYTHING', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm2 == true) {
        final userId = ref.read(authStateProvider).value?.uid;
        if (userId != null) {
          final firestore = FirebaseFirestore.instance;
          final batch = firestore.batch();
          final docs = await firestore.collection('users').doc(userId).collection('customers').get();
          for (var doc in docs.docs) {
            batch.delete(doc.reference);
          }
          
          final historyDocs = await firestore.collection('users').doc(userId).collection('history').get();
          for (var doc in historyDocs.docs) {
            batch.delete(doc.reference);
          }
          
          await firestore.collection('users').doc(userId).collection('config').doc('business_settings').delete();
          await batch.commit();
        }

        await Hive.box<Customer>('customers').clear();
        await Hive.box<MonthlyHistory>('monthly_history').clear();
        await ref.read(authServiceProvider).signOut();
        if (context.mounted) {
          navigator.pop();
        }
      }
    }
  }

  void _showLifetimeExportOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Lifetime Business Report', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Includes every detail from all months', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final current = ref.read(customerRepositoryProvider).getAllCustomers();
                      final history = ref.read(historyRepositoryProvider).getAllHistory();
                      ExportService.exportLifetimeReport(current, history, isPdf: true);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final current = ref.read(customerRepositoryProvider).getAllCustomers();
                      final history = ref.read(historyRepositoryProvider).getAllHistory();
                      ExportService.exportLifetimeReport(current, history, isPdf: false);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.table_view_outlined),
                    label: const Text('Excel'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
