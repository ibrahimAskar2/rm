import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String type;
  final String senderId;
  final String senderName;
  final String text;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileType;
  final String? fileName;
  final DateTime timestamp;
  final bool isRead;
  final bool isEdited;
  final DateTime? editedAt;
  final List<String> readBy;
  final List<String> deliveredTo;

  Message({
    required this.id,
    required this.type,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imageUrl,
    this.fileUrl,
    this.fileType,
    this.fileName,
    required this.timestamp,
    this.isRead = false,
    this.isEdited = false,
    this.editedAt,
    this.readBy = const [],
    this.deliveredTo = const [],
  });

  // تحويل الرسالة إلى Map لتخزينها في Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileName': fileName,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'readBy': readBy,
      'deliveredTo': deliveredTo,
    };
  }

  // إنشاء رسالة من Map من Firestore
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      type: map['type'] ?? 'text',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      fileUrl: map['fileUrl'],
      fileType: map['fileType'],
      fileName: map['fileName'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      isEdited: map['isEdited'] ?? false,
      editedAt: map['editedAt'] != null ? (map['editedAt'] as Timestamp).toDate() : null,
      readBy: List<String>.from(map['readBy'] ?? []),
      deliveredTo: List<String>.from(map['deliveredTo'] ?? []),
    );
  }

  // إنشاء رسالة نصية جديدة
  factory Message.createText({
    required String chatId,
    required String senderId,
    required String text,
  }) {
    return Message(
      id: FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').doc().id,
      type: 'text',
      senderId: senderId,
      senderName: '',
      text: text,
      timestamp: DateTime.now(),
      isRead: false,
      isEdited: false,
      editedAt: null,
      readBy: [senderId],
      deliveredTo: [],
    );
  }

  // إنشاء رسالة وسائط جديدة
  factory Message.createMedia({
    required String chatId,
    required String senderId,
    required String text,
    required String mediaType,
    required Map<String, dynamic> mediaData,
  }) {
    return Message(
      id: FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').doc().id,
      type: mediaType,
      senderId: senderId,
      senderName: '',
      text: text,
      imageUrl: mediaData['imageUrl'],
      fileUrl: mediaData['fileUrl'],
      fileType: mediaData['fileType'],
      fileName: mediaData['fileName'],
      timestamp: DateTime.now(),
      isRead: false,
      isEdited: false,
      editedAt: null,
      readBy: [senderId],
      deliveredTo: [],
    );
  }

  // تعليم الرسالة كمقروءة من قبل مستخدم
  Message markAsReadBy(String userId) {
    if (readBy.contains(userId)) {
      return this;
    }
    
    final updatedReadBy = List<String>.from(readBy);
    updatedReadBy.add(userId);
    
    return Message(
      id: id,
      type: type,
      senderId: senderId,
      senderName: senderName,
      text: text,
      imageUrl: imageUrl,
      fileUrl: fileUrl,
      fileType: fileType,
      fileName: fileName,
      timestamp: timestamp,
      isRead: true,
      isEdited: isEdited,
      editedAt: editedAt,
      readBy: updatedReadBy,
      deliveredTo: deliveredTo,
    );
  }

  // التحقق مما إذا كانت الرسالة تحتوي على وسائط
  bool get hasMedia => type != 'text';

  // الحصول على نوع الوسائط
  String get mediaType => type;

  // الحصول على رابط الوسائط
  String get mediaUrl => imageUrl ?? fileUrl ?? '';

  // الحصول على حجم الوسائط
  String get mediaSize => '';

  // الحصول على مدة الوسائط (للصوت والفيديو)
  int get mediaDuration => 0;

  Message copyWith({
    String? id,
    String? type,
    String? senderId,
    String? senderName,
    String? text,
    String? imageUrl,
    String? fileUrl,
    String? fileType,
    String? fileName,
    DateTime? timestamp,
    bool? isRead,
    bool? isEdited,
    DateTime? editedAt,
    List<String>? readBy,
    List<String>? deliveredTo,
  }) {
    return Message(
      id: id ?? this.id,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileName: fileName ?? this.fileName,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      readBy: readBy ?? this.readBy,
      deliveredTo: deliveredTo ?? this.deliveredTo,
    );
  }
}
