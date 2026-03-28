class ReelItem {
  final int reelId;
  final String creator;
  final String caption;
  final String assetPath;
  final String videoUrl;
  final int likeCount;
  final int commentCount;

  const ReelItem({
    required this.reelId,
    required this.creator,
    required this.caption,
    required this.assetPath,
    required this.videoUrl,
    required this.likeCount,
    required this.commentCount,
  });

  factory ReelItem.fromJson(Map<String, dynamic> json) {
    return ReelItem(
      reelId: (json['reel_id'] as num?)?.toInt() ?? 0,
      creator: (json['creator'] ?? 'user_unknown') as String,
      caption: (json['caption'] ?? 'No caption') as String,
      assetPath: (json['asset_path'] ?? 'assets/videos/reel1.mp4') as String,
      videoUrl: (json['video_url'] ?? '') as String,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
    );
  }
}
