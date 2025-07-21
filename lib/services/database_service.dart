import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static SharedPreferences? _prefs;
  static bool _initialized = false;

  // Singleton pattern
  DatabaseService._internal();
  
  factory DatabaseService() {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  static Future<void> initialize() async {
    if (!_initialized) {
      print('🔧 [DATABASE] Starting initialization for WEB platform');
      try {
        print('🌐 [DATABASE] Initializing web storage with SharedPreferences...');
        _prefs = await SharedPreferences.getInstance();
        print('✅ [DATABASE] Web storage initialized successfully');
        print('✅ [DATABASE] Initialization completed');
      } catch (e) {
        print('❌ [DATABASE] Initialization failed: $e');
        rethrow;
      }
      _initialized = true;
    } else {
      print('♻️  [DATABASE] Already initialized, skipping');
    }
  }

  // Web-specific storage methods using SharedPreferences
  Future<List<Student>> _getStudentsFromPrefs() async {
    await initialize();
    final studentsJson = _prefs!.getString('students') ?? '[]';
    final List<dynamic> studentsList = json.decode(studentsJson);
    return studentsList.map((json) => Student.fromMap(json)).toList();
  }

  Future<void> _saveStudentsToPrefs(List<Student> students) async {
    await initialize();
    final studentsJson = json.encode(students.map((s) => s.toMap()).toList());
    await _prefs!.setString('students', studentsJson);
  }

  Future<List<Event>> _getEventsFromPrefs() async {
    await initialize();
    final eventsJson = _prefs!.getString('events') ?? '[]';
    final List<dynamic> eventsList = json.decode(eventsJson);
    return eventsList.map((json) => Event.fromMap(json)).toList();
  }

  Future<void> _saveEventsToPrefs(List<Event> events) async {
    await initialize();
    final eventsJson = json.encode(events.map((e) => e.toMap()).toList());
    await _prefs!.setString('events', eventsJson);
  }

  Future<List<AttendanceRecord>> _getAttendanceFromPrefs() async {
    await initialize();
    final attendanceJson = _prefs!.getString('attendance_records') ?? '[]';
    final List<dynamic> attendanceList = json.decode(attendanceJson);
    return attendanceList.map((json) => AttendanceRecord.fromMap(json)).toList();
  }

  Future<void> _saveAttendanceToPrefs(List<AttendanceRecord> records) async {
    await initialize();
    final attendanceJson = json.encode(records.map((r) => r.toMap()).toList());
    await _prefs!.setString('attendance_records', attendanceJson);
  }

  // Student operations
  Future<int> insertStudent(Student student) async {
    print('👤 [DATABASE] Inserting student: ${student.studentId}');
    try {
      final students = await _getStudentsFromPrefs();
      students.removeWhere((s) => s.studentId == student.studentId);
      final newId = students.isEmpty ? 1 : students.map((s) => s.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      final newStudent = student.copyWith(id: newId);
      students.add(newStudent);
      await _saveStudentsToPrefs(students);
      print('✅ [DATABASE] Student inserted with ID: $newId (web)');
      return newId;
    } catch (e) {
      print('❌ [DATABASE] Failed to insert student: $e');
      rethrow;
    }
  }

  Future<Student?> getStudent(String studentId) async {
    final students = await _getStudentsFromPrefs();
    try {
      return students.firstWhere((s) => s.studentId == studentId);
    } catch (e) {
      return null;
    }
  }

  Future<List<Student>> getAllStudents() async {
    final students = await _getStudentsFromPrefs();
    students.sort((a, b) => (b.totalPoints).compareTo(a.totalPoints));
    return students;
  }

  Future<void> updateStudentPoints(String studentId, int points) async {
    final students = await _getStudentsFromPrefs();
    final index = students.indexWhere((s) => s.studentId == studentId);
    if (index != -1) {
      students[index] = students[index].copyWith(totalPoints: points);
      await _saveStudentsToPrefs(students);
    }
  }

  // Event operations
  Future<int> insertEvent(Event event) async {
    print('🎉 [DATABASE] Inserting event: ${event.name}');
    final events = await _getEventsFromPrefs();
    // End any existing active events
    for (var i = 0; i < events.length; i++) {
      if (events[i].isActive) {
        events[i] = events[i].copyWith(isActive: false);
      }
    }
    final newId = events.isEmpty ? 1 : events.map((e) => int.tryParse(e.id ?? '0') ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    final newEvent = event.copyWith(id: newId.toString());
    events.add(newEvent);
    await _saveEventsToPrefs(events);
    print('✅ [DATABASE] Event inserted with ID: $newId (web)');
    return newId;
  }

  Future<Event?> getActiveEvent() async {
    final events = await _getEventsFromPrefs();
    try {
      return events.firstWhere((e) => e.isActive);
    } catch (e) {
      return null;
    }
  }

  Future<List<Event>> getAllEvents() async {
    final events = await _getEventsFromPrefs();
    events.sort((a, b) => b.date.compareTo(a.date));
    return events;
  }

  Future<void> endEvent(int eventId) async {
    final events = await _getEventsFromPrefs();
    final index = events.indexWhere((e) => int.tryParse(e.id ?? '0') == eventId);
    if (index != -1) {
      events[index] = events[index].copyWith(isActive: false);
      await _saveEventsToPrefs(events);
    }
  }

  // Attendance operations
  Future<int> insertAttendanceRecord(AttendanceRecord record) async {
    print('📝 [DATABASE] Inserting attendance record for: ${record.studentId}');
    final records = await _getAttendanceFromPrefs();
    final newId = records.isEmpty ? 1 : records.map((r) => int.tryParse(r.id ?? '0') ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    final newRecord = record.copyWith(id: newId.toString());
    records.add(newRecord);
    await _saveAttendanceToPrefs(records);
    print('✅ [DATABASE] Attendance record inserted with ID: $newId (web)');
    return newId;
  }

  Future<AttendanceRecord?> getActiveAttendanceRecord(String studentId, int eventId) async {
    final records = await _getAttendanceFromPrefs();
    try {
      return records.firstWhere((r) => 
        r.studentId == studentId && 
        int.tryParse(r.eventId) == eventId && 
        r.checkOutTime == null
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> updateCheckOut(int recordId, DateTime checkOutTime, int points) async {
    final records = await _getAttendanceFromPrefs();
    final index = records.indexWhere((r) => int.tryParse(r.id ?? '0') == recordId);
    if (index != -1) {
      records[index] = records[index].copyWith(
        checkOutTime: checkOutTime,
        points: points
      );
      await _saveAttendanceToPrefs(records);
    }
  }

  Future<List<AttendanceRecord>> getAttendanceRecords(int eventId) async {
    final records = await _getAttendanceFromPrefs();
    final filtered = records.where((r) => int.tryParse(r.eventId) == eventId).toList();
    filtered.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    return filtered;
  }

  Future<List<AttendanceRecord>> getAllAttendanceRecords() async {
    final records = await _getAttendanceFromPrefs();
    records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    return records;
  }

  Future<void> deleteAttendanceRecord(int recordId) async {
    final records = await _getAttendanceFromPrefs();
    records.removeWhere((r) => r.id == recordId);
    await _saveAttendanceToPrefs(records);
  }

  Future<int> calculateTotalPoints(String studentId) async {
    final records = await _getAttendanceFromPrefs();
    int total = 0;
    for (final record in records) {
      if (record.studentId == studentId) {
        total += record.points;
      }
    }
    return total;
  }
}