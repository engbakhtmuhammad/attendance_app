class UserModel {
  final String id;
  final String name;
  final String passwordHash;
  final String? deviceId;
  final String status; // pending | approved | blocked
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.passwordHash,
    this.deviceId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'password_hash': passwordHash,
        'device_id': deviceId,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as String,
        name: map['name'] as String,
        passwordHash: map['password_hash'] as String,
        deviceId: map['device_id'] as String?,
        status: map['status'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  UserModel copyWith({
    String? id,
    String? name,
    String? passwordHash,
    String? deviceId,
    String? status,
    DateTime? createdAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        passwordHash: passwordHash ?? this.passwordHash,
        deviceId: deviceId ?? this.deviceId,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
}
