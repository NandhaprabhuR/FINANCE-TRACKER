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
      // Optimistically add the reminder to the local state for immediate UI feedback
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      final tempReminder = Reminder(
        id: tempId,
        title: reminder.title,
        amount: reminder.amount,
        dueDate: reminder.dueDate,
        type: reminder.type,
        notes: reminder.notes,
        createdAt: reminder.createdAt,
      );
      _reminders.add(tempReminder);
      notifyListeners();
      debugPrint("Local reminder added for user $_userId");

      // Perform the Firestore write
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('reminders')
          .add(reminder.toMap());
      debugPrint("Reminder added to Firestore for user $_userId");

      // Fetch the latest data to ensure consistency
      await fetchReminders();
      return true;
    } catch (e) {
      debugPrint("Failed to add reminder: $e");
      // If Firestore write fails, revert the local change
      await fetchReminders();
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

  Future<bool> deleteReminder(String id) async {
    if (_userId.isEmpty) {
      debugPrint("User not authenticated");
      return false;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('reminders')
          .doc(id)
          .delete();
      debugPrint("Reminder deleted for user $_userId");
      await fetchReminders();
      return true;
    } catch (e) {
      debugPrint("Failed to delete reminder: $e");
      return false;
    }
  }

  Future<bool> deleteGoal(String id) async {
    if (_userId.isEmpty) {
      debugPrint("User not authenticated");
      return false;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('goals')
          .doc(id)
          .delete();
      debugPrint("Goal deleted for user $_userId");
      await fetchGoals();
      return true;
    } catch (e) {
      debugPrint("Failed to delete goal: $e");
      return false;
    }
  }

  Future<bool> updateGoal(Goal updatedGoal) async {
    if (_userId.isEmpty) {
      debugPrint("User not authenticated");
      return false;
    }
    try {
      // Optimistically update the local state for immediate UI feedback
      final index = _goals.indexWhere((goal) => goal.id == updatedGoal.id);
      if (index != -1) {
        _goals[index] = updatedGoal;
        notifyListeners();
        debugPrint("Local goal updated for user $_userId");
      }

      // Perform the Firestore update
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('goals')
          .doc(updatedGoal.id)
          .update(updatedGoal.toMap());
      debugPrint("Goal updated in Firestore for user $_userId");

      // Fetch the latest data to ensure consistency
      await fetchGoals();
      return true;
    } catch (e) {
      debugPrint("Failed to update goal: $e");
      // If Firestore update fails, revert the local change
      await fetchGoals();
      return false;
    }
  }

  Future<bool> updateReminder(Reminder updatedReminder) async {
    if (_userId.isEmpty) {
      debugPrint("User not authenticated");
      return false;
    }
    try {
      // Validate the reminder ID
      if (updatedReminder.id == null || updatedReminder.id!.isEmpty) {
        debugPrint("Invalid reminder ID: ${updatedReminder.id}");
        throw Exception("Reminder ID cannot be null or empty");
      }

      // Validate the reminder data
      final reminderMap = updatedReminder.toMap();
      debugPrint("Reminder data to update: $reminderMap");

      // Optimistically update the local state for immediate UI feedback
      final index = _reminders.indexWhere((reminder) => reminder.id == updatedReminder.id);
      if (index != -1) {
        _reminders[index] = updatedReminder;
        notifyListeners();
        debugPrint("Local reminder updated for user $_userId");
      } else {
        debugPrint("Reminder with ID ${updatedReminder.id} not found in local state");
      }

      // Perform the Firestore update
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('reminders')
          .doc(updatedReminder.id)
          .update(reminderMap);
      debugPrint("Reminder updated in Firestore for user $_userId");

      // Fetch the latest data to ensure consistency
      await fetchReminders();
      return true;
    } catch (e) {
      debugPrint("Failed to update reminder: $e");
      debugPrint("Stack trace: ${StackTrace.current}");
      // If Firestore update fails, revert the local change
      await fetchReminders();
      return false;
    }
  }
}