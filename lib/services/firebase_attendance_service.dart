import 'package:firebase_database/firebase_database.dart';
import '../models/models.dart';

class FirebaseAttendanceService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  String parseCardSwipe(String swipeData) {
    final regex = RegExp(r'=(\d+)='); 
    final match = regex.firstMatch(swipeData);
    if (match != null && match.groupCount > 0) {
      return match.group(1)!;
    }
    throw Exception('Invalid card swipe data format');
  }

  int calculatePoints(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 15) return 1;
    if (minutes < 30) return 3;
    if (minutes < 60) return 5;
    if (minutes < 120) return 8;
    return 10;
  }

  Future<Event?> getCurrentEvent() async {
    final snapshot = await _db.ref('events').orderByChild('isActive').equalTo(true).limitToLast(1).get();
    if (snapshot.exists && snapshot.children.isNotEmpty) {
      final data = snapshot.children.first.value as Map<dynamic, dynamic>;
      return Event.fromFirebaseMap(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<List<Student>> getLeaderboard() async {
    final snapshot = await _db.ref('students').get();
    if (!snapshot.exists) return [];
    return snapshot.children.map((snap) => Student.fromFirebaseMap(Map<String, dynamic>.from(snap.value as Map))).toList();
  }

  Future<List<AttendanceRecord>> getCurrentEventAttendance() async {
    final event = await getCurrentEvent();
    if (event == null || event.id == null) return [];
    final snapshot = await _db.ref('attendance/${event.id}').get();
    if (!snapshot.exists) return [];
    return snapshot.children.map((snap) => AttendanceRecord.fromFirebaseMap(Map<String, dynamic>.from(snap.value as Map))).toList();
  }

  Future<String> processAttendance(String input, {bool isManual = false}) async {
    String studentId;
    try {
      studentId = isManual ? input.trim() : parseCardSwipe(input);
    } catch (e) {
      return 'Error: Invalid input format';
    }

    final event = await getCurrentEvent();
    if (event == null || event.id == null) {
      return 'Error: No active event found';
    }

    final attendanceSnap = await _db.ref('attendance/${event.id}/$studentId').get();
    if (!attendanceSnap.exists) {
      // Check in
      final record = AttendanceRecord(
        studentId: studentId,
        eventId: event.id!,
        checkInTime: DateTime.now(),
        isManualEntry: isManual,
      );
      await _db.ref('attendance/${event.id}/$studentId').set(record.toFirebaseMap());
      return '$studentId checked in';
    } else {
      // Check out
      final record = AttendanceRecord.fromFirebaseMap(Map<String, dynamic>.from(attendanceSnap.value as Map));
      if (record.isCheckedOut) {
        return '$studentId already checked out';
      }
      final checkOutTime = DateTime.now();
      final duration = checkOutTime.difference(record.checkInTime);
      final points = calculatePoints(duration);
      final updated = record.copyWith(
        checkOutTime: checkOutTime,
        points: points,
      );
      await _db.ref('attendance/${event.id}/$studentId').set(updated.toFirebaseMap());
      // Update student points
      final studentSnap = await _db.ref('students/$studentId').get();
      int totalPoints = points;
      if (studentSnap.exists) {
        final student = Student.fromFirebaseMap(Map<String, dynamic>.from(studentSnap.value as Map));
        totalPoints += student.totalPoints;
      }
      await _db.ref('students/$studentId').set({
        'studentId': studentId,
        'totalPoints': totalPoints,
        'name': studentSnap.exists ? (studentSnap.value as Map)['name'] : null,
        'createdAt': studentSnap.exists ? (studentSnap.value as Map)['createdAt'] : DateTime.now().toIso8601String(),
      });
      return '$studentId checked out (+$points pts)';
    }
  }

  Future<String> createEvent(String eventName) async {
    // End any existing active events
    final eventsSnap = await _db.ref('events').orderByChild('isActive').equalTo(true).get();
    for (final snap in eventsSnap.children) {
      await _db.ref('events/${snap.key}').update({'isActive': false});
    }
    final newEventRef = _db.ref('events').push();
    final event = Event(
      id: newEventRef.key,
      name: eventName,
      date: DateTime.now(),
      isActive: true,
    );
    await newEventRef.set(event.toFirebaseMap());
    return event.name;
  }

  Future<void> endCurrentEvent() async {
    final event = await getCurrentEvent();
    if (event != null && event.id != null) {
      await _db.ref('events/${event.id}').update({'isActive': false});
    }
  }

  Future<void> deleteAttendanceRecord(String eventId, String studentId) async {
    await _db.ref('attendance/$eventId/$studentId').remove();
  }
}