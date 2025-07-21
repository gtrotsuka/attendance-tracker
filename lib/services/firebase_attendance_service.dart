import '../models/models.dart';
import 'firebase_service.dart';
import 'database_service.dart';

class AttendanceService {
  final DatabaseService _db = DatabaseService();

  // Parse card swipe data to extract student ID
  String parseCardSwipe(String swipeData) {
    // For input like ";1570=903774061=00=6017700007279520?"
    // Extract the ID number (903774061) which is between the first two = signs
    final regex = RegExp(r'=(\d+)=');
    final match = regex.firstMatch(swipeData);
    if (match != null && match.groupCount > 0) {
      return match.group(1)!;
    }
    throw Exception('Invalid card swipe data format');
  }

  // Calculate points based on attendance duration
  int calculatePoints(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 15) return 1; // Minimum attendance
    if (minutes < 30) return 3;
    if (minutes < 60) return 5;
    if (minutes < 120) return 8;
    return 10; // Maximum points for 2+ hours
  }

  // Process check-in or check-out
  Future<String> processAttendance(String input, {bool isManual = false}) async {
    String studentId;
    
    try {
      if (isManual) {
        studentId = input.trim();
      } else {
        studentId = parseCardSwipe(input);
      }
    } catch (e) {
      return 'Error: Invalid input format';
    }

    // Try Firebase first
    if (FirebaseService.isAvailable) {
      try {
        final activeEvent = await FirebaseService.getActiveEvent();
        if (activeEvent == null) {
          return 'Error: No active event found';
        }

        // Check if student is already checked in
        final activeRecord = await FirebaseService.getActiveAttendanceRecord(
          studentId, 
          activeEvent.id!
        );

        if (activeRecord == null) {
          // Check in
          await FirebaseService.saveStudent(Student(studentId: studentId));
          
          final record = AttendanceRecord(
            studentId: studentId,
            eventId: activeEvent.id!,
            checkInTime: DateTime.now(),
            isManualEntry: isManual,
          );
          
          await FirebaseService.saveAttendanceRecord(record);
          return '$studentId checked in';
        } else {
          // Check out
          final checkOutTime = DateTime.now();
          final duration = checkOutTime.difference(activeRecord.checkInTime);
          final points = calculatePoints(duration);
          
          final updatedRecord = activeRecord.copyWith(
            checkOutTime: checkOutTime,
            points: points,
          );
          
          await FirebaseService.updateAttendanceRecord(activeRecord.id!, updatedRecord);
          
          // Update student total points
          final student = await FirebaseService.getStudent(studentId);
          if (student != null) {
            final updatedStudent = student.copyWith(
              totalPoints: student.totalPoints + points,
            );
            await FirebaseService.saveStudent(updatedStudent);
          }
          
          final durationText = '${duration.inMinutes} min';
          return '$studentId checked out ($durationText, +$points pts)';
        }
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
      }
    }

    // Fallback to local storage
    try {
      // Get or create student
      Student? student = await _db.getStudent(studentId);
      if (student == null) {
        student = Student(studentId: studentId);
        await _db.insertStudent(student);
      }

      // Get active event
      Event? activeEvent = await _db.getActiveEvent();
      if (activeEvent == null) {
        return 'Error: No active event found';
      }

      // Check if student is already checked in
      AttendanceRecord? activeRecord = await _db.getActiveAttendanceRecord(
        studentId, 
        int.parse(activeEvent.id!.replaceAll(RegExp(r'[^0-9]'), '')) // Convert string ID to int
      );

      if (activeRecord == null) {
        // Check in
        final record = AttendanceRecord(
          studentId: studentId,
          eventId: activeEvent.id!.toString(),
          checkInTime: DateTime.now(),
          isManualEntry: isManual,
        );
        await _db.insertAttendanceRecord(record);
        
        final displayName = student.name ?? studentId;
        return '$displayName checked in';
      } else {
        // Check out
        final checkOutTime = DateTime.now();
        final duration = checkOutTime.difference(activeRecord.checkInTime);
        final points = calculatePoints(duration);
        
        await _db.updateCheckOut(activeRecord.id!, checkOutTime, points);
        
        // Update student total points
        final totalPoints = await _db.calculateTotalPoints(studentId);
        await _db.updateStudentPoints(studentId, totalPoints);
        
        final displayName = student.name ?? studentId;
        final durationText = '${duration.inMinutes} min';
        return '$displayName checked out ($durationText, +$points pts)';
      }
    } catch (e) {
      print('Local storage error: $e');
      return 'Error: Failed to process attendance - $e';
    }
  }

  // Create a new event
  Future<int> createEvent(String eventName) async {
    // Try Firebase first
    if (FirebaseService.isAvailable) {
      try {
        final event = Event(
          name: eventName,
          date: DateTime.now(),
          isActive: true,
        );
        
        final eventId = await FirebaseService.createEvent(event);
        return eventId.hashCode; // Convert string to int for compatibility
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
      }
    }

    // Fallback to local storage
    // End any existing active events
    final activeEvent = await _db.getActiveEvent();
    if (activeEvent != null) {
      await _db.endEvent(activeEvent.id!);
    }

    final event = Event(
      name: eventName,
      date: DateTime.now(),
    );
    return await _db.insertEvent(event);
  }

  // Get leaderboard
  Future<List<Student>> getLeaderboard() async {
    // Try Firebase first
    if (FirebaseService.isAvailable) {
      try {
        return await FirebaseService.getLeaderboard();
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
      }
    }

    // Fallback to local storage
    return await _db.getAllStudents();
  }

  // Get attendance records for current event
  Future<List<AttendanceRecord>> getCurrentEventAttendance() async {
    // Try Firebase first
    if (FirebaseService.isAvailable) {
      try {
        final activeEvent = await FirebaseService.getActiveEvent();
        if (activeEvent != null) {
          return await FirebaseService.getEventAttendance(activeEvent.id!);
        }
        return [];
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
      }
    }

    // Fallback to local storage
    final activeEvent = await _db.getActiveEvent();
    if (activeEvent == null) return [];
    return await _db.getAttendanceRecords(activeEvent.id!);
  }

  // Get all attendance records
  Future<List<AttendanceRecord>> getAllAttendanceRecords() async {
    return await _db.getAllAttendanceRecords();
  }

  // Delete attendance record
  Future<void> deleteAttendanceRecord(int recordId, String studentId) async {
    await _db.deleteAttendanceRecord(recordId);
    
    // Recalculate student points
    final totalPoints = await _db.calculateTotalPoints(studentId);
    await _db.updateStudentPoints(studentId, totalPoints);
  }

  // Get current active event
  Future<Event?> getCurrentEvent() async {
    // Try Firebase first
    if (FirebaseService.isAvailable) {
      try {
        return await FirebaseService.getActiveEvent();
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
      }
    }

    // Fallback to local storage
    return await _db.getActiveEvent();
  }

  // End current event
  Future<void> endCurrentEvent() async {
    // Try Firebase first
    if (FirebaseService.isAvailable) {
      try {
        final activeEvent = await FirebaseService.getActiveEvent();
        if (activeEvent != null) {
          // Deactivate all events in Firebase
          await FirebaseService.createEvent(activeEvent.copyWith(isActive: false));
        }
        return;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
      }
    }

    // Fallback to local storage
    final activeEvent = await _db.getActiveEvent();
    if (activeEvent != null) {
      await _db.endEvent(activeEvent.id!);
    }
  }

  // Update student name (for when roster is imported)
  Future<void> updateStudentName(String studentId, String name) async {
    // Try Firebase first
    if (FirebaseService.isAvailable) {
      try {
        final student = await FirebaseService.getStudent(studentId);
        if (student != null) {
          await FirebaseService.saveStudent(student.copyWith(name: name));
        }
        return;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
      }
    }

    // Fallback to local storage
    final student = await _db.getStudent(studentId);
    if (student != null) {
      final updatedStudent = student.copyWith(name: name);
      await _db.insertStudent(updatedStudent);
    }
  }

  // Get student display name
  Future<String> getStudentDisplayName(String studentId) async {
    // Try Firebase first
    if (FirebaseService.isAvailable) {
      try {
        final student = await FirebaseService.getStudent(studentId);
        return student?.name ?? studentId;
      } catch (e) {
        print('Firebase error, falling back to local storage: $e');
      }
    }

    // Fallback to local storage
    final student = await _db.getStudent(studentId);
    return student?.name ?? studentId;
  }

  // Get connection status
  bool get isConnected => FirebaseService.isAvailable;

  // Get realtime streams (Firebase only)
  Stream<List<Student>> watchLeaderboard({int limit = 10}) {
    if (FirebaseService.isAvailable) {
      return FirebaseService.watchLeaderboard(limit: limit);
    }
    return Stream.value([]);
  }

  Stream<List<AttendanceRecord>> watchCurrentEventAttendance() {
    if (FirebaseService.isAvailable) {
      return FirebaseService.getActiveEvent().asStream().asyncExpand((event) {
        if (event != null) {
          return FirebaseService.watchEventAttendance(event.id!);
        }
        return Stream.value(<AttendanceRecord>[]);
      });
    }
    return Stream.value([]);
  }

  Stream<bool> watchConnectionStatus() {
    if (FirebaseService.isAvailable) {
      return FirebaseService.watchConnectionStatus();
    }
    return Stream.value(false);
  }
}
