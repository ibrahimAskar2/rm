class AppSettings {
  final bool darkMode;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool readReceiptsEnabled;
  final bool typingIndicatorEnabled;
  final bool autoDownloadMedia;
  final String language;
  final String theme;
  final Map<String, bool> notificationSettings;
  final Map<String, dynamic> privacySettings;
  final Map<String, dynamic> chatSettings;

  AppSettings({
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.readReceiptsEnabled = true,
    this.typingIndicatorEnabled = true,
    this.autoDownloadMedia = true,
    this.language = 'ar',
    this.theme = 'default',
    this.notificationSettings = const {
      'messages': true,
      'groups': true,
      'calls': true,
      'mentions': true,
    },
    this.privacySettings = const {
      'lastSeen': 'everyone',
      'profilePhoto': 'everyone',
      'status': 'everyone',
      'readReceipts': 'everyone',
    },
    this.chatSettings = const {
      'enterToSend': true,
      'mediaAutoDownload': true,
      'messagePreview': true,
      'linkPreview': true,
    },
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      darkMode: map['darkMode'] ?? false,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      readReceiptsEnabled: map['readReceiptsEnabled'] ?? true,
      typingIndicatorEnabled: map['typingIndicatorEnabled'] ?? true,
      autoDownloadMedia: map['autoDownloadMedia'] ?? true,
      language: map['language'] ?? 'ar',
      theme: map['theme'] ?? 'default',
      notificationSettings: Map<String, bool>.from(map['notificationSettings'] ?? {}),
      privacySettings: Map<String, dynamic>.from(map['privacySettings'] ?? {}),
      chatSettings: Map<String, dynamic>.from(map['chatSettings'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'darkMode': darkMode,
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'readReceiptsEnabled': readReceiptsEnabled,
      'typingIndicatorEnabled': typingIndicatorEnabled,
      'autoDownloadMedia': autoDownloadMedia,
      'language': language,
      'theme': theme,
      'notificationSettings': notificationSettings,
      'privacySettings': privacySettings,
      'chatSettings': chatSettings,
    };
  }

  AppSettings copyWith({
    bool? darkMode,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? readReceiptsEnabled,
    bool? typingIndicatorEnabled,
    bool? autoDownloadMedia,
    String? language,
    String? theme,
    Map<String, bool>? notificationSettings,
    Map<String, dynamic>? privacySettings,
    Map<String, dynamic>? chatSettings,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      readReceiptsEnabled: readReceiptsEnabled ?? this.readReceiptsEnabled,
      typingIndicatorEnabled: typingIndicatorEnabled ?? this.typingIndicatorEnabled,
      autoDownloadMedia: autoDownloadMedia ?? this.autoDownloadMedia,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      privacySettings: privacySettings ?? this.privacySettings,
      chatSettings: chatSettings ?? this.chatSettings,
    );
  }
} 