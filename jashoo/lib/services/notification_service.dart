import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _requestPermissions();
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
    // You can navigate to specific screens based on payload
  }

  // Overspending Alert
  Future<void> showOverspendingAlert({
    required double amount,
    required double limit,
    required String category,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'overspending_channel',
      'Overspending Alerts',
      channelDescription: 'Alerts when you exceed spending limits',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF5252),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      '⚠️ Overspending Alert',
      'You\'ve spent KES ${amount.toStringAsFixed(0)} on $category, exceeding your limit of KES ${limit.toStringAsFixed(0)}',
      notificationDetails,
      payload: 'overspending:$category',
    );
  }

  // Daily Spending Summary
  Future<void> showDailySpendingSummary({
    required double totalSpent,
    required Map<String, double> categoryBreakdown,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'spending_summary_channel',
      'Spending Summary',
      channelDescription: 'Daily spending summaries',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final topCategory = categoryBreakdown.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    await _notifications.show(
      2,
      '📊 Daily Spending Summary',
      'You spent KES ${totalSpent.toStringAsFixed(0)} today. Top category: $topCategory',
      notificationDetails,
      payload: 'spending_summary',
    );
  }

  // Unusual Activity Alert
  Future<void> showUnusualActivityAlert({
    required String activity,
    required String location,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'security_channel',
      'Security Alerts',
      channelDescription: 'Alerts for unusual account activity',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF5252),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      3,
      '🔒 Unusual Activity Detected',
      '$activity from $location. If this wasn\'t you, secure your account immediately.',
      notificationDetails,
      payload: 'security:unusual_activity',
    );
  }

  // Savings Goal Progress
  Future<void> showSavingsProgressAlert({
    required String goalName,
    required double progress,
    required double target,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'savings_channel',
      'Savings Alerts',
      channelDescription: 'Updates on your savings goals',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF10B981),
    );

    const iosDetails = DarwinNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final percentage = (progress / target * 100).toStringAsFixed(0);

    await _notifications.show(
      4,
      '💰 Savings Goal Update',
      '$goalName is $percentage% complete! KES ${progress.toStringAsFixed(0)} of KES ${target.toStringAsFixed(0)}',
      notificationDetails,
      payload: 'savings:$goalName',
    );
  }

  // Job Application Update
  Future<void> showJobApplicationUpdate({
    required String jobTitle,
    required String status,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'jobs_channel',
      'Job Alerts',
      channelDescription: 'Updates on your job applications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF10B981),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      5,
      '💼 Job Application Update',
      'Your application for "$jobTitle" has been $status',
      notificationDetails,
      payload: 'job:$jobTitle',
    );
  }

  // Transaction Alert
  Future<void> showTransactionAlert({
    required String type,
    required double amount,
    required String currency,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'transaction_channel',
      'Transaction Alerts',
      channelDescription: 'Notifications for all transactions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final emoji = type == 'deposit' ? '💰' : '💸';
    final action = type == 'deposit' ? 'deposited' : 'withdrawn';

    await _notifications.show(
      6,
      '$emoji Transaction ${type.toUpperCase()}',
      'You have $action $currency ${amount.toStringAsFixed(2)}',
      notificationDetails,
      payload: 'transaction:$type',
    );
  }

  // Fraud Alert
  Future<void> showFraudAlert({
    required String message,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'fraud_channel',
      'Fraud Alerts',
      channelDescription: 'Critical fraud and security alerts',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF0000),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      7,
      '🚨 FRAUD ALERT',
      message,
      notificationDetails,
      payload: 'fraud_alert',
    );
  }

  // Login from New Device
  Future<void> showNewDeviceLogin({
    required String deviceName,
    required String location,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'security_channel',
      'Security Alerts',
      channelDescription: 'Alerts for unusual account activity',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF9800),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      8,
      '🔐 New Device Login',
      'Login detected from $deviceName in $location. If this wasn\'t you, change your password immediately.',
      notificationDetails,
      payload: 'security:new_device',
    );
  }

  // Clear all notifications
  Future<void> clearAll() async {
    await _notifications.cancelAll();
  }

  // Clear specific notification
  Future<void> clear(int id) async {
    await _notifications.cancel(id);
  }

  // Generic notification method for custom alerts
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    Color? color,
    Importance importance = Importance.high,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final androidDetails = AndroidNotificationDetails(
      'general_channel',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: importance,
      priority: importance == Importance.max ? Priority.max : Priority.high,
      icon: '@mipmap/ic_launcher',
      color: color ?? const Color(0xFF10B981),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}

