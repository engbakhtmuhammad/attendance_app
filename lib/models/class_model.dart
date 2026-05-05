class ClassModel {
  final String id;
  final String name;
  final String date; // yyyy-MM-dd
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final bool isActive;
  final String? sessionToken;
  final DateTime createdAt;

  const ClassModel({
    required this.id,
    required this.name,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    this.sessionToken,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'is_active': isActive ? 1 : 0,
        'session_token': sessionToken,
        'created_at': createdAt.toIso8601String(),
      };

  factory ClassModel.fromMap(Map<String, dynamic> map) => ClassModel(
        id: map['id'] as String,
        name: map['name'] as String,
        date: map['date'] as String,
        startTime: map['start_time'] as String,
        endTime: map['end_time'] as String,
        isActive: (map['is_active'] as int) == 1,
        sessionToken: map['session_token'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  ClassModel copyWith({
    String? id,
    String? name,
    String? date,
    String? startTime,
    String? endTime,
    bool? isActive,
    String? sessionToken,
    DateTime? createdAt,
  }) =>
      ClassModel(
        id: id ?? this.id,
        name: name ?? this.name,
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        isActive: isActive ?? this.isActive,
        sessionToken: sessionToken ?? this.sessionToken,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Check if the given time (HH:mm) is within the class time window
  bool isTimeWithinWindow(String currentTime) {
    final now = _parseTime(currentTime);
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    return now >= start && now <= end;
  }

  int _parseTime(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
