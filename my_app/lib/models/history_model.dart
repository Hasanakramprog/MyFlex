// models/history_model.dart
class HistoryItem {
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final DateTime watchedAt;
  final int viewCount;
  final String? playlistTitle;
  
  // New fields for enhanced tracking
  final int watchDurationInSeconds; // How long the user watched
  final int totalDurationInSeconds; // Total video duration
  final double watchProgress; // Progress as a percentage (0-100)
  final int lastPositionInSeconds; // Position where user stopped watching

  HistoryItem({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.watchedAt,
    required this.viewCount,
    this.playlistTitle,
    this.watchDurationInSeconds = 0,
    this.totalDurationInSeconds = 0,
    this.watchProgress = 0.0,
    this.lastPositionInSeconds = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'watchedAt': watchedAt.toIso8601String(),
      'viewCount': viewCount,
      'playlistTitle': playlistTitle,
      'watchDurationInSeconds': watchDurationInSeconds,
      'totalDurationInSeconds': totalDurationInSeconds,
      'watchProgress': watchProgress,
      'lastPositionInSeconds': lastPositionInSeconds,
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      videoId: map['videoId'],
      title: map['title'],
      thumbnailUrl: map['thumbnailUrl'],
      watchedAt: DateTime.parse(map['watchedAt']),
      viewCount: map['viewCount'] ?? 0,
      playlistTitle: map['playlistTitle'],
      watchDurationInSeconds: map['watchDurationInSeconds'] ?? 0,
      totalDurationInSeconds: map['totalDurationInSeconds'] ?? 0,
      watchProgress: map['watchProgress']?.toDouble() ?? 0.0,
      lastPositionInSeconds: map['lastPositionInSeconds'] ?? 0,
    );
  }
  
  // Create an updated copy of this history item
  HistoryItem copyWith({
    String? videoId,
    String? title,
    String? thumbnailUrl,
    DateTime? watchedAt,
    int? viewCount,
    String? playlistTitle,
    int? watchDurationInSeconds,
    int? totalDurationInSeconds,
    double? watchProgress,
    int? lastPositionInSeconds,
  }) {
    return HistoryItem(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      watchedAt: watchedAt ?? this.watchedAt,
      viewCount: viewCount ?? this.viewCount,
      playlistTitle: playlistTitle ?? this.playlistTitle,
      watchDurationInSeconds: watchDurationInSeconds ?? this.watchDurationInSeconds,
      totalDurationInSeconds: totalDurationInSeconds ?? this.totalDurationInSeconds,
      watchProgress: watchProgress ?? this.watchProgress,
      lastPositionInSeconds: lastPositionInSeconds ?? this.lastPositionInSeconds,
    );
  }
}