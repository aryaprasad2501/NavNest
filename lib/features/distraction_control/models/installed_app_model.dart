class InstalledAppModel {
  final String packageName;
  final String appName;
  final bool isSystemApp;
  final bool isBlocked;

  const InstalledAppModel({
    required this.packageName,
    required this.appName,
    this.isSystemApp = false,
    this.isBlocked = false,
  });

  InstalledAppModel copyWith({
    String? packageName,
    String? appName,
    bool? isSystemApp,
    bool? isBlocked,
  }) {
    return InstalledAppModel(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }

  factory InstalledAppModel.fromMap(Map<String, dynamic> map, {bool isBlocked = false}) {
    return InstalledAppModel(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      isSystemApp: map['isSystemApp'] as bool? ?? false,
      isBlocked: isBlocked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'isSystemApp': isSystemApp,
      'isBlocked': isBlocked,
    };
  }

  /// Categorizes apps into recognizable buckets for intuitive student filtering.
  String get category {
    final lower = packageName.toLowerCase();
    if (lower.contains('instagram') ||
        lower.contains('snapchat') ||
        lower.contains('facebook') ||
        lower.contains('tiktok') ||
        lower.contains('reddit') ||
        lower.contains('twitter') ||
        lower.contains('threads') ||
        lower.contains('discord') ||
        lower.contains('telegram') ||
        lower.contains('whatsapp')) {
      return 'Social & Chat';
    }
    if (lower.contains('youtube') ||
        lower.contains('netflix') ||
        lower.contains('primevideo') ||
        lower.contains('hotstar') ||
        lower.contains('spotify') ||
        lower.contains('music')) {
      return 'Media & Streaming';
    }
    if (lower.contains('pubg') ||
        lower.contains('game') ||
        lower.contains('clash') ||
        lower.contains('roblox') ||
        lower.contains('freefire')) {
      return 'Gaming';
    }
    if (lower.contains('chrome') ||
        lower.contains('browser') ||
        lower.contains('firefox') ||
        lower.contains('opera')) {
      return 'Browsers';
    }
    return 'Other Apps';
  }

  String get iconEmoji {
    switch (category) {
      case 'Social & Chat':
        return '💬';
      case 'Media & Streaming':
        return '🎬';
      case 'Gaming':
        return '🎮';
      case 'Browsers':
        return '🌐';
      default:
        return '📱';
    }
  }
}
