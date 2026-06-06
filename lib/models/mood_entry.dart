import 'package:flutter/material.dart';

class MoodEntry {
  final int? id;
  final int moodScore; // 1–5
  final String? note;
  final DateTime createdAt;

  const MoodEntry({
    this.id,
    required this.moodScore,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'mood_score': moodScore,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };

  factory MoodEntry.fromMap(Map<String, dynamic> map) => MoodEntry(
        id: map['id'] as int?,
        moodScore: map['mood_score'] as int,
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  String get moodEmoji {
    switch (moodScore) {
      case 1: return '😢';
      case 2: return '😕';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '😄';
      default: return '😐';
    }
  }

  String get moodLabel {
    switch (moodScore) {
      case 1: return 'Very Low';
      case 2: return 'Low';
      case 3: return 'Neutral';
      case 4: return 'Good';
      case 5: return 'Great';
      default: return 'Neutral';
    }
  }

  static const moodColors = [
    Color(0xFFE57373),
    Color(0xFFFFB74D),
    Color(0xFFFFD54F),
    Color(0xFF81C784),
    Color(0xFF4CAF50),
  ];

  Color get moodColor => moodColors[moodScore - 1];
}