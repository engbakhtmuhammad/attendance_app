class AttendanceModel {
  final String id;
  final String userId;
  final String deviceId;
  final String classId;
  final DateTime timestamp;

  const AttendanceModel({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.classId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'device_id': deviceId,
        'class_id': classId,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AttendanceModel.fromMap(Map<String, dynamic> map) => AttendanceModel(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        deviceId: map['device_id'] as String,
        classId: map['class_id'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
}
