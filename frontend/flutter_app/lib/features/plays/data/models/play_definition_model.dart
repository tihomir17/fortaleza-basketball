// lib/features/plays/data/models/play_definition_model.dart

class PlayDefinition {
  final int id;
  final String name;
  final String? description;
  final String playType; // 'OFFENSIVE' or 'DEFENSIVE'
  final int teamId;
  final String? diagramUrl;
  final String? videoUrl;
  final int? parentId;

  PlayDefinition({
    required this.id,
    required this.name,
    this.description,
    required this.playType,
    required this.teamId,
    this.diagramUrl,
    this.videoUrl,
    this.parentId,
  });

  factory PlayDefinition.fromJson(Map<String, dynamic> json) {
    return PlayDefinition(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      playType: json['play_type'],
      teamId: json['team'], // Assuming the API returns the team ID directly
      diagramUrl: json['diagram_url'],
      videoUrl: json['video_url'],
      parentId: json['parent'],
    );
  }
}