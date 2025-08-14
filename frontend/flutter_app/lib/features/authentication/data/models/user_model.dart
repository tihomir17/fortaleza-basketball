// lib/features/authentication/data/models/user_model.dart

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? coachType; // Can be null

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.coachType,
  });

  // A factory constructor for creating a new User instance from a map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'] ?? '', // Handle potential nulls from API
      lastName: json['last_name'] ?? '', // Handle potential nulls from API
      role: json['role'],
      coachType: json['coach_type'],
    );
  }
}
