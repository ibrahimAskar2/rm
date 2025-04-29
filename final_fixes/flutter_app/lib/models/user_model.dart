import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final String? bio;
  final String? status;
  final bool isOnline;
  final DateTime lastSeen;
  final Map<String, dynamic>? settings;
  final List<String>? blockedUsers;
  final List<String>? favoriteChats;
  final Map<String, dynamic>? notifications;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.bio,
    this.status,
    this.isOnline = false,
    required this.lastSeen,
    this.settings,
    this.blockedUsers,
    this.favoriteChats,
    this.notifications,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      profileImage: map['profileImage'],
      bio: map['bio'],
      status: map['status'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: (map['lastSeen'] as Timestamp).toDate(),
      settings: map['settings'],
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
      favoriteChats: List<String>.from(map['favoriteChats'] ?? []),
      notifications: map['notifications'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'bio': bio,
      'status': status,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'settings': settings,
      'blockedUsers': blockedUsers,
      'favoriteChats': favoriteChats,
      'notifications': notifications,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? bio,
    String? status,
    bool? isOnline,
    DateTime? lastSeen,
    Map<String, dynamic>? settings,
    List<String>? blockedUsers,
    List<String>? favoriteChats,
    Map<String, dynamic>? notifications,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      settings: settings ?? this.settings,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      favoriteChats: favoriteChats ?? this.favoriteChats,
      notifications: notifications ?? this.notifications,
    );
  }

  // الحصول على الحروف الأولى من اسم المستخدم
  String get initials {
    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    } else {
      return '';
    }
  }

  // التحقق مما إذا كان المستخدم نشطًا مؤخرًا
  bool get isRecentlyActive {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    return difference.inMinutes < 5;
  }

  // الحصول على حالة المستخدم كنص
  String get statusText {
    if (isOnline) {
      return 'متصل الآن';
    } else if (isRecentlyActive) {
      return 'نشط مؤخرًا';
    } else {
      return 'غير متصل';
    }
  }
}
