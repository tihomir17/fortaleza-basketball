// lib/features/authentication/data/models/user_model.dart

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? coachType; // Can be null
  final int? jerseyNumber; 

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.coachType,
    this.jerseyNumber,
  });

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    // If the full name is empty, fall back to the username.
    return fullName.isNotEmpty ? fullName : username;
  }

  // A factory constructor for creating a new User instance from a map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'],
      // Ensure coach_type is handled correctly if it's null or missing
      coachType: json['coach_type'] == 'NONE' ? null : json['coach_type'],
      jerseyNumber: json['jersey_number'],
    );
  }
}
