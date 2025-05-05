import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models.dart';
import 'dataprovider.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
  int touchedIndex = -1;
  int selectedDetailIndex = -1; // Track the selected detail index
  late AnimationController _sparkleController;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller for sparkling effect
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _sparkleAnimation = Tween<double>(begin: 0, end: 1).animate(_sparkleController);

    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DataProvider>(context, listen: false);
      Future.wait([
        provider.fetchTransactions(),
        provider.fetchReminders(),
        provider.fetchGoals(),
      ]);
    });
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, provider, child) {
        // Calculate total balance, income, and expenses
        double income = 0.0;
        double expenses = 0.0;
        for (var transaction in provider.transactions) {
          if (transaction.type.toLowerCase() == 'income') {
            income += transaction.amount;
          } else if (transaction.type.toLowerCase() == 'expense') {
            expenses += transaction.amount;
          }
        }
        final totalBalance = income - expenses;

        // Prepare data for expense breakdown chart
        final expenseCategories = <String, double>{};
        for (var transaction in provider.transactions) {
          if (transaction.type.toLowerCase() == 'expense') {
            expenseCategories[transaction.category] =
                (expenseCategories[transaction.category] ?? 0) + transaction.amount;
          }
        }
        final chartData = expenseCategories.entries.toList();
        final colors = [
          Colors.blue,
          Colors.red,
          Colors.green,
          Colors.orange,
          Colors.purple,
        ];

        // Debug print to verify data
        debugPrint('Transactions: ${provider.transactions.length}');
        debugPrint('Expenses: $expenses');
        debugPrint('Expense Categories: $expenseCategories');

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                provider.fetchTransactions(),
                provider.fetchReminders(),
                provider.fetchGoals(),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Balance Section
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL BALANCE',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${NumberFormat('#,##0.00').format(totalBalance)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'INCOME',
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${NumberFormat('#,##0.00').format(income)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'EXPENSES',
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${NumberFormat('#,##0.00').format(expenses)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Upcoming Reminders Section
                    const Text(
                      'UPCOMING REMINDERS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    provider.reminders.isEmpty
                        ? const Center(child: Text('No reminders found'))
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.reminders.length,
                      itemBuilder: (context, index) {
                        final reminder = provider.reminders[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const Icon(
                              Icons.notifications,
                              color: Colors.orange,
                            ),
                            title: Text(reminder.title),
                            subtitle: Text(
                              'Due: ${DateFormat('MMM d, yyyy').format(reminder.dueDate)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\$${NumberFormat('#,##0.00').format(reminder.amount)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditReminderScreen(reminder: reminder),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Reminder'),
                                        content: Text(
                                            'Are you sure you want to delete "${reminder.title}"? This action cannot be undone.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(context); // Close confirmation dialog
                                              try {
                                                await provider.deleteReminder(reminder.id);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Reminder deleted successfully')),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Failed to delete reminder: $e')),
                                                );
                                              }
                                            },
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Your Goals Section
                    const Text(
                      'YOUR GOALS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    provider.goals.isEmpty
                        ? const Center(child: Text('No goals found'))
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.goals.length,
                      itemBuilder: (context, index) {
                        final goal = provider.goals[index];
                        final progress = goal.savedAmount / goal.amount;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      goal.title.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6200EE),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6200EE)),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '\$${goal.savedAmount.toStringAsFixed(2)} saved',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Goal: \$${goal.amount.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Expense Breakdown Section
                    const Text(
                      'EXPENSE BREAKDOWN',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    expenses == 0
                        ? const Center(child: Text('No expenses to display'))
                        : Column(
                      children: [
                        // Pie Chart with Sparkling Effect
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Sparkling effect layer
                            SizedBox(
                              height: 300,
                              width: 300,
                              child: AnimatedBuilder(
                                animation: _sparkleAnimation,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: SparklePainter(_sparkleAnimation.value),
                                    child: Container(),
                                  );
                                },
                              ),
                            ),
                            // Pie chart
                            SizedBox(
                              height: 300,
                              child: PieChart(
                                PieChartData(
                                  sections: chartData.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final category = entry.value.key;
                                    final amount = entry.value.value;
                                    final percentage = (amount / expenses) * 100;
                                    return PieChartSectionData(
                                      color: colors[index % colors.length],
                                      value: amount,
                                      title: '$category: ${percentage.toStringAsFixed(0)}%',
                                      radius: selectedDetailIndex == index ? 110 : 100, // Pop out effect
                                      titleStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      showTitle: touchedIndex == index,
                                    );
                                  }).toList(),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 0,
                                  pieTouchData: PieTouchData(
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection == null) {
                                          touchedIndex = -1;
                                          return;
                                        }
                                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            // Tooltip for touched section
                            if (touchedIndex != -1)
                              Positioned(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${chartData[touchedIndex].key}: \$${chartData[touchedIndex].value.toStringAsFixed(2)} (${((chartData[touchedIndex].value / expenses) * 100).toStringAsFixed(0)}%)',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Chart Details Below the Pie Chart
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: chartData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final category = entry.value.key;
                            final amount = entry.value.value;
                            final percentage = (amount / expenses) * 100;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  // Toggle selection: if the same category is tapped, deselect it
                                  selectedDetailIndex = (selectedDetailIndex == index) ? -1 : index;
                                });
                                debugPrint("Tapped detail: $category, index: $index");
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                                margin: const EdgeInsets.symmetric(vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: selectedDetailIndex == index
                                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: colors[index % colors.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        category,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '\$${amount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${percentage.toStringAsFixed(0)}%)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddReminderScreen()),
              );
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

// Custom painter for sparkling effect
class SparklePainter extends CustomPainter {
  final double animationValue;

  SparklePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random();
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Draw sparkles around the pie chart
    for (int i = 0; i < 20; i++) {
      final angle = (animationValue * 2 * pi) + (i * 2 * pi / 20);
      final radius = size.width / 2 + random.nextDouble() * 20;
      final x = size.width / 2 + radius * cos(angle);
      final y = size.height / 2 + radius * sin(angle);
      final sparkleSize = random.nextDouble() * 3 + 1;
      canvas.drawCircle(Offset(x, y), sparkleSize, paint);
    }
  }

  @override
  bool shouldRepaint(SparklePainter oldDelegate) => true;
}

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _dueDate;
  String _selectedType = 'Loan'; // Default type
  bool _isAddingReminder = false;

  final List<String> _reminderTypes = [
    'Loan',
    'Due',
    'Recharge',
    'Education Fees',
    'Rent',
    'Other',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _addReminder() async {
    if (_titleController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _dueDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields')),
        );
      }
      return;
    }

    setState(() {
      _isAddingReminder = true;
    });

    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    final newReminder = Reminder(
      id: '',
      title: _titleController.text,
      amount: double.parse(_amountController.text),
      dueDate: _dueDate!,
      type: _selectedType,
      notes: _notesController.text,
      createdAt: DateTime.now(),
    );

    final success = await dataProvider.addReminder(newReminder);

    if (!mounted) return;

    setState(() {
      _isAddingReminder = false;
    });

    if (success) {
      _titleController.clear();
      _amountController.clear();
      _notesController.clear();
      setState(() {
        _dueDate = null;
        _selectedType = 'Loan';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder added successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add reminder')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Reminder'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Reminder Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  items: _reminderTypes
                      .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Reminder Type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dueDate == null
                            ? 'Select Due Date'
                            : 'Due Date: ${DateFormat('MMM d, yyyy').format(_dueDate!)}',
                        style: TextStyle(
                          color: _dueDate == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _selectDate(context),
                      child: const Text('Pick Date'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _isAddingReminder
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _addReminder,
                  child: const Text('Add Reminder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditReminderScreen extends StatefulWidget {
  final Reminder reminder;

  const EditReminderScreen({super.key, required this.reminder});

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _dueDate;
  late String _selectedType;
  bool _isUpdatingReminder = false;

  final List<String> _reminderTypes = [
    'Loan',
    'Due',
    'Recharge',
    'Education Fees',
    'Rent',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with the existing reminder's data
    _titleController = TextEditingController(text: widget.reminder.title);
    _amountController = TextEditingController(text: widget.reminder.amount.toString());
    _notesController = TextEditingController(text: widget.reminder.notes);
    _dueDate = widget.reminder.dueDate;
    _selectedType = widget.reminder.type!;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _updateReminder() async {
    if (_titleController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _dueDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields')),
        );
      }
      return;
    }

    setState(() {
      _isUpdatingReminder = true;
    });

    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    final updatedReminder = Reminder(
      id: widget.reminder.id,
      title: _titleController.text,
      amount: double.parse(_amountController.text),
      dueDate: _dueDate,
      type: _selectedType,
      notes: _notesController.text,
      createdAt: widget.reminder.createdAt,
    );

    final success = await dataProvider.updateReminder(updatedReminder);

    if (!mounted) return;

    setState(() {
      _isUpdatingReminder = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder updated successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update reminder')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Reminder'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Reminder Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  items: _reminderTypes
                      .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Reminder Type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Due Date: ${DateFormat('MMM d, yyyy').format(_dueDate)}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _selectDate(context),
                      child: const Text('Pick Date'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _isUpdatingReminder
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _updateReminder,
                  child: const Text('Update Reminder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}