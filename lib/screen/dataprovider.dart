import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models.dart';

class DataProvider with ChangeNotifier {
  List<AppTransaction> _transactions = [];
  List<Reminder> _reminders = [];
  List<Goal> _goals = [];

  List<AppTransaction> get transactions => _transactions;
  List<Reminder> get reminders => _reminders;
  List<Goal> get goals => _goals;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> addTransaction(AppTransaction transaction) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .add(transaction.toMap());
      debugPrint("Transaction added for user $_userId");
      await fetchTransactions();
    } catch (e) {
      debugPrint("Failed to add transaction: $e");
      throw Exception('Failed to add transaction: $e');
    }
  }

  Future<void> fetchTransactions() async {
    if (_userId.isEmpty) throw Exception('User not authenticated');
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .get();
      _transactions = snapshot.docs.map((doc) {
        return AppTransaction.fromMap(doc.data(), doc.id);
      }).toList();
      debugPrint("Fetched ${_transactions.length} transactions for user $_userId");
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to fetch transactions: $e");
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  Future<bool> addReminder(Reminder reminder) async {
    if (_userId.isEmpty) {
      debugPrint("User not authenticated");
      return false;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('reminders')
          .add(reminder.toMap());
      debugPrint("Reminder added for user $_userId");
      await fetchReminders();
      return true;
    } catch (e) {
      debugPrint("Failed to add reminder: $e");
      return false;
    }
  }

  Future<void> fetchReminders() async {
    if (_userId.isEmpty) throw Exception('User not authenticated');
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('reminders')
          .get();
      _reminders = snapshot.docs.map((doc) {
        return Reminder.fromMap(doc.data(), doc.id);
      }).toList();
      debugPrint("Fetched ${_reminders.length} reminders for user $_userId");
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to fetch reminders: $e");
      throw Exception('Failed to fetch reminders: $e');
    }
  }

  Future<bool> addGoal(Goal goal) async {
    if (_userId.isEmpty) {
      debugPrint("User not authenticated");
      return false;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('goals')
          .add(goal.toMap());
      debugPrint("Goal added for user $_userId");
      await fetchGoals();
      return true;
    } catch (e) {
      debugPrint("Failed to add goal: $e");
      return false;
    }
  }

  Future<void> fetchGoals() async {
    if (_userId.isEmpty) throw Exception('User not authenticated');
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('goals')
          .get();
      _goals = snapshot.docs.map((doc) {
        return Goal.fromMap(doc.data(), doc.id);
      }).toList();
      debugPrint("Fetched ${_goals.length} goals for user $_userId");
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to fetch goals: $e");
      throw Exception('Failed to fetch goals: $e');
    }
  }

  updateGoal(Goal updatedGoal) {}

  deleteGoal(String id) {}

  deleteReminder(String id) {}

  updateReminder(Reminder updatedReminder) {}
}