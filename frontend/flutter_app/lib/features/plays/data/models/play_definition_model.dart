// lib/features/plays/data/models/play_definition_model.dart

import 'play_category_model.dart';

class PlayDefinition {
  final int id;
  final String name;
  final String? description;
  final String playType;
  final int teamId;
  final String? diagramUrl;
  final String? videoUrl;
  final int? parentId;
  final PlayCategory? category;
  final String? subcategory; 
  final String actionTypeString; 

  PlayDefinition({
    required this.id,
    required this.name,
    this.description,
    required this.playType,
    required this.teamId,
    this.diagramUrl,
    this.videoUrl,
    this.parentId,
    this.category,
    this.subcategory, 
    required this.actionTypeString,
  });

  factory PlayDefinition.fromJson(Map<String, dynamic> json) {
    return PlayDefinition(
      id: json['id'],
      name: json['name'] as String? ?? 'Unnamed Play',
      description: json['description'],
      playType: json['play_type'],
      teamId: json['team'],
      diagramUrl: json['diagram_url'],
      videoUrl: json['video_url'],
      parentId: json['parent'],
      category: json['category'] != null
          ? PlayCategory.fromJson(json['category'])
          : null,
      subcategory: json['subcategory'], // <-- FIX 3: Added parsing for subcategory
      // Parse the action_type string, providing 'NORMAL' as a safe default
      actionTypeString: json['action_type'] as String? ?? 'NORMAL', // <-- FIX 2
    );
  }
}