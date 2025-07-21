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

  Map<String, dynamic> toFirebaseMap() {
    return {
      'name': name,
      'totalPoints': totalPoints,
      'createdAt': createdAt.toIso8601String(),
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

  factory Student.fromFirebaseMap(Map<String, dynamic> map) {
    return Student(
      id: null, // Firebase uses string keys, not integer IDs
      studentId: map['studentId'] ?? '',
      name: map['name'],
      totalPoints: map['totalPoints'] ?? 0,
      createdAt: map['createdAt'] != null 
        ? DateTime.parse(map['createdAt']) 
        : DateTime.now(),
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
  final String? id; // Firebase uses string IDs
  final String name;
  final String? description;
  final DateTime date;
  final bool isActive;

  Event({
    this.id,
    required this.name,
    this.description,
    required this.date,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date.toIso8601String().split('T').first,
      'is_active': isActive ? 1 : 0,
    };
  }

  Map<String, dynamic> toFirebaseMap() {
    return {
      'name': name,
      'description': description,
      'date': date.toIso8601String().split('T').first,
      'isActive': isActive,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id']?.toString(),
      name: map['name'],
      description: map['description'],
      date: DateTime.parse('${map['date']}T00:00:00.000Z'),
      isActive: map['is_active'] == 1,
    );
  }

  factory Event.fromFirebaseMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      date: DateTime.parse('${map['date']}T00:00:00.000Z'),
      isActive: map['isActive'] == true,
    );
  }

  Event copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? date,
    bool? isActive,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      date: date ?? this.date,
      isActive: isActive ?? this.isActive,
    );
  }
}

class AttendanceRecord {
  final String? id; // Firebase uses string IDs
  final String studentId;
  final String eventId; // Firebase event IDs are strings
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final int points;
  final bool isManualEntry;

  AttendanceRecord({
    this.id,
    required this.studentId,
    required this.eventId,
    required this.checkInTime,
    this.checkOutTime,
    this.points = 0,
    this.isManualEntry = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'event_id': eventId,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'points_earned': points,
      'is_manual_entry': isManualEntry ? 1 : 0,
    };
  }

  Map<String, dynamic> toFirebaseMap() {
    return {
      'studentId': studentId,
      'eventId': eventId,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'points': points,
      'isManualEntry': isManualEntry,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id']?.toString(),
      studentId: map['student_id'],
      eventId: map['event_id']?.toString() ?? '',
      checkInTime: DateTime.parse(map['check_in_time']),
      checkOutTime: map['check_out_time'] != null ? DateTime.parse(map['check_out_time']) : null,
      points: map['points_earned'] ?? 0,
      isManualEntry: map['is_manual_entry'] == 1,
    );
  }

  factory AttendanceRecord.fromFirebaseMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      studentId: map['studentId'],
      eventId: map['eventId'],
      checkInTime: DateTime.parse(map['checkInTime']),
      checkOutTime: map['checkOutTime'] != null ? DateTime.parse(map['checkOutTime']) : null,
      points: map['points'] ?? 0,
      isManualEntry: map['isManualEntry'] == true,
    );
  }

  AttendanceRecord copyWith({
    String? id,
    String? studentId,
    String? eventId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    int? points,
    bool? isManualEntry,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      eventId: eventId ?? this.eventId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      points: points ?? this.points,
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