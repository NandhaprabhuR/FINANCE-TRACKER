import 'package:cloud_firestore/cloud_firestore.dart';

class AppTransaction {
  final String id;
  final String description;
  final double amount;
  final String type;
  final String category;
  final DateTime date;
  final String? notes;

  AppTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.notes,
  });

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    return AppTransaction(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory AppTransaction.fromMap(Map<String, dynamic> data, String id) {
    return AppTransaction(
      id: id,
      description: data['description'] as String,
      amount: (data['amount'] as num).toDouble(),
      type: data['type'] as String,
      category: data['category'] as String,
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date,
      'notes': notes,
    };
  }
}

class Reminder {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String? type; // Made nullable
  final String? notes; // Made nullable
  final DateTime? createdAt; // Made nullable

  Reminder({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.type,
    this.notes,
    this.createdAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      type: json['type'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'type': type,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> data, String id) {
    return Reminder(
      id: id,
      title: data['title'] as String,
      amount: (data['amount'] as num).toDouble(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      type: data['type'] as String?,
      notes: data['notes'] as String?,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'dueDate': dueDate,
      'type': type,
      'notes': notes,
      'createdAt': createdAt,
    };
  }
}

class Goal {
  final String id;
  final String title;
  final double amount;
  final double savedAmount;
  final DateTime targetDate;
  final String category;
  final String notes;
  final DateTime? createdAt; // Made nullable

  Goal({
    required this.id,
    required this.title,
    required this.amount,
    required this.savedAmount,
    required this.targetDate,
    required this.category,
    required this.notes,
    this.createdAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      savedAmount: (json['savedAmount'] as num).toDouble(),
      targetDate: DateTime.parse(json['targetDate'] as String),
      category: json['category'] as String,
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'savedAmount': savedAmount,
      'targetDate': targetDate.toIso8601String(),
      'category': category,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> data, String id) {
    return Goal(
      id: id,
      title: data['title'] as String,
      amount: (data['amount'] as num).toDouble(),
      savedAmount: (data['savedAmount'] as num).toDouble(),
      targetDate: (data['targetDate'] as Timestamp).toDate(),
      category: data['category'] as String,
      notes: data['notes'] as String? ?? '',
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'savedAmount': savedAmount,
      'targetDate': targetDate,
      'category': category,
      'notes': notes,
      'createdAt': createdAt,
    };
  }
}