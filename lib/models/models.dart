class Student {
  final int? id;
  final String studentId;
  final String? name;
  final int totalPoints;
  final DateTime createdAt;

  Student({
    this.id,
    required this.studentId,
    this.name,
    this.totalPoints = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'name': name,
      'total_points': totalPoints,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      studentId: map['student_id'],
      name: map['name'],
      totalPoints: map['total_points'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Student copyWith({
    int? id,
    String? studentId,
    String? name,
    int? totalPoints,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      totalPoints: totalPoints ?? this.totalPoints,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Event {
  final int? id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;

  Event({
    this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      name: map['name'],
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      isActive: map['is_active'] == 1,
    );
  }

  Event copyWith({
    int? id,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    bool? isActive,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
    );
  }
}

class AttendanceRecord {
  final int? id;
  final String studentId;
  final int eventId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final int pointsEarned;
  final bool isManualEntry;

  AttendanceRecord({
    this.id,
    required this.studentId,
    required this.eventId,
    required this.checkInTime,
    this.checkOutTime,
    this.pointsEarned = 0,
    this.isManualEntry = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'event_id': eventId,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'points_earned': pointsEarned,
      'is_manual_entry': isManualEntry ? 1 : 0,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      studentId: map['student_id'],
      eventId: map['event_id'],
      checkInTime: DateTime.parse(map['check_in_time']),
      checkOutTime: map['check_out_time'] != null ? DateTime.parse(map['check_out_time']) : null,
      pointsEarned: map['points_earned'] ?? 0,
      isManualEntry: map['is_manual_entry'] == 1,
    );
  }

  AttendanceRecord copyWith({
    int? id,
    String? studentId,
    int? eventId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    int? pointsEarned,
    bool? isManualEntry,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      eventId: eventId ?? this.eventId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      isManualEntry: isManualEntry ?? this.isManualEntry,
    );
  }

  Duration? get duration {
    if (checkOutTime != null) {
      return checkOutTime!.difference(checkInTime);
    }
    return null;
  }

  bool get isCheckedOut => checkOutTime != null;
}