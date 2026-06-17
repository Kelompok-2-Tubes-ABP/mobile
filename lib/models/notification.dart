import 'package:flutter/material.dart';

class UserNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  UserNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }

  IconData get icon {
    switch (type) {
      case 'budget':
        return Icons.error_outline;
      case 'transaction':
        return Icons.attach_money;
      case 'bill':
      case 'debt':
      case 'recurring':
        return Icons.event_note;
      case 'goal':
        return Icons.gps_fixed;
      default:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case 'budget':
        return Colors.red;
      case 'transaction':
        return Colors.green;
      case 'bill':
      case 'debt':
        return Colors.orange;
      case 'recurring':
        return Colors.indigo;
      case 'goal':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }
}
