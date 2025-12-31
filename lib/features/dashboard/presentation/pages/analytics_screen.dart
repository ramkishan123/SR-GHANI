import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sr_ghani/services/customer_repository.dart';
import 'package:sr_ghani/services/export_service.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(customerRepositoryProvider);
    final customers = repository.getAllCustomers();

    final pending = customers.where((c) => c.status == 'pending').length;
    final processed = customers.where((c) => c.status == 'completed_by_us').length;
    final finished = customers.where((c) => c.status == 'fully_completed').length;
    final revenue = customers.fold(0.0, (prev, c) => prev + (c.status == 'fully_completed' ? (c.extraCharge ?? 0.0) : 0.0));
    final bool isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Business Analytics'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => ExportService.exportToPdf(customers),
          ),
          IconButton(
            icon: const Icon(Icons.table_view_outlined),
            onPressed: () => ExportService.exportToExcel(customers),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWideScreen ? 1100 : 800),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Performance Overview'),
                      const SizedBox(height: 16),
                      if (isWideScreen)
                        Row(
                          children: [
                            _buildSummaryCard('Pending', pending.toString(), Colors.orange),
                            const SizedBox(width: 12),
                            _buildSummaryCard('Processed', processed.toString(), Colors.blue),
                            const SizedBox(width: 12),
                            _buildSummaryCard('Finished', finished.toString(), Colors.green),
                            const SizedBox(width: 12),
                            _buildSummaryCard('Revenue', '₹${revenue.toStringAsFixed(0)}', Colors.purple),
                          ],
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildSummaryCard('Pending', pending.toString(), Colors.orange),
                              const SizedBox(width: 8),
                              _buildSummaryCard('Processed', processed.toString(), Colors.blue),
                              const SizedBox(width: 8),
                              _buildSummaryCard('Finished', finished.toString(), Colors.green),
                              const SizedBox(width: 8),
                              _buildSummaryCard('Revenue', '₹${revenue.toStringAsFixed(0)}', Colors.purple),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),
                      if (isWideScreen)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildChartCard(
                                title: 'Order Distribution',
                                chart: _buildDonutChart(pending, processed, finished),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader('Seed Type Statistics'),
                                  const SizedBox(height: 16),
                                  _buildSeedStatsCard(customers),
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _buildChartCard(
                          title: 'Order Distribution',
                          chart: _buildDonutChart(pending, processed, finished),
                        ),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Seed Type Statistics'),
                        const SizedBox(height: 16),
                        _buildSeedStatsCard(customers),
                      ],
                      const SizedBox(height: 120), // Padding for FloatingDock
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.show_chart, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildChartCard({required String title, required Widget chart}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildDonutChart(int pending, int processed, int finished) {
    final total = pending + processed + finished;
    if (total == 0) return const Center(child: Text('No data available'));

    return PieChart(
      PieChartData(
        sectionsSpace: 8,
        centerSpaceRadius: 50,
        sections: [
          _buildPieSection(pending.toDouble(), Colors.orange, 'Pending'),
          _buildPieSection(processed.toDouble(), Colors.blue, 'Processed'),
          _buildPieSection(finished.toDouble(), Colors.green, 'Finished'),
        ],
      ),
    );
  }

  PieChartSectionData _buildPieSection(double value, Color color, String title) {
    return PieChartSectionData(
      color: color,
      value: value,
      title: '', // Hide title on section
      radius: 25,
      badgeWidget: _buildChartBadge(color, title),
      badgePositionPercentageOffset: 1.4,
    );
  }

  Widget _buildChartBadge(Color color, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSeedStatsCard(List<dynamic> customers) {
    final Map<String, double> seedCounts = {};
    for (var c in customers) {
      for (var s in c.seeds) {
        seedCounts[s.seedType] = (seedCounts[s.seedType] ?? 0) + s.quantity;
      }
    }

    final sortedEntries = seedCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: sortedEntries.map((e) => _buildSeedProgressRow(e.key, e.value)).toList(),
      ),
    );
  }

  Widget _buildSeedProgressRow(String type, double quantity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  type,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text('${quantity.toStringAsFixed(1)} kg', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: quantity / 1000,
              backgroundColor: Colors.blue.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation(Colors.blue),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }
}
