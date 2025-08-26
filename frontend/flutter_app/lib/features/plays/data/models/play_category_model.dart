// lib/features/plays/data/models/play_category_model.dart
class PlayCategory {
  final int id;
  final String name;
  final String? description;

  PlayCategory({required this.id, required this.name, this.description});

  factory PlayCategory.fromJson(Map<String, dynamic> json) {
    return PlayCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}
