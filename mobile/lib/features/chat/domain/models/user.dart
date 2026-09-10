class User {
  final String id;
  final String username;
  final String? email;
  final String? name;
  final String? bio;
  final String? avatarUrl;

  User({
    required this.id,
    required this.username,
    this.email,
    this.name,
    this.bio,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
