import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:moneynest/models.dart';
import 'dataprovider.dart';

class Goals extends StatelessWidget {
  const Goals({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                try {
                  await provider.fetchGoals();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to refresh goals: $e'),
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
                                      Expanded(
                                        child: Text(
                                          goal.title.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '${(progress * 100).toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF6200EE),
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
                                              showDialog(
                                                context: context,
                                                builder: (context) => EditGoalDialog(goal: goal),
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
                                                  title: const Text('Delete Goal'),
                                                  content: Text(
                                                      'Are you sure you want to delete "${goal.title}"? This action cannot be undone.'),
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
                                                          await provider.deleteGoal(goal.id);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('Goal deleted successfully')),
                                                          );
                                                        } catch (e) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('Failed to delete goal: $e')),
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
                                  const SizedBox(height: 8),
                                  Text(
                                    'Target: ${DateFormat('MMM d, yyyy').format(goal.targetDate)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    goal.notes,
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddGoalDialog(),
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

class AddGoalDialog extends StatefulWidget {
  const AddGoalDialog({super.key});

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _savedAmountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _targetDate;
  String? _selectedCategory;
  bool _isAddingGoal = false;

  final List<String> _categories = [
    'General',
    'Travel',
    'Education',
    'Health',
    'Savings',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _savedAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  Future<void> _addGoal() async {
    if (_titleController.text.isEmpty ||
        _targetAmountController.text.isEmpty ||
        _savedAmountController.text.isEmpty ||
        _targetDate == null ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    double? targetAmount;
    double? savedAmount;
    try {
      targetAmount = double.parse(_targetAmountController.text);
      savedAmount = double.parse(_savedAmountController.text);
      if (targetAmount <= 0 || savedAmount < 0) {
        throw const FormatException('Amounts must be positive, and saved amount cannot be negative');
      }
      if (savedAmount > targetAmount) {
        throw const FormatException('Saved amount cannot exceed target amount');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid amount: $e')),
      );
      return;
    }

    setState(() {
      _isAddingGoal = true;
    });

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final newGoal = Goal(
      id: '',
      title: _titleController.text,
      amount: targetAmount,
      savedAmount: savedAmount,
      targetDate: _targetDate!,
      category: _selectedCategory!,
      notes: _notesController.text,
      createdAt: DateTime.now(),
    );

    try {
      await dataProvider.addGoal(newGoal);
      await Future.delayed(const Duration(milliseconds: 500)); // Small delay to ensure Firestore sync
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Goal added successfully')),
      );
      debugPrint("Goal added, closing dialog");
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Close the dialog
        debugPrint("Dialog closed");
      } else {
        debugPrint("Cannot pop dialog: Navigator.canPop returned false");
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to add goal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingGoal = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Add New Goal',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Goal Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                prefixText: '\$',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _savedAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Saved Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                prefixText: '\$',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _targetDate == null
                        ? 'Select Target Date'
                        : 'Target: ${DateFormat('MMM d, yyyy').format(_targetDate!)}',
                    style: TextStyle(
                      color: _targetDate == null ? Colors.grey : Colors.black,
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
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: const Text('Select Category'),
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
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
              debugPrint("Dialog cancelled");
            }
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isAddingGoal ? null : _addGoal,
          child: _isAddingGoal
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Add Goal'),
        ),
      ],
    );
  }
}

class EditGoalDialog extends StatefulWidget {
  final Goal goal;

  const EditGoalDialog({super.key, required this.goal});

  @override
  State<EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<EditGoalDialog> {
  late TextEditingController _titleController;
  late TextEditingController _targetAmountController;
  late TextEditingController _savedAmountController;
  late TextEditingController _notesController;
  late DateTime _targetDate;
  late String _selectedCategory;
  bool _isUpdatingGoal = false;

  final List<String> _categories = [
    'General',
    'Travel',
    'Education',
    'Health',
    'Savings',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with the existing goal's data
    _titleController = TextEditingController(text: widget.goal.title);
    _targetAmountController = TextEditingController(text: widget.goal.amount.toString());
    _savedAmountController = TextEditingController(text: widget.goal.savedAmount.toString());
    _notesController = TextEditingController(text: widget.goal.notes);
    _targetDate = widget.goal.targetDate;
    _selectedCategory = widget.goal.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _savedAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  Future<void> _updateGoal() async {
    if (_titleController.text.isEmpty ||
        _targetAmountController.text.isEmpty ||
        _savedAmountController.text.isEmpty ||
        _targetDate == null ||
        _selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    double? targetAmount;
    double? savedAmount;
    try {
      targetAmount = double.parse(_targetAmountController.text);
      savedAmount = double.parse(_savedAmountController.text);
      if (targetAmount <= 0 || savedAmount < 0) {
        throw const FormatException('Amounts must be positive, and saved amount cannot be negative');
      }
      if (savedAmount > targetAmount) {
        throw const FormatException('Saved amount cannot exceed target amount');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid amount: $e')),
      );
      return;
    }

    setState(() {
      _isUpdatingGoal = true;
    });

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final updatedGoal = Goal(
      id: widget.goal.id,
      title: _titleController.text,
      amount: targetAmount,
      savedAmount: savedAmount,
      targetDate: _targetDate,
      category: _selectedCategory,
      notes: _notesController.text,
      createdAt: widget.goal.createdAt,
    );

    try {
      await dataProvider.updateGoal(updatedGoal);
      await Future.delayed(const Duration(milliseconds: 500)); // Small delay to ensure Firestore sync
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Goal updated successfully')),
      );
      debugPrint("Goal updated, closing dialog");
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Close the dialog
        debugPrint("Dialog closed");
      } else {
        debugPrint("Cannot pop dialog: Navigator.canPop returned false");
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to update goal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingGoal = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Edit Goal',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Goal Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                prefixText: '\$',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _savedAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Saved Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                prefixText: '\$',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Target: ${DateFormat('MMM d, yyyy').format(_targetDate)}',
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
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: const Text('Select Category'),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
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
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
              debugPrint("Dialog cancelled");
            }
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUpdatingGoal ? null : _updateGoal,
          child: _isUpdatingGoal
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Update Goal'),
        ),
      ],
    );
  }
}