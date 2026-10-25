class PlaylistModel {
  final String id;
  final String name;
  final int createdAt;
  final int colorAccent;
  final String? description;
  final int trackCount;

  const PlaylistModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.colorAccent,
    this.description,
    this.trackCount = 0,
  });

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] as int,
      colorAccent: map['color_accent'] as int,
      description: map['description'] as String?,
      trackCount: map['track_count'] as int? ?? 0,
    );
  }
}
