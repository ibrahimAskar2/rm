import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/call_models.dart';
import '../services/call_service.dart';
import '../screens/call_screen.dart';
import '../widgets/incoming_call_widget.dart';

class CallNotificationService {
  // Singleton pattern
  static final CallNotificationService _instance = CallNotificationService._internal();
  factory CallNotificationService() => _instance;
  CallNotificationService._internal();

  // Services
  final CallService _callService = CallService();
  
  // Notifications
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Streams
  final _incomingCallController = StreamController<Call>.broadcast();
  Stream<Call> get incomingCallStream => _incomingCallController.stream;
  
  // تهيئة خدمة الإشعارات
  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // إعداد إشعارات Firebase
    FirebaseMessaging.onMessage.listen(_handleFirebaseMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleFirebaseMessageOpened);
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    if (response.payload != null) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.payload as Map<String, dynamic>
      );
      if (data['type'] == 'call') {
        final String callId = data['callId'];
        final String action = data['action'];
        
        if (action == 'accept') {
          await _callService.acceptCall(callId);
        } else if (action == 'reject') {
          await _callService.rejectCall(callId);
        }
      }
    }
  }

  Future<void> _handleFirebaseMessage(RemoteMessage message) async {
    if (message.data['type'] == 'call') {
      await showCallNotification(
        title: message.notification?.title ?? 'مكالمة واردة',
        body: message.notification?.body ?? 'لديك مكالمة واردة',
        payload: message.data,
      );
    }
  }

  Future<void> _handleFirebaseMessageOpened(RemoteMessage message) async {
    if (message.data['type'] == 'call') {
      final String callId = message.data['callId'];
      final String action = message.data['action'];
      
      if (action == 'accept') {
        await _callService.acceptCall(callId);
      } else if (action == 'reject') {
        await _callService.rejectCall(callId);
      }
    }
  }

  Future<void> showCallNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'call_channel',
      'المكالمات',
      channelDescription: 'إشعارات المكالمات الصوتية',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('ringtone'),
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'ringtone.wav',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload.toString(),
    );
  }

  // الاستماع للمكالمات الواردة
  void _listenForIncomingCalls(BuildContext context) {
    // الاستماع للمكالمات الواردة من خدمة المكالمات
    // في التطبيق الفعلي، سيتم استخدام Firestore لتتبع المكالمات الواردة
  }

  // معالجة رسائل Firebase في الخلفية
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // معالجة الإشعارات في الخلفية
    if (message.data['type'] == 'call') {
      // عرض إشعار مكالمة واردة
      // في التطبيق الفعلي، سيتم استخدام إشعارات عالية الأولوية
    }
  }

  // عرض نافذة المكالمة الواردة
  void showIncomingCallDialog(BuildContext context, Call call) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => IncomingCallWidget(
        call: call,
        onCallAccepted: () {
          // إلغاء الإشعار
          _notifications.cancel(call.id.hashCode);
        },
        onCallRejected: () {
          // إلغاء الإشعار
          _notifications.cancel(call.id.hashCode);
        },
      ),
    );
  }

  // إلغاء إشعار المكالمة
  Future<void> cancelCallNotification(String callId) async {
    await _notifications.cancel(callId.hashCode);
  }

  // التخلص من الموارد
  void dispose() {
    _incomingCallController.close();
  }
}
