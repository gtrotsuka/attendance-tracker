import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'attendance_service.dart';

/// A simple Firebase-enabled attendance service that extends the local service
class SimpleFirebaseService extends AttendanceService {
  static FirebaseDatabase? _database;
  static bool _isFirebaseAvailable = false;
  static StreamSubscription<DatabaseEvent>? _eventListener;
  static StreamSubscription<DatabaseEvent>? _attendanceListener;
  static StreamSubscription<DatabaseEvent>? _leaderboardListener;
  static FirebaseDatabase? database;
  static bool isFirebaseAvailable = false;
  static StreamSubscription<DatabaseEvent>? eventListener;
  static StreamSubscription<DatabaseEvent>? attendanceListener;
  static StreamSubscription<DatabaseEvent>? leaderboardListener;

  /// Check if Firebase is available and initialize database reference
  static Future<void> initializeFirebase() async {
    try {
      _database = FirebaseDatabase.instance;
      await _database!.goOnline();
      _isFirebaseAvailable = true;
      database = FirebaseDatabase.instance;
      await database!.goOnline();
      isFirebaseAvailable = true;
      print('🔥 Firebase database initialized successfully');
      // Start listening for real-time updates
      _startRealtimeListeners();
    } catch (e) {
      _isFirebaseAvailable = false;
      print('⚠️  Firebase database initialization failed: $e');
    }
  }
  /// Start real-time listeners for events, attendance, and leaderboard
  static void _startRealtimeListeners() {
    // Listen for event changes
    _eventListener?.cancel();
    _eventListener = _database?.ref('events').onValue.listen((event) {
      // TODO: Parse event.snapshot.value and update local cache/state
      print('🔄 [Firebase] Events updated: ${event.snapshot.value}');
    });
    eventListener?.cancel();
    eventListener = database?.ref('events').onValue.listen((event) {
      // TODO: Parse event.snapshot.value and update local cache/state
      print('🔄 [Firebase] Events updated: ${event.snapshot.value}');
    });

    _attendanceListener?.cancel();
    _attendanceListener = _database?.ref('attendance').onValue.listen((event) {
      // TODO: Parse event.snapshot.value and update local cache/state
      print('🔄 [Firebase] Attendance updated: ${event.snapshot.value}');
    });
    attendanceListener?.cancel();
    attendanceListener = database?.ref('attendance').onValue.listen((event) {
      // TODO: Parse event.snapshot.value and update local cache/state
      print('🔄 [Firebase] Attendance updated: ${event.snapshot.value}');
    });

    _leaderboardListener?.cancel();
    _leaderboardListener = _database?.ref('students').onValue.listen((event) {
      // TODO: Parse event.snapshot.value and update local cache/state
      print('🔄 [Firebase] Leaderboard updated: ${event.snapshot.value}');
    });
    leaderboardListener?.cancel();
    leaderboardListener = database?.ref('students').onValue.listen((event) {
      // TODO: Parse event.snapshot.value and update local cache/state
      print('🔄 [Firebase] Leaderboard updated: ${event.snapshot.value}');
    });
  }

  /// Process attendance with Firebase sync
  @override
  Future<String> processAttendance(String input, {bool isManual = false}) async {
    // Process locally first
    final result = await super.processAttendance(input, isManual: isManual);
    
    // Fire and forget Firebase sync - don't wait for it
    if (_isFirebaseAvailable && _database != null) {
      _syncToFirebaseAsync();
    }
    
    return result;
  }

  /// Create event with Firebase sync
  @override
  Future<int> createEvent(String eventName) async {
    // Create event locally first
    final eventId = await super.createEvent(eventName);
    
    // Fire and forget Firebase sync - don't wait for it
    if (_isFirebaseAvailable && _database != null) {
      _syncToFirebaseAsync();
    }
    
    return eventId;
  }

  /// Async Firebase sync that doesn't block the UI
  void _syncToFirebaseAsync() {
    // Run sync in background without blocking
    _syncToFirebase().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('⏰ [Firebase] Background sync timeout');
      },
    ).catchError((e) {
      print('⚠️  [Firebase] Background sync failed: $e');
    });
  }

  /// Sync current data to Firebase
  Future<void> _syncToFirebase() async {
    if (!_isFirebaseAvailable || _database == null) return;

    try {
      final currentEvent = await getCurrentEvent();
      if (currentEvent == null) return;

      // Sync event data
      await _database!.ref('events/${currentEvent.id}').set({
        'name': currentEvent.name,
        'date': currentEvent.date.toIso8601String(),
        'isActive': true,
      });

      // Sync attendance records
      final attendance = await getCurrentEventAttendance();
      for (final record in attendance) {
        await _database!.ref('attendance/${currentEvent.id}/${record.studentId}').set({
          'studentId': record.studentId,
          'checkInTime': record.checkInTime.toIso8601String(),
          'checkOutTime': record.checkOutTime?.toIso8601String(),
          'isCheckedOut': record.isCheckedOut,
          'isManualEntry': record.isManualEntry,
          'points': record.points,
        });
      }

      // Sync leaderboard
      final leaderboard = await getLeaderboard();
      for (final student in leaderboard) {
        await _database!.ref('students/${student.studentId}').set({
          'studentId': student.studentId,
          'name': student.name,
          'totalPoints': student.totalPoints,
        });
      }

      print('✅ Data synced to Firebase successfully');
    } catch (e) {
      print('❌ Firebase sync error: $e');
      rethrow;
    }
  }

  /// Get Firebase connection status
  /// Dispose listeners when no longer needed
  static void disposeListeners() {
    _eventListener?.cancel();
    _attendanceListener?.cancel();
    _leaderboardListener?.cancel();
    eventListener?.cancel();
    attendanceListener?.cancel();
    leaderboardListener?.cancel();
    eventListener?.cancel();
    attendanceListener?.cancel();
    leaderboardListener?.cancel();
  }
}
