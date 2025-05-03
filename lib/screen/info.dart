import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import 'dataprovider.dart';

class Analytics extends StatefulWidget {
  const Analytics({super.key});

  @override
  State<Analytics> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<Analytics> {
  DateTimeRange? _selectedDateRange;
  String _selectedChartType = 'line';

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    Provider.of<DataProvider>(context, listen: false).fetchTransactions();
  }

  List<AppTransaction> _getFilteredTransactions(List<AppTransaction> transactions) { // Changed to AppTransaction
    if (_selectedDateRange == null) return transactions;

    return transactions.where((t) {
      return (t.date.isAfter(_selectedDateRange!.start) ||
          t.date.isAtSameMomentAs(_selectedDateRange!.start)) &&
          (t.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))) ||
              t.date.isAtSameMomentAs(_selectedDateRange!.end));
    }).toList();
  }

  Map<DateTime, double> _aggregateData(String type, List<AppTransaction> transactions) { // Changed to AppTransaction
    final filteredTransactions = _getFilteredTransactions(transactions);
    final data = <DateTime, double>{};

    for (var transaction in filteredTransactions) {
      if (transaction.type == type) {
        final date = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
        data[date] = (data[date] ?? 0) + transaction.amount;
      }
    }

    return data;
  }

  Map<String, double> _aggregateByCategory(String type, List<AppTransaction> transactions) { // Changed to AppTransaction
    final filteredTransactions = _getFilteredTransactions(transactions);
    final data = <String, double>{};

    for (var transaction in filteredTransactions) {
      if (transaction.type == type) {
        data[transaction.category] = (data[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return data;
  }

  List<FlSpot> _prepareLineChartData(String type, List<AppTransaction> transactions) { // Changed to AppTransaction
    final data = _aggregateData(type, transactions);
    final spots = <FlSpot>[];
    final sortedDates = data.keys.toList()..sort();

    for (var i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[sortedDates[i]]!));
    }

    return spots;
  }

  List<PieChartSectionData> _preparePieChartData(List<AppTransaction> transactions) { // Changed to AppTransaction
    final expenseData = _aggregateByCategory('expense', transactions);
    final total = expenseData.values.fold<double>(0, (sum, value) => sum + value);

    const colors = [
      Color(0xFF3b82f6),
      Color(0xFF10b981),
      Color(0xFFF59e0b),
      Color(0xFFef4444),
      Color(0xFF8b5cf6),
      Color(0xFFec4899),
    ];

    return expenseData.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final value = entry.value.value;
      final percentage = total > 0 ? (value / total * 100).toStringAsFixed(0) : '0';
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: value,
        title: '$category: $percentage%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.55,
      );
    }).toList();
  }

  Map<String, double> _calculateSummary(List<AppTransaction> transactions) { // Changed to AppTransaction
    final filteredTransactions = _getFilteredTransactions(transactions);
    final totalIncome = filteredTransactions
        .where((t) => t.type == 'income')
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpenses = filteredTransactions
        .where((t) => t.type == 'expense')
        .fold<double>(0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpenses;
    return {
      'income': totalIncome,
      'expenses': totalExpenses,
      'balance': balance,
    };
  }

  Widget _buildSummaryCard(String title, double value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6b7280),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${NumberFormat('#,##0.00').format(value)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: Color(0xFFcbd5e1),
          ),
          const SizedBox(height: 16),
          Text(
            'No data available for the selected period',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6b7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6b7280),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final List<AppTransaction> transactions = dataProvider.transactions; // Changed to AppTransaction

        if (transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = _calculateSummary(transactions);
        final incomeData = _prepareLineChartData('income', transactions);
        final expenseData = _prepareLineChartData('expense', transactions);
        final pieChartData = _preparePieChartData(transactions);

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFC),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analytics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2d3748),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date Range',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6b7280),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedDateRange == null
                                      ? 'All Time'
                                      : '${DateFormat('MMM d, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_selectedDateRange!.end)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2d3748),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              final newRange = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                initialDateRange: _selectedDateRange,
                              );
                              if (newRange != null) {
                                setState(() {
                                  _selectedDateRange = newRange;
                                });
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4f46e5),
                              side: const BorderSide(color: Color(0xFFe2e8f0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Select Range'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 800
                          ? 3
                          : constraints.maxWidth > 500
                          ? 2
                          : 1;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildSummaryCard('Total Income', summary['income']!, const Color(0xFF10b981)),
                          _buildSummaryCard('Total Expenses', summary['expenses']!, const Color(0xFFef4444)),
                          _buildSummaryCard(
                              'Net Balance',
                              summary['balance']!,
                              summary['balance']! >= 0 ? const Color(0xFF10b981) : const Color(0xFFef4444)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            'Chart Type: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6b7280),
                            ),
                          ),
                          DropdownButton<String>(
                            value: _selectedChartType,
                            items: const [
                              DropdownMenuItem(value: 'line', child: Text('Line Chart')),
                              DropdownMenuItem(value: 'pie', child: Text('Pie Chart')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedChartType = value ?? 'line';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedChartType == 'line'
                                ? 'Income vs Expenses Over Time'
                                : 'Expense Breakdown by Category',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2d3748),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 300,
                            child: _selectedChartType == 'line'
                                ? (incomeData.isEmpty && expenseData.isEmpty)
                                ? _buildNoDataWidget()
                                : LineChart(
                              LineChartData(
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: incomeData,
                                    isCurved: true,
                                    color: const Color(0xFF10b981),
                                    barWidth: 3,
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: const Color(0xFF10b981).withOpacity(0.1),
                                    ),
                                  ),
                                  LineChartBarData(
                                    spots: expenseData,
                                    isCurved: true,
                                    color: const Color(0xFFef4444),
                                    barWidth: 3,
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: const Color(0xFFef4444).withOpacity(0.1),
                                    ),
                                  ),
                                ],
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final sortedDates =
                                        _aggregateData('income', transactions).keys.toList()
                                          ..sort();
                                        if (value.toInt() >= sortedDates.length) return const Text('');
                                        return Text(
                                          DateFormat('MMM d').format(sortedDates[value.toInt()]),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6b7280),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(show: true),
                              ),
                            )
                                : pieChartData.isEmpty
                                ? _buildNoDataWidget()
                                : PieChart(
                              PieChartData(
                                sections: pieChartData,
                                centerSpaceRadius: 40,
                                sectionsSpace: 2,
                              ),
                            ),
                          ),
                          if (_selectedChartType == 'line') ...[
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLegend('Income', const Color(0xFF10b981)),
                                const SizedBox(width: 20),
                                _buildLegend('Expenses', const Color(0xFFef4444)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}