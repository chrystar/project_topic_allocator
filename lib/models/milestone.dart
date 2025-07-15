import 'package:cloud_firestore/cloud_firestore.dart';

class Milestone {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime? completedDate;
  final String? feedback;
  final int weightage; // Percentage of project completion this milestone represents

  Milestone({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.completedDate,
    this.feedback,
    this.weightage = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'isCompleted': isCompleted,
      'completedDate': completedDate != null ? Timestamp.fromDate(completedDate!) : null,
      'feedback': feedback,
      'weightage': weightage,
    };
  }

  factory Milestone.fromMap(String id, Map<String, dynamic> map) {
    return Milestone(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      isCompleted: map['isCompleted'] ?? false,
      completedDate: map['completedDate'] != null 
          ? (map['completedDate'] as Timestamp).toDate()
          : null,
      feedback: map['feedback'],
      weightage: map['weightage'] ?? 0,
    );
  }

  Milestone copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedDate,
    String? feedback,
    int? weightage,
  }) {
    return Milestone(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      feedback: feedback ?? this.feedback,
      weightage: weightage ?? this.weightage,
    );
  }
}
