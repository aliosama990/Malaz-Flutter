import 'package:flutter/foundation.dart';

enum NotificationType {
  emergency,
  daily,
  weekly,
}

class NotificationModel {
  final String id;
  final String text;
  final String time;
  final String icon; // 'warning', 'check_circle', 'info'
  final String iconColor; // 'orange', 'green', 'red'
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.text,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  NotificationModel copyWith({
    String? id,
    String? text,
    String? time,
    String? icon,
    String? iconColor,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      text: text ?? this.text,
      time: time ?? this.time,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  // Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'time': time,
      'icon': icon,
      'iconColor': iconColor,
      'type': type.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  // Create from JSON from API
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      time: json['time'] ?? '',
      icon: json['icon'] ?? 'info',
      iconColor: json['iconColor'] ?? 'green',
      type: _parseNotificationType(json['type']),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'emergency':
        return NotificationType.emergency;
      case 'daily':
        return NotificationType.daily;
      case 'weekly':
        return NotificationType.weekly;
      default:
        return NotificationType.daily;
    }
  }
}

class NotificationsProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get emergency notifications
  List<NotificationModel> get emergencyNotifications {
    return getNotificationsByType(NotificationType.emergency);
  }

  // Get daily notifications
  List<NotificationModel> get dailyNotifications {
    return getNotificationsByType(NotificationType.daily);
  }

  // Get weekly notifications
  List<NotificationModel> get weeklyNotifications {
    return getNotificationsByType(NotificationType.weekly);
  }

  // Get unread notifications count
  int get unreadCount {
    return _notifications.where((n) => !n.isRead).length;
  }

  // Get unread emergency count
  int get unreadEmergencyCount {
    return emergencyNotifications.where((n) => !n.isRead).length;
  }

  // Check if there are any emergency notifications
  bool get hasEmergencyNotifications {
    return emergencyNotifications.isNotEmpty;
  }

  // Load dummy data (for testing until API is ready)
  void loadDummyData() {
    _notifications = [
      // Emergency notifications
      NotificationModel(
        id: 'emg_1',
        text: 'اقتربت سلمي من حدود منطقة الامان المخصصه',
        time: '10:03 ص',
        icon: 'warning',
        iconColor: 'orange',
        type: NotificationType.emergency,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'emg_2',
        text: 'اقترب ميعاد انتهاء اليوم الدراسي لسلمي يرجى المتي لمصاحبتها',
        time: '11:45 ص',
        icon: 'warning',
        iconColor: 'orange',
        type: NotificationType.emergency,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),

      // Daily notifications
      NotificationModel(
        id: 'daily_1',
        text: 'احمد وصل المدرسه بأمان',
        time: '8:30 ص',
        icon: 'check_circle',
        iconColor: 'green',
        type: NotificationType.daily,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      NotificationModel(
        id: 'daily_2',
        text: 'سلمي وصلت المدرسه بأمان',
        time: '8:30 ص',
        icon: 'check_circle',
        iconColor: 'green',
        type: NotificationType.daily,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      NotificationModel(
        id: 'daily_3',
        text: 'اقتربت سلمي من حدود منطقة الامان المخصصه',
        time: '10:03 ص',
        icon: 'warning',
        iconColor: 'orange',
        type: NotificationType.daily,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'daily_4',
        text: 'الان سلمي داخل منطقة امان',
        time: '10:35 ص',
        icon: 'check_circle',
        iconColor: 'green',
        type: NotificationType.daily,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'daily_5',
        text: 'اقترب ميعاد انتهاء اليوم الدراسي لسلمي يرجى المتي لمصاحبتها',
        time: '11:45 ص',
        icon: 'info',
        iconColor: 'orange',
        type: NotificationType.daily,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: 'daily_6',
        text: 'فرح احمد في ميعاد انتهاء اليوم الدراسي',
        time: '2:00 م',
        icon: 'check_circle',
        iconColor: 'green',
        type: NotificationType.daily,
        createdAt: DateTime.now(),
      ),
    ];
    notifyListeners();
  }

  // Fetch notifications from API
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      // final response = await ApiService.getNotifications();
      // _notifications = response.map((json) => NotificationModel.fromJson(json)).toList();

      // For now, load dummy data
      await Future.delayed(const Duration(seconds: 1)); // Simulate API delay
      loadDummyData();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      // TODO: Call API to mark as read
      // await ApiService.markNotificationAsRead(notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      // TODO: Call API to mark all as read
      // await ApiService.markAllNotificationsAsRead();

      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Add new notification (for real-time updates)
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  // Clear all notifications
  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      // TODO: Call API to delete notification
      // await ApiService.deleteNotification(notificationId);

      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Refresh notifications
  Future<void> refreshNotifications() async {
    await fetchNotifications();
  }
}
