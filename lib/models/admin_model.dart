class AdminModel {
  final String id;
  final String name;
  final String pinHash;
  final DateTime createdAt;

  const AdminModel({
    required this.id,
    required this.name,
    required this.pinHash,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'pin_hash': pinHash,
        'created_at': createdAt.toIso8601String(),
      };

  static AdminModel fromMap(Map<String, dynamic> map) => AdminModel(
        id: map['id'] as String,
        name: map['name'] as String,
        pinHash: map['pin_hash'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
