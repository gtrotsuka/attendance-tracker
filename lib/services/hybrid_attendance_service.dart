import 'dart:async';
import '../models/models.dart';
import 'attendance_service.dart';
import 'firebase_service.dart';

/// Hybrid service that uses Firebase when available, falls back to local storage
class HybridAttendanceService {
  final AttendanceService _localService;
  Timer? _syncTimer;
  bool _isOnline = false;

  HybridAttendanceService(this._localService);

  Future<void> initialize() async {
    // Initialize Firebase
    await FirebaseService.initialize();
    
    // Monitor connection status
    FirebaseService.watchConnectionStatus().listen((isOnline) {
      _isOnline = isOnline;
      if (isOnline) {
        _schedulePendingSync();
      }
    });

    // Sync data every 30 seconds when online
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isOnline && FirebaseService.isAvailable) {
        _syncWithFirebase();
      }
    });
  }

  void dispose() {
    _syncTimer?.cancel();
  }

  // Attendance processing - this is the main interface used by the app
  Future<String> processAttendance(String input, {bool isManual = false}) async {
    // Process locally first for immediate response
    final localResult = await _localService.processAttendance(input, isManual: isManual);
    
    // Try to sync to Firebase in the background
    if (FirebaseService.isAvailable) {
      _syncAttendanceToFirebase(input, isManual);
    }
    
    return localResult;
  }

  // Create a new event
  Future<int> createEvent(String eventName) async {
    // Create locally first
    final eventId = await _localService.createEvent(eventName);
    
    // Try to create in Firebase too
    if (FirebaseService.isAvailable) {
      try {
        final firebaseEvent = Event(
          name: eventName,
          description: 'Event created: ${DateTime.now().toString()}',
          date: DateTime.now(),
          isActive: true,
        );
        final firebaseId = await FirebaseService.createEvent(firebaseEvent);
        print('Event created in Firebase with ID: $firebaseId');
      } catch (e) {
        print('Firebase createEvent failed: $e');
      }
    }
    
    return eventId;
  }

  // Get leaderboard with Firebase fallback
  Future<List<Student>> getLeaderboard() async {
    // Try Firebase first for real-time data
    if (FirebaseService.isAvailable) {
      try {
        final firebaseLeaderboard = await FirebaseService.getLeaderboard();
        if (firebaseLeaderboard.isNotEmpty) {
          return firebaseLeaderboard;
        }
      } catch (e) {
        print('Firebase getLeaderboard failed: $e');
      }
    }

    // Fall back to local
    return await _localService.getLeaderboard();
  }

  Stream<List<Student>> watchLeaderboard() {
    if (FirebaseService.isAvailable) {
      return FirebaseService.watchLeaderboard();
    }
    
    // For local service, return a single snapshot
    return _localService.getLeaderboard().asStream();
  }

  // Get current event
  Future<Event?> getCurrentEvent() async {
    // Try Firebase first
    if (FirebaseService.isAvailable) {
      try {
        final firebaseEvent = await FirebaseService.getActiveEvent();
        if (firebaseEvent != null) {
          return firebaseEvent;
        }
      } catch (e) {
        print('Firebase getCurrentEvent failed: $e');
      }
    }

    // Fall back to local
    return await _localService.getCurrentEvent();
  }

  // Get current event attendance
  Future<List<AttendanceRecord>> getCurrentEventAttendance() async {
    final currentEvent = await getCurrentEvent();
    if (currentEvent == null) return [];

    // Try Firebase first
    if (FirebaseService.isAvailable && currentEvent.id != null) {
      try {
        final firebaseRecords = await FirebaseService.getEventAttendance(currentEvent.id!);
        if (firebaseRecords.isNotEmpty) {
          return firebaseRecords;
        }
      } catch (e) {
        print('Firebase getCurrentEventAttendance failed: $e');
      }
    }

    // Fall back to local
    return await _localService.getCurrentEventAttendance();
  }

  Stream<List<AttendanceRecord>> watchCurrentEventAttendance() async* {
    final currentEvent = await getCurrentEvent();
    if (currentEvent == null) {
      yield [];
      return;
    }

    if (FirebaseService.isAvailable && currentEvent.id != null) {
      yield* FirebaseService.watchEventAttendance(currentEvent.id!);
    } else {
      yield await _localService.getCurrentEventAttendance();
    }
  }

  // Delegate other methods to local service
  Future<List<AttendanceRecord>> getAllAttendanceRecords() => _localService.getAllAttendanceRecords();
  Future<void> deleteAttendanceRecord(int recordId, String studentId) => _localService.deleteAttendanceRecord(recordId, studentId);
  Future<void> endCurrentEvent() => _localService.endCurrentEvent();
  Future<void> updateStudentName(String studentId, String name) => _localService.updateStudentName(studentId, name);
  Future<String> getStudentDisplayName(String studentId) => _localService.getStudentDisplayName(studentId);

  // Background sync to Firebase
  Future<void> _syncAttendanceToFirebase(String input, bool isManual) async {
    try {
      // Parse the input to get student ID
      String studentId;
      if (isManual) {
        studentId = input.trim();
      } else {
        studentId = _localService.parseCardSwipe(input);
      }

      // Get or create student in Firebase
      var student = await FirebaseService.getStudent(studentId);
      if (student == null) {
        student = Student(studentId: studentId, name: studentId);
        await FirebaseService.saveStudent(student);
      }

      // Get active event from Firebase
      var activeEvent = await FirebaseService.getActiveEvent();
      if (activeEvent == null) {
        // Create a default event if none exists
        activeEvent = Event(
          name: 'Default Event',
          description: 'Auto-created event',
          date: DateTime.now(),
          isActive: true,
        );
        await FirebaseService.createEvent(activeEvent);
      }

      // Check if already checked in
      final activeRecord = await FirebaseService.getActiveAttendanceRecord(studentId, activeEvent.id!);
      
      if (activeRecord == null) {
        // Check in
        final record = AttendanceRecord(
          studentId: studentId,
          eventId: activeEvent.id!,
          checkInTime: DateTime.now(),
          points: 1,
          isManualEntry: isManual,
        );
        await FirebaseService.saveAttendanceRecord(record);
      } else {
        // Check out
        final checkOutTime = DateTime.now();
        final duration = checkOutTime.difference(activeRecord.checkInTime);
        final points = _calculatePoints(duration);
        
        final updatedRecord = activeRecord.copyWith(
          checkOutTime: checkOutTime,
          points: points,
        );
        await FirebaseService.updateAttendanceRecord(activeRecord.id!, updatedRecord);
        
        // Update student points
        final updatedStudent = student.copyWith(totalPoints: student.totalPoints + points);
        await FirebaseService.saveStudent(updatedStudent);
      }
    } catch (e) {
      print('Background sync to Firebase failed: $e');
    }
  }

  // Sync existing data to Firebase
  Future<void> _syncWithFirebase() async {
    if (!FirebaseService.isAvailable) return;

    try {
      print('Syncing data with Firebase...');
      
      // Get local leaderboard and sync to Firebase
      final localStudents = await _localService.getLeaderboard();
      for (final student in localStudents) {
        final firebaseStudent = await FirebaseService.getStudent(student.studentId);
        if (firebaseStudent == null || firebaseStudent.totalPoints < student.totalPoints) {
          await FirebaseService.saveStudent(student);
        }
      }
      
      print('Sync completed');
    } catch (e) {
      print('Sync with Firebase failed: $e');
    }
  }

  void _schedulePendingSync() {
    Timer(const Duration(seconds: 2), () {
      _syncWithFirebase();
    });
  }

  int _calculatePoints(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 15) return 1;
    if (minutes < 30) return 3;
    if (minutes < 60) return 5;
    if (minutes < 120) return 8;
    return 10;
  }

  // Connection status
  bool get isOnline => _isOnline;
  bool get hasFirebase => FirebaseService.isAvailable;
  
  Stream<bool> watchConnectionStatus() {
    if (FirebaseService.isAvailable) {
      return FirebaseService.watchConnectionStatus();
    }
    return Stream.value(false);
  }
}
