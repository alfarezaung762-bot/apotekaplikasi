class User {
  final String id;
  final String name;
  final String email;
  final String role; // patient, doctor, pharmacy, admin
  final String? avatar;
  final String? phone;
  final String? password;
  final String createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    this.phone,
    this.password,
    this.createdAt = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: (json['role'] ?? 'patient').toString().toLowerCase(),
      avatar: json['avatar'],
      phone: json['phone'],
      password: json['password'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'avatar': avatar,
    'phone': phone,
    'password': password,
    'createdAt': createdAt,
  };

  String get initials {
    final parts = name.split(' ').where((n) => !n.startsWith('Dr')).toList();
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
