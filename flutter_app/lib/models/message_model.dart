import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy;
  final List<String> deliveredTo;
  final String type;
  final String? mediaUrl;
  final Map<String, dynamic>? mediaData;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.readBy = const [],
    this.deliveredTo = const [],
    this.type = 'text',
    this.mediaUrl,
    this.mediaData,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'readBy': readBy,
      'deliveredTo': deliveredTo,
      'type': type,
      'mediaUrl': mediaUrl,
      'mediaData': mediaData,
    };
  }

  factory Message.fromMap(String id, Map<String, dynamic> map) {
    return Message(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      readBy: List<String>.from(map['readBy'] ?? []),
      deliveredTo: List<String>.from(map['deliveredTo'] ?? []),
      type: map['type'] ?? 'text',
      mediaUrl: map['mediaUrl'],
      mediaData: map['mediaData'],
    );
  }

  factory Message.createText({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
  }) {
    return Message(
      id: FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').doc().id,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
      readBy: [senderId],
      deliveredTo: [senderId],
      type: 'text',
    );
  }

  factory Message.createMedia({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
    required String mediaType,
    required String mediaUrl,
    required Map<String, dynamic> mediaData,
  }) {
    return Message(
      id: FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').doc().id,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
      readBy: [senderId],
      deliveredTo: [senderId],
      type: mediaType,
      mediaUrl: mediaUrl,
      mediaData: mediaData,
    );
  }

  Message markAsReadBy(String userId) {
    if (readBy.contains(userId)) {
      return this;
    }
    
    final updatedReadBy = List<String>.from(readBy);
    updatedReadBy.add(userId);
    
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: timestamp,
      isRead: true,
      readBy: updatedReadBy,
      deliveredTo: deliveredTo,
      type: type,
      mediaUrl: mediaUrl,
      mediaData: mediaData,
    );
  }

  Message markAsDeliveredTo(String userId) {
    if (deliveredTo.contains(userId)) {
      return this;
    }
    
    final updatedDeliveredTo = List<String>.from(deliveredTo);
    updatedDeliveredTo.add(userId);
    
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: timestamp,
      isRead: isRead,
      readBy: readBy,
      deliveredTo: updatedDeliveredTo,
      type: type,
      mediaUrl: mediaUrl,
      mediaData: mediaData,
    );
  }

  bool get hasMedia => type != 'text';
  String get mediaType => type;
  String get mediaUrlString => mediaUrl ?? (mediaData?['url'] ?? '');
  String get mediaSize => mediaData?['size'] ?? '';
  int get mediaDuration => mediaData?['duration'] ?? 0;

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    List<String>? readBy,
    List<String>? deliveredTo,
    String? type,
    String? mediaUrl,
    Map<String, dynamic>? mediaData,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
      deliveredTo: deliveredTo ?? this.deliveredTo,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaData: mediaData ?? this.mediaData,
    );
  }
}

class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final String receiverId;
  final DateTime timestamp;
  final String type;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
    required this.type,
    this.imageUrl,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      content: map['content'] as String,
      senderId: map['senderId'] as String,
      receiverId: map['receiverId'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: map['type'] as String,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'imageUrl': imageUrl,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    String? senderId,
    String? receiverId,
    DateTime? timestamp,
    String? type,
    String? imageUrl,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
