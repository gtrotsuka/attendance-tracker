import 'package:firebase_database/firebase_database.dart';
import 'attendance_service.dart';

/// A debug version that skips Firebase sync to isolate issues
class DebugAttendanceService extends AttendanceService {
  static bool _isFirebaseAvailable = false;

  /// Initialize Firebase (but don't fail if it doesn't work)
  static Future<void> initializeFirebase() async {
    try {
      final database = FirebaseDatabase.instance;
      await database.goOnline();
      _isFirebaseAvailable = true;
      print('🔥 Firebase database initialized successfully');
    } catch (e) {
      _isFirebaseAvailable = false;
      print('⚠️  Firebase database initialization failed: $e');
    }
  }

  /// Process attendance with minimal Firebase interaction
  @override
  Future<String> processAttendance(String input, {bool isManual = false}) async {
    print('📝 [Debug] Processing attendance: $input');
    final result = await super.processAttendance(input, isManual: isManual);
    print('✅ [Debug] Attendance processed: $result');
    
    // Skip Firebase sync for now
    if (_isFirebaseAvailable) {
      print('🔥 [Debug] Firebase available but skipping sync');
    }
    
    return result;
  }

  /// Create event without Firebase sync
  @override
  Future<int> createEvent(String eventName) async {
    print('🎯 [Debug] Creating event: $eventName');
    
    try {
      final eventId = await super.createEvent(eventName);
      print('✅ [Debug] Event created successfully with ID: $eventId');
      
      // Skip Firebase sync for debugging
      if (_isFirebaseAvailable) {
        print('🔥 [Debug] Firebase available but skipping sync for debugging');
      }
      
      return eventId;
    } catch (e) {
      print('❌ [Debug] Event creation failed: $e');
      rethrow;
    }
  }

  /// Get Firebase connection status
  static bool get isFirebaseAvailable => _isFirebaseAvailable;
}
