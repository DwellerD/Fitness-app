class User {
  final String id;
  final String email;
  final String? name;
  final String createdAt;
  final Map<String, dynamic> prefs;
  final String? passwordHash;

  User({
    required this.id,
    required this.email,
    this.name,
    required this.createdAt,
    required this.prefs,
    this.passwordHash,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
      createdAt: map['created_at'] as String,
      prefs: map['prefs'] != null 
          ? Map<String, dynamic>.from(map['prefs'] as Map)
          : {},
      passwordHash: map['password_hash'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'created_at': createdAt,
      'prefs': prefs,
      'password_hash': passwordHash,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? createdAt,
    Map<String, dynamic>? prefs,
    String? passwordHash,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      prefs: prefs ?? this.prefs,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }
}
