import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import 'dataprovider.dart';
import 'profile.dart';
import 'services.dart';

class TransactionForm extends StatefulWidget {
  const TransactionForm({super.key});

  @override
  State<TransactionForm> createState() => TransactionFormState();
}

class TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _message;
  Color? _messageColor;

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final _notesController = TextEditingController();
  String _type = 'expense';
  String _category = '';

  late CategoryPredictionService _predictionService;

  final List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Refund',
    'Other',
  ];

  final List<String> _expenseCategories = [
    'Food',
    'Housing',
    'Transportation',
    'Utilities',
    'Entertainment',
    'Healthcare',
    'Shopping',
    'Education',
    'Personal Care',
    'Travel',
    'Gifts',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _predictionService = CategoryPredictionService();
    _initializeService();
  // _descriptionController.addListener(_predictCategory);
  }

  Future<void> _initializeService() async {
    await _predictionService.loadModel();
    // The new CategoryPredictionService logs errors internally,
    // so we don't need to set an error message here unless we want to display it
  }

  Future<void> _predictCategory() async {
    final description = _descriptionController.text;
    if (description.isEmpty) {
      setState(() {
        _category = '';
      });
      return;
    }

    final predictedCategory = await _predictionService.predictCategory(description);
    print("kongu$predictedCategory");
    setState(() {
      if (predictedCategory != null) {
        // Ensure the predicted category matches one of the dropdown options
        if (_type == 'expense' && _expenseCategories.contains(predictedCategory)) {
          _category = predictedCategory;
        } else if (_type == 'income' && _incomeCategories.contains(predictedCategory)) {
          _category = predictedCategory;
        } else {
          _category = '';
          _message = 'Predicted category not applicable for ${_type == 'expense' ? 'expense' : 'income'}. Please select manually.';
          _messageColor = const Color(0xFFef4444);
        }
      } else {
        _category = '';
        _message = 'Unable to predict category. Please select manually.';
        _messageColor = const Color(0xFFef4444);
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_predictCategory);
    _descriptionController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    _predictionService.dispose();
    super.dispose();
  }

  void _resetForm() {
    _descriptionController.clear();
    _amountController.clear();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _notesController.clear();
    setState(() {
      _type = 'expense';
      _category = '';
      _message = null;
      _messageColor = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
      _messageColor = null;
    });

    try {
      final transaction = AppTransaction(
        id: '',
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        type: _type,
        category: _category,
        date: DateFormat('yyyy-MM-dd').parse(_dateController.text),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await Provider.of<DataProvider>(context, listen: false).addTransaction(transaction);

      setState(() {
        _message = 'Transaction added successfully!';
        _messageColor = const Color(0xFF10b981);
        _resetForm();
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to add transaction: $e';
        _messageColor = const Color(0xFFef4444);
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == 'income' ? _incomeCategories : _expenseCategories;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_message != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: _messageColor?.withOpacity(0.1),
                                    border: Border.all(
                                        color: _messageColor?.withOpacity(0.2) ?? Colors.transparent),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _message!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _messageColor,
                                    ),
                                  ),
                                ),
                              Text(
                                'Transaction Type',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _type = 'expense';
                                          _category = '';
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _type == 'expense'
                                            ? const Color(0xFFef4444)
                                            : Theme.of(context).colorScheme.surface,
                                        foregroundColor: _type == 'expense'
                                            ? Colors.white
                                            : Theme.of(context).colorScheme.onSurface,
                                        side: BorderSide(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.arrow_upward, size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            'Expense',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _type = 'income';
                                          _category = '';
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _type == 'income'
                                            ? const Color(0xFF10b981)
                                            : Theme.of(context).colorScheme.surface,
                                        foregroundColor: _type == 'income'
                                            ? Colors.white
                                            : Theme.of(context).colorScheme.onSurface,
                                        side: BorderSide(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.arrow_downward, size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            'Income',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 600;
                                  return Wrap(
                                    spacing: 16,
                                    runSpacing: 20,
                                    children: [
                                      SizedBox(
                                        width: isWide ? constraints.maxWidth / 2 - 8 : constraints.maxWidth,
                                        child: TextFormField(
                                          controller: _descriptionController,

                                          onEditingComplete: (){
                                            print("kongu");_predictCategory();},

                                          decoration: const InputDecoration(
                                            labelText: 'Description *',
                                            hintText: 'What was this transaction for?',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.person),
                                          ),
                                          validator: (value) =>
                                          value!.isEmpty ? 'Please enter a description' : null,
                                        ),
                                      ),
                                      SizedBox(
                                        width: isWide ? constraints.maxWidth / 2 - 8 : constraints.maxWidth,
                                        child: TextFormField(
                                          controller: _amountController,
                                          decoration: const InputDecoration(
                                            labelText: 'Amount *',
                                            hintText: '0.00',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.monetization_on),
                                          ),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          validator: (value) {
                                            if (value!.isEmpty) return 'Please enter an amount';
                                            final num = double.tryParse(value);
                                            if (num == null || num <= 0) return 'Please enter a valid amount';
                                            return null;
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: isWide ? constraints.maxWidth / 2 - 8 : constraints.maxWidth,
                                        child: DropdownButtonFormField<String>(
                                          value: _category.isEmpty ? null : _category,
                                          decoration: const InputDecoration(
                                            labelText: 'Category *',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.category),
                                          ),
                                          items: categories
                                              .map((category) => DropdownMenuItem(
                                            value: category,
                                            child: Text(category),
                                          ))
                                              .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _category = value ?? '';
                                            });
                                          },
                                          validator: (value) =>
                                          value == null || value.isEmpty ? 'Please select a category' : null,
                                        ),
                                      ),
                                      SizedBox(
                                        width: isWide ? constraints.maxWidth / 2 - 8 : constraints.maxWidth,
                                        child: TextFormField(
                                          controller: _dateController,
                                          decoration: const InputDecoration(
                                            labelText: 'Date *',
                                            hintText: 'YYYY-MM-DD',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.calendar_today),
                                          ),
                                          onTap: () async {
                                            final date = await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100),
                                            );
                                            if (date != null) {
                                              setState(() {
                                                _dateController.text =
                                                    DateFormat('yyyy-MM-dd').format(date);
                                              });
                                            }
                                          },
                                          validator: (value) {
                                            if (value!.isEmpty) return 'Please select a date';
                                            try {
                                              DateFormat('yyyy-MM-dd').parse(value);
                                              return null;
                                            } catch (e) {
                                              return 'Please enter a valid date (YYYY-MM-DD)';
                                            }
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: constraints.maxWidth,
                                        child: TextFormField(
                                          controller: _notesController,
                                          decoration: const InputDecoration(
                                            labelText: 'Notes (Optional)',
                                            hintText: 'Any additional details',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.note),
                                          ),
                                          maxLines: 3,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4f46e5),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : const Text(
                                    'Add Transaction',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Add New Transaction',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ),
        ),
      ],
    );
  }
}