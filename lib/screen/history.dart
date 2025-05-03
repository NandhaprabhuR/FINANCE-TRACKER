import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models.dart'; // Used for AppTransaction
import 'dataprovider.dart';

class TransactionHistory extends StatefulWidget {
  const TransactionHistory({super.key});

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  bool _sortAscending = true;
  final _searchController = TextEditingController();
  String? _selectedType;
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;

  // Available filter options
  final List<String> _types = ['ALL TYPES', 'INCOME', 'EXPENSE'];
  final List<String> _categories = [
    'ALL CATEGORIES',
    'Food',
    'Transport',
    'Entertainment',
    'Bills',
    'Health',
    'Salary',
    'Gift',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = 'ALL TYPES';
    _selectedCategory = 'ALL CATEGORIES';
    _searchController.addListener(() {
      setState(() {}); // Rebuild when search text changes
    });
  }

  Map<String, List<AppTransaction>> _groupTransactionsByDate(List<AppTransaction> transactions) {
    final sortedTransactions = List.from(transactions)
      ..sort((a, b) {
        final comparison = a.date.compareTo(b.date);
        return _sortAscending ? comparison : -comparison;
      });

    final Map<String, List<AppTransaction>> grouped = {};
    for (var transaction in sortedTransactions) {
      final dateKey = DateFormat('MMM d, yyyy').format(transaction.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }
    return grouped;
  }

  List<AppTransaction> _filterTransactions(List<AppTransaction> transactions) {
    List<AppTransaction> filtered = transactions;

    // Apply search filter
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((transaction) {
        return transaction.description.toLowerCase().contains(searchQuery) ||
            transaction.category.toLowerCase().contains(searchQuery);
      }).toList();
    }

    // Apply type filter
    if (_selectedType != null && _selectedType != 'ALL TYPES') {
      filtered = filtered.where((transaction) {
        return transaction.type.toUpperCase() == _selectedType;
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != null && _selectedCategory != 'ALL CATEGORIES') {
      filtered = filtered.where((transaction) {
        return transaction.category.toUpperCase() == _selectedCategory;
      }).toList();
    }

    // Apply date range filter
    if (_startDate != null) {
      filtered = filtered.where((transaction) {
        return transaction.date.isAfter(_startDate!.subtract(const Duration(days: 1)));
      }).toList();
    }
    if (_endDate != null) {
      filtered = filtered.where((transaction) {
        return transaction.date.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Ensure end date is not before start date
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _toggleSortOrder() {
    setState(() {
      _sortAscending = !_sortAscending;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final allTransactions = dataProvider.transactions;
        final filteredTransactions = _filterTransactions(allTransactions);
        final groupedTransactions = _groupTransactionsByDate(filteredTransactions);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Transaction History'),
            actions: [
              IconButton(
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                onPressed: _toggleSortOrder,
                tooltip: 'Sort by Date',
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                try {
                  await dataProvider.fetchTransactions();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to refresh transactions: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search and Filter Section
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search transactions...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedType,
                              items: _types.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value;
                                });
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              items: _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: 'Start Date',
                                labelText: _startDate != null
                                    ? DateFormat('MMM d, yyyy').format(_startDate!)
                                    : null,
                                suffixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              onTap: () => _selectStartDate(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: 'End Date',
                                labelText: _endDate != null
                                    ? DateFormat('MMM d, yyyy').format(_endDate!)
                                    : null,
                                suffixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              onTap: () => _selectEndDate(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Transaction List
                      Text(
                        'SHOWING ${filteredTransactions.length} OF ${allTransactions.length} TRANSACTIONS',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      filteredTransactions.isEmpty
                          ? const Center(child: Text('No transactions found'))
                          : Column(
                        children: groupedTransactions.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${entry.value.length} transaction${entry.value.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...entry.value.map((transaction) {
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: transaction.type.toLowerCase() == 'income'
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      child: Icon(
                                        transaction.type.toLowerCase() == 'income'
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: transaction.type.toLowerCase() == 'income'
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    title: Text(transaction.description),
                                    subtitle: Text(
                                      '${transaction.category}\n${DateFormat('hh:mm a').format(transaction.date)}',
                                    ),
                                    trailing: Text(
                                      '\$${NumberFormat('#,##0.00').format(transaction.amount)}',
                                      style: TextStyle(
                                        color: transaction.type.toLowerCase() == 'income'
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}