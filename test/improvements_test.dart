import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/models/message_model.dart';
import 'package:flutter_app/models/notification_model.dart';
import 'package:flutter_app/models/call_models.dart';
import 'package:flutter_app/services/chat_service.dart';
import 'package:flutter_app/services/notification_service.dart';

void main() {
  group('Message Model Tests', () {
    test('should create text message', () {
      final message = Message.createText(
        chatId: 'chat123',
        senderId: 'user123',
        receiverId: 'user456',
        content: 'Hello World',
      );

      expect(message.chatId, equals('chat123'));
      expect(message.senderId, equals('user123'));
      expect(message.receiverId, equals('user456'));
      expect(message.content, equals('Hello World'));
      expect(message.type, equals('text'));
    });

    test('should create image message', () {
      final message = Message.createImage(
        chatId: 'chat123',
        senderId: 'user123',
        receiverId: 'user456',
        mediaUrl: 'https://example.com/image.jpg',
      );

      expect(message.chatId, equals('chat123'));
      expect(message.senderId, equals('user123'));
      expect(message.receiverId, equals('user456'));
      expect(message.type, equals('image'));
      expect(message.mediaUrl, equals('https://example.com/image.jpg'));
    });

    test('should convert message to map', () {
      final message = Message.createText(
        chatId: 'chat123',
        senderId: 'user123',
        receiverId: 'user456',
        content: 'Hello World',
      );

      final map = message.toMap();
      expect(map['chatId'], equals('chat123'));
      expect(map['senderId'], equals('user123'));
      expect(map['receiverId'], equals('user456'));
      expect(map['content'], equals('Hello World'));
      expect(map['type'], equals('text'));
    });

    test('should create message from map', () {
      final map = {
        'chatId': 'chat123',
        'senderId': 'user123',
        'receiverId': 'user456',
        'content': 'Hello World',
        'type': 'text',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'readBy': ['user123'],
        'deliveredTo': ['user123'],
      };

      final message = Message.fromMap('message123', map);
      expect(message.id, equals('message123'));
      expect(message.chatId, equals('chat123'));
      expect(message.senderId, equals('user123'));
      expect(message.receiverId, equals('user456'));
      expect(message.content, equals('Hello World'));
      expect(message.type, equals('text'));
    });
  });

  group('Notification Model Tests', () {
    test('should create notification', () {
      final notification = Notification(
        id: 'notif123',
        userId: 'user123',
        senderId: 'user456',
        senderName: 'John Doe',
        type: 'message',
        title: 'New Message',
        body: 'You have a new message',
        timestamp: DateTime.now(),
        isRead: false,
        targetId: 'chat123',
        data: {'messageId': 'msg123'},
      );

      expect(notification.id, equals('notif123'));
      expect(notification.userId, equals('user123'));
      expect(notification.senderId, equals('user456'));
      expect(notification.senderName, equals('John Doe'));
      expect(notification.type, equals('message'));
      expect(notification.title, equals('New Message'));
      expect(notification.body, equals('You have a new message'));
      expect(notification.isRead, isFalse);
      expect(notification.targetId, equals('chat123'));
      expect(notification.data, equals({'messageId': 'msg123'}));
    });

    test('should convert notification to map', () {
      final notification = Notification(
        id: 'notif123',
        userId: 'user123',
        senderId: 'user456',
        senderName: 'John Doe',
        type: 'message',
        title: 'New Message',
        body: 'You have a new message',
        timestamp: DateTime.now(),
        isRead: false,
        targetId: 'chat123',
        data: {'messageId': 'msg123'},
      );

      final map = notification.toMap();
      expect(map['id'], equals('notif123'));
      expect(map['userId'], equals('user123'));
      expect(map['senderId'], equals('user456'));
      expect(map['senderName'], equals('John Doe'));
      expect(map['type'], equals('message'));
      expect(map['title'], equals('New Message'));
      expect(map['body'], equals('You have a new message'));
      expect(map['isRead'], isFalse);
      expect(map['targetId'], equals('chat123'));
      expect(map['data'], equals({'messageId': 'msg123'}));
    });

    test('should create notification from map', () {
      final map = {
        'id': 'notif123',
        'userId': 'user123',
        'senderId': 'user456',
        'senderName': 'John Doe',
        'type': 'message',
        'title': 'New Message',
        'body': 'You have a new message',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'targetId': 'chat123',
        'data': {'messageId': 'msg123'},
      };

      final notification = Notification.fromMap(map);
      expect(notification.id, equals('notif123'));
      expect(notification.userId, equals('user123'));
      expect(notification.senderId, equals('user456'));
      expect(notification.senderName, equals('John Doe'));
      expect(notification.type, equals('message'));
      expect(notification.title, equals('New Message'));
      expect(notification.body, equals('You have a new message'));
      expect(notification.isRead, isFalse);
      expect(notification.targetId, equals('chat123'));
      expect(notification.data, equals({'messageId': 'msg123'}));
    });

    test('should mark notification as read', () {
      final notification = Notification(
        id: 'notif123',
        userId: 'user123',
        senderId: 'user456',
        senderName: 'John Doe',
        type: 'message',
        title: 'New Message',
        body: 'You have a new message',
        timestamp: DateTime.now(),
        isRead: false,
        targetId: 'chat123',
        data: {'messageId': 'msg123'},
      );

      final updatedNotification = notification.markAsRead();
      expect(updatedNotification.isRead, isTrue);
    });

    test('should create message notification', () {
      final message = Message.createText(
        chatId: 'chat123',
        senderId: 'user123',
        receiverId: 'user456',
        content: 'Hello World',
      );

      final notification = Notification.createMessageNotification(
        message: message,
        receiverId: 'user456',
        receiverName: 'Jane Doe',
      );

      expect(notification.type, equals('message'));
      expect(notification.title, equals('New Message'));
      expect(notification.body, equals('Hello World'));
      expect(notification.targetId, equals('chat123'));
      expect(notification.data, contains('messageId'));
    });
  });

  group('Call Model Tests', () {
    test('should create call', () {
      final call = Call(
        id: 'call123',
        callerId: 'user123',
        callerName: 'John Doe',
        callerImage: 'https://example.com/image.jpg',
        receiverId: 'user456',
        receiverName: 'Jane Doe',
        receiverImage: 'https://example.com/image2.jpg',
        status: CallStatus.ringing,
        startTime: DateTime.now(),
        endTime: null,
        duration: 0,
      );

      expect(call.id, equals('call123'));
      expect(call.callerId, equals('user123'));
      expect(call.callerName, equals('John Doe'));
      expect(call.callerImage, equals('https://example.com/image.jpg'));
      expect(call.receiverId, equals('user456'));
      expect(call.receiverName, equals('Jane Doe'));
      expect(call.receiverImage, equals('https://example.com/image2.jpg'));
      expect(call.status, equals(CallStatus.ringing));
      expect(call.endTime, isNull);
      expect(call.duration, equals(0));
    });

    test('should update call status', () {
      final call = Call(
        id: 'call123',
        callerId: 'user123',
        callerName: 'John Doe',
        callerImage: 'https://example.com/image.jpg',
        receiverId: 'user456',
        receiverName: 'Jane Doe',
        receiverImage: 'https://example.com/image2.jpg',
        status: CallStatus.ringing,
        startTime: DateTime.now(),
        endTime: null,
        duration: 0,
      );

      final updatedCall = call.copyWith(status: CallStatus.ongoing);
      expect(updatedCall.status, equals(CallStatus.ongoing));
    });

    test('should get call status text', () {
      final call = Call(
        id: 'call123',
        callerId: 'user123',
        callerName: 'John Doe',
        callerImage: 'https://example.com/image.jpg',
        receiverId: 'user456',
        receiverName: 'Jane Doe',
        receiverImage: 'https://example.com/image2.jpg',
        status: CallStatus.ringing,
        startTime: DateTime.now(),
        endTime: null,
        duration: 0,
      );

      expect(call.statusText, equals('Ringing'));
    });
  });
} 