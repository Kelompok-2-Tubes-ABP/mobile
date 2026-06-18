import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  final storage = const FlutterSecureStorage();

  List<UserNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<UserNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications({bool unreadOnly = false}) async {
    final token = await storage.read(key: 'token');
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('http://172.24.217.180:8000/api/notifications/feed?unread_only=$unreadOnly');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _unreadCount = data['unread_count'] ?? 0;
        
        if (data['notifications'] != null) {
          _notifications = (data['notifications'] as List)
              .map((item) => UserNotification.fromJson(item))
              .toList();
        } else {
          _notifications = [];
        }
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final token = await storage.read(key: 'token');
    if (token == null) return;

    try {
      final url = Uri.parse('http://172.24.217.180:8000/api/notifications/feed/$id/read');
      final response = await http.patch(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index] = UserNotification(
            id: _notifications[index].id,
            title: _notifications[index].title,
            message: _notifications[index].message,
            type: _notifications[index].type,
            isRead: true,
            createdAt: _notifications[index].createdAt,
          );
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final token = await storage.read(key: 'token');
    if (token == null) return;

    try {
      final url = Uri.parse('http://172.24.217.180:8000/api/notifications/feed/read-all');
      final response = await http.patch(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _notifications = _notifications.map((n) {
          return UserNotification(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
          );
        }).toList();
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }
}
