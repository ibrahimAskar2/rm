import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String content;
  final String type;
  final String? mediaUrl;
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy;
  final List<String> deliveredTo;
  final Map<String, dynamic>? mediaData;

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
      id: const Uuid().v4(),
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      type: mediaType,
      mediaUrl: mediaUrl,
      mediaData: mediaData,
      timestamp: DateTime.now(),
      isRead: false,
      readBy: [senderId],
      deliveredTo: [senderId],
    );
  }
  
  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    this.mediaUrl,
    required this.timestamp,
    this.isRead = false,
    this.readBy = const [],
    this.deliveredTo = const [],
    this.mediaData,
  });

  factory Message.createText({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
  }) {
    return Message(
      id: const Uuid().v4(),
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      type: 'text',
      timestamp: DateTime.now(),
      isRead: false,
      readBy: [senderId],
      deliveredTo: [senderId],
    );
  }

  factory Message.createImage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String mediaUrl,
  }) {
    return Message(
      id: const Uuid().v4(),
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      content: 'صورة',
      type: 'image',
      mediaUrl: mediaUrl,
      timestamp: DateTime.now(),
      isRead: false,
      readBy: [senderId],
      deliveredTo: [senderId],
    );
  }

  factory Message.fromMap(String id, Map<String, dynamic> map) {
    return Message(
      id: id,
      chatId: map['chatId'] as String,
      senderId: map['senderId'] as String,
      receiverId: map['receiverId'] as String,
      content: map['content'] as String,
      type: map['type'] as String,
      mediaUrl: map['mediaUrl'] as String?,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] as bool? ?? false,
      readBy: List<String>.from(map['readBy'] ?? []),
      deliveredTo: List<String>.from(map['deliveredTo'] ?? []),
      mediaData: map['mediaData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'mediaUrl': mediaUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'readBy': readBy,
      'deliveredTo': deliveredTo,
      'mediaData': mediaData,
    };
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
      type: type,
      mediaUrl: mediaUrl,
      timestamp: timestamp,
      isRead: true,
      readBy: updatedReadBy,
      deliveredTo: deliveredTo,
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
      type: type,
      mediaUrl: mediaUrl,
      timestamp: timestamp,
      isRead: isRead,
      readBy: readBy,
      deliveredTo: updatedDeliveredTo,
      mediaData: mediaData,
    );
  }

  bool get hasMedia => type != 'text';
  String get mediaType => type;
  String get mediaUrlString => mediaUrl ?? '';
  String get mediaSize => mediaData?['size']?.toString() ?? '';
  int get mediaDuration => mediaData?['duration'] ?? 0;

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? content,
    String? type,
    String? mediaUrl,
    DateTime? timestamp,
    bool? isRead,
    List<String>? readBy,
    List<String>? deliveredTo,
    Map<String, dynamic>? mediaData,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
      deliveredTo: deliveredTo ?? this.deliveredTo,
      mediaData: mediaData ?? this.mediaData,
    );
  }
}
