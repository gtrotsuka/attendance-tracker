import 'package:firebase_database/firebase_database.dart';
import '../models/models.dart';

class FirebaseService {
  static FirebaseDatabase? _database;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Firebase should already be initialized in main.dart
      // Just get the database instance
      _database = FirebaseDatabase.instance;
      
      // Enable offline persistence for better UX
      _database!.setPersistenceEnabled(true);
      
      print('✅ Firebase initialized successfully');
      _initialized = true;
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      print('Will fall back to local storage only');
      // Don't throw - we'll handle this gracefully by falling back to local storage
    }
  }

  static bool get isAvailable => _initialized && _database != null;

  // Students
  static Future<void> saveStudent(Student student) async {
    if (!isAvailable) return;
    
    try {
      await _database!
          .ref('students/${student.studentId}')
          .set({
            'name': student.name,
            'totalPoints': student.totalPoints,
            'createdAt': student.createdAt.toIso8601String(),
          });
    } catch (e) {
      print('Error saving student: $e');
      rethrow;
    }
  }

  static Future<Student?> getStudent(String studentId) async {
    if (!isAvailable) return null;
    
    try {
      final snapshot = await _database!
          .ref('students/$studentId')
          .get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return Student(
          studentId: studentId,
          name: data['name'],
          totalPoints: data['totalPoints'] ?? 0,
          createdAt: data['createdAt'] != null 
            ? DateTime.parse(data['createdAt']) 
            : DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      print('Error getting student: $e');
      return null;
    }
  }

  static Future<List<Student>> getLeaderboard({int limit = 10}) async {
    if (!isAvailable) return [];
    
    try {
      final snapshot = await _database!
          .ref('students')
          .orderByChild('totalPoints')
          .limitToLast(limit)
          .get();
      
      if (snapshot.exists) {
        final students = <Student>[];
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        for (final entry in data.entries) {
          final studentData = Map<String, dynamic>.from(entry.value as Map);
          students.add(Student(
            studentId: entry.key,
            name: studentData['name'],
            totalPoints: studentData['totalPoints'] ?? 0,
            createdAt: studentData['createdAt'] != null 
              ? DateTime.parse(studentData['createdAt']) 
              : DateTime.now(),
          ));
        }
        
        // Sort by points descending (Firebase sorts ascending)
        students.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
        return students;
      }
      return [];
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }

  // Events
  static Future<String> createEvent(Event event) async {
    if (!isAvailable) throw Exception('Firebase not available');
    
    try {
      // First, deactivate all existing events if this one should be active
      if (event.isActive) {
        await _deactivateAllEvents();
      }
      
      final ref = _database!.ref('events').push();
      await ref.set({
        'name': event.name,
        'description': event.description,
        'date': event.date.toIso8601String().split('T').first,
        'isActive': event.isActive,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      return ref.key!;
    } catch (e) {
      print('Error creating event: $e');
      rethrow;
    }
  }

  static Future<Event?> getActiveEvent() async {
    if (!isAvailable) return null;
    
    try {
      final snapshot = await _database!
          .ref('events')
          .orderByChild('isActive')
          .equalTo(true)
          .limitToFirst(1)
          .get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final entry = data.entries.first;
        final eventData = Map<String, dynamic>.from(entry.value as Map);
        
        return Event(
          id: entry.key,
          name: eventData['name'],
          description: eventData['description'],
          date: DateTime.parse('${eventData['date']}T00:00:00.000Z'),
          isActive: eventData['isActive'] == true,
        );
      }
      return null;
    } catch (e) {
      print('Error getting active event: $e');
      return null;
    }
  }

  static Future<void> _deactivateAllEvents() async {
    if (!isAvailable) return;
    
    try {
      final snapshot = await _database!.ref('events').get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final updates = <String, dynamic>{};
        
        for (final key in data.keys) {
          updates['events/$key/isActive'] = false;
        }
        
        await _database!.ref().update(updates);
      }
    } catch (e) {
      print('Error deactivating events: $e');
    }
  }

  // Attendance
  static Future<String> saveAttendanceRecord(AttendanceRecord record) async {
    if (!isAvailable) throw Exception('Firebase not available');
    
    try {
      final ref = _database!.ref('attendance').push();
      await ref.set({
        'studentId': record.studentId,
        'eventId': record.eventId,
        'checkInTime': record.checkInTime.toIso8601String(),
        'checkOutTime': record.checkOutTime?.toIso8601String(),
        'points': record.points,
        'isManualEntry': record.isManualEntry,
      });
      return ref.key!;
    } catch (e) {
      print('Error saving attendance record: $e');
      rethrow;
    }
  }

  static Future<void> updateAttendanceRecord(String recordId, AttendanceRecord record) async {
    if (!isAvailable) return;
    
    try {
      await _database!
          .ref('attendance/$recordId')
          .update({
            'checkOutTime': record.checkOutTime?.toIso8601String(),
            'points': record.points,
          });
    } catch (e) {
      print('Error updating attendance record: $e');
      rethrow;
    }
  }

  static Future<AttendanceRecord?> getActiveAttendanceRecord(String studentId, String eventId) async {
    if (!isAvailable) return null;
    
    try {
      final snapshot = await _database!
          .ref('attendance')
          .orderByChild('studentId')
          .equalTo(studentId)
          .get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        for (final entry in data.entries) {
          final recordData = Map<String, dynamic>.from(entry.value as Map);
          
          // Check if this record is for the right event and not checked out
          if (recordData['eventId'] == eventId && recordData['checkOutTime'] == null) {
            return AttendanceRecord(
              id: entry.key,
              studentId: recordData['studentId'],
              eventId: recordData['eventId'],
              checkInTime: DateTime.parse(recordData['checkInTime']),
              checkOutTime: recordData['checkOutTime'] != null 
                ? DateTime.parse(recordData['checkOutTime']) 
                : null,
              points: recordData['points'] ?? 0,
              isManualEntry: recordData['isManualEntry'] == true,
            );
          }
        }
      }
      return null;
    } catch (e) {
      print('Error getting active attendance record: $e');
      return null;
    }
  }

  static Future<List<AttendanceRecord>> getEventAttendance(String eventId) async {
    if (!isAvailable) return [];
    
    try {
      final snapshot = await _database!
          .ref('attendance')
          .orderByChild('eventId')
          .equalTo(eventId)
          .get();
      
      if (snapshot.exists) {
        final records = <AttendanceRecord>[];
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        for (final entry in data.entries) {
          final recordData = Map<String, dynamic>.from(entry.value as Map);
          records.add(AttendanceRecord(
            id: entry.key,
            studentId: recordData['studentId'],
            eventId: recordData['eventId'],
            checkInTime: DateTime.parse(recordData['checkInTime']),
            checkOutTime: recordData['checkOutTime'] != null 
              ? DateTime.parse(recordData['checkOutTime']) 
              : null,
            points: recordData['points'] ?? 0,
            isManualEntry: recordData['isManualEntry'] == true,
          ));
        }
        
        // Sort by check-in time descending
        records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
        return records;
      }
      return [];
    } catch (e) {
      print('Error getting event attendance: $e');
      return [];
    }
  }

  // Listen to realtime updates
  static Stream<List<Student>> watchLeaderboard({int limit = 10}) {
    if (!isAvailable) return Stream.value([]);
    
    return _database!
        .ref('students')
        .orderByChild('totalPoints')
        .limitToLast(limit)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final students = <Student>[];
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        for (final entry in data.entries) {
          final studentData = Map<String, dynamic>.from(entry.value as Map);
          students.add(Student(
            studentId: entry.key,
            name: studentData['name'],
            totalPoints: studentData['totalPoints'] ?? 0,
            createdAt: studentData['createdAt'] != null 
              ? DateTime.parse(studentData['createdAt']) 
              : DateTime.now(),
          ));
        }
        
        students.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
        return students;
      }
      return <Student>[];
    });
  }

  static Stream<List<AttendanceRecord>> watchEventAttendance(String eventId) {
    if (!isAvailable) return Stream.value([]);
    
    return _database!
        .ref('attendance')
        .orderByChild('eventId')
        .equalTo(eventId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final records = <AttendanceRecord>[];
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        for (final entry in data.entries) {
          final recordData = Map<String, dynamic>.from(entry.value as Map);
          records.add(AttendanceRecord(
            id: entry.key,
            studentId: recordData['studentId'],
            eventId: recordData['eventId'],
            checkInTime: DateTime.parse(recordData['checkInTime']),
            checkOutTime: recordData['checkOutTime'] != null 
              ? DateTime.parse(recordData['checkOutTime']) 
              : null,
            points: recordData['points'] ?? 0,
            isManualEntry: recordData['isManualEntry'] == true,
          ));
        }
        
        records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
        return records;
      }
      return <AttendanceRecord>[];
    });
  }

  // Connection status
  static Stream<bool> watchConnectionStatus() {
    if (!isAvailable) return Stream.value(false);
    
    return _database!
        .ref('.info/connected')
        .onValue
        .map((event) => event.snapshot.value as bool? ?? false);
  }
}
