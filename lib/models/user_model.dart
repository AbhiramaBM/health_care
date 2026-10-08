class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? role;
  final String? avatarUrl;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.role,
    this.avatarUrl,
    this.metadata,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? json['fullName'],
      email: json['email'],
      phone: json['phone'] ?? json['phoneNumber'],
      role: json['role'] ?? 'staff',
      avatarUrl: json['avatarUrl'] ?? json['avatar'],
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'avatarUrl': avatarUrl,
      if (metadata != null) 'metadata': metadata,
    };
  }
}
