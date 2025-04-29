import 'package:cloud_firestore/cloud_firestore.dart';

class Statistics {
  final int totalMessages;
  final int totalChats;
  final int totalGroups;
  final int totalPrivateChats;
  final int totalMediaMessages;
  final int totalVoiceMessages;
  final int totalImageMessages;
  final Map<String, int> messagesPerDay;
  final Map<String, int> messagesPerHour;
  final Map<String, int> messagesPerUser;
  final Map<String, int> messagesPerGroup;
  final DateTime lastUpdated;

  Statistics({
    required this.totalMessages,
    required this.totalChats,
    required this.totalGroups,
    required this.totalPrivateChats,
    required this.totalMediaMessages,
    required this.totalVoiceMessages,
    required this.totalImageMessages,
    required this.messagesPerDay,
    required this.messagesPerHour,
    required this.messagesPerUser,
    required this.messagesPerGroup,
    required this.lastUpdated,
  });

  factory Statistics.fromMap(Map<String, dynamic> map) {
    return Statistics(
      totalMessages: map['totalMessages'] ?? 0,
      totalChats: map['totalChats'] ?? 0,
      totalGroups: map['totalGroups'] ?? 0,
      totalPrivateChats: map['totalPrivateChats'] ?? 0,
      totalMediaMessages: map['totalMediaMessages'] ?? 0,
      totalVoiceMessages: map['totalVoiceMessages'] ?? 0,
      totalImageMessages: map['totalImageMessages'] ?? 0,
      messagesPerDay: Map<String, int>.from(map['messagesPerDay'] ?? {}),
      messagesPerHour: Map<String, int>.from(map['messagesPerHour'] ?? {}),
      messagesPerUser: Map<String, int>.from(map['messagesPerUser'] ?? {}),
      messagesPerGroup: Map<String, int>.from(map['messagesPerGroup'] ?? {}),
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalMessages': totalMessages,
      'totalChats': totalChats,
      'totalGroups': totalGroups,
      'totalPrivateChats': totalPrivateChats,
      'totalMediaMessages': totalMediaMessages,
      'totalVoiceMessages': totalVoiceMessages,
      'totalImageMessages': totalImageMessages,
      'messagesPerDay': messagesPerDay,
      'messagesPerHour': messagesPerHour,
      'messagesPerUser': messagesPerUser,
      'messagesPerGroup': messagesPerGroup,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  Statistics copyWith({
    int? totalMessages,
    int? totalChats,
    int? totalGroups,
    int? totalPrivateChats,
    int? totalMediaMessages,
    int? totalVoiceMessages,
    int? totalImageMessages,
    Map<String, int>? messagesPerDay,
    Map<String, int>? messagesPerHour,
    Map<String, int>? messagesPerUser,
    Map<String, int>? messagesPerGroup,
    DateTime? lastUpdated,
  }) {
    return Statistics(
      totalMessages: totalMessages ?? this.totalMessages,
      totalChats: totalChats ?? this.totalChats,
      totalGroups: totalGroups ?? this.totalGroups,
      totalPrivateChats: totalPrivateChats ?? this.totalPrivateChats,
      totalMediaMessages: totalMediaMessages ?? this.totalMediaMessages,
      totalVoiceMessages: totalVoiceMessages ?? this.totalVoiceMessages,
      totalImageMessages: totalImageMessages ?? this.totalImageMessages,
      messagesPerDay: messagesPerDay ?? this.messagesPerDay,
      messagesPerHour: messagesPerHour ?? this.messagesPerHour,
      messagesPerUser: messagesPerUser ?? this.messagesPerUser,
      messagesPerGroup: messagesPerGroup ?? this.messagesPerGroup,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
} 