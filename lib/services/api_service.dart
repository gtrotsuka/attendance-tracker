import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:3000/api';
  static const Duration _timeout = Duration(seconds: 10);

  // Helper method to handle HTTP responses
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      final error = response.body.isNotEmpty 
          ? json.decode(response.body)['error'] ?? 'Unknown error'
          : 'HTTP ${response.statusCode}';
      throw Exception('API Error: $error');
    }
  }

  // Student endpoints
  static Future<List<Student>> getStudents() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/students'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      final data = _handleResponse(response) as List;
      return data.map((json) => Student.fromApiMap(json)).toList();
    } catch (e) {
      print('Error fetching students: $e');
      throw Exception('Failed to fetch students: $e');
    }
  }

  static Future<Student?> getStudent(String studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/students/$studentId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 404) return null;
      
      final data = _handleResponse(response);
      return Student.fromApiMap(data);
    } catch (e) {
      print('Error fetching student: $e');
      return null;
    }
  }

  static Future<Student> createOrUpdateStudent(Student student) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/students'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(student.toApiMap()),
      ).timeout(_timeout);

      final data = _handleResponse(response);
      return Student.fromApiMap(data);
    } catch (e) {
      print('Error creating/updating student: $e');
      throw Exception('Failed to create/update student: $e');
    }
  }

  static Future<List<Student>> getLeaderboard({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/students/leaderboard/top?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      final data = _handleResponse(response) as List;
      return data.map((json) => Student.fromApiMap(json)).toList();
    } catch (e) {
      print('Error fetching leaderboard: $e');
      throw Exception('Failed to fetch leaderboard: $e');
    }
  }

  // Event endpoints
  static Future<List<Event>> getEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/events'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      final data = _handleResponse(response) as List;
      return data.map((json) => Event.fromApiMap(json)).toList();
    } catch (e) {
      print('Error fetching events: $e');
      throw Exception('Failed to fetch events: $e');
    }
  }

  static Future<Event?> getActiveEvent() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/events/active/current'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 404) return null;
      
      final data = _handleResponse(response);
      return Event.fromApiMap(data);
    } catch (e) {
      print('Error fetching active event: $e');
      return null;
    }
  }

  static Future<Event> createEvent(Event event) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/events'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(event.toApiMap()),
      ).timeout(_timeout);

      final data = _handleResponse(response);
      return Event.fromApiMap(data);
    } catch (e) {
      print('Error creating event: $e');
      throw Exception('Failed to create event: $e');
    }
  }

  static Future<Event> updateEvent(Event event) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/events/${event.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(event.toApiMap()),
      ).timeout(_timeout);

      final data = _handleResponse(response);
      return Event.fromApiMap(data);
    } catch (e) {
      print('Error updating event: $e');
      throw Exception('Failed to update event: $e');
    }
  }

  static Future<Event> activateEvent(int eventId) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/events/$eventId/activate'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      final data = _handleResponse(response);
      return Event.fromApiMap(data);
    } catch (e) {
      print('Error activating event: $e');
      throw Exception('Failed to activate event: $e');
    }
  }

  // Attendance endpoints
  static Future<List<AttendanceRecord>> getAttendanceRecords({int? eventId, String? studentId}) async {
    try {
      String url = '$_baseUrl/attendance';
      List<String> params = [];
      
      if (eventId != null) params.add('event_id=$eventId');
      if (studentId != null) params.add('student_id=$studentId');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      final data = _handleResponse(response) as List;
      return data.map((json) => AttendanceRecord.fromApiMap(json)).toList();
    } catch (e) {
      print('Error fetching attendance records: $e');
      throw Exception('Failed to fetch attendance records: $e');
    }
  }

  static Future<List<AttendanceRecord>> getEventAttendance(int eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/attendance/event/$eventId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      final data = _handleResponse(response) as List;
      return data.map((json) => AttendanceRecord.fromApiMap(json)).toList();
    } catch (e) {
      print('Error fetching event attendance: $e');
      throw Exception('Failed to fetch event attendance: $e');
    }
  }

  static Future<Map<String, dynamic>> processAttendance({
    required String studentId,
    required int eventId,
    bool isManual = false,
    String? input,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/attendance/process'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': studentId,
          'event_id': eventId,
          'is_manual': isManual,
          'input': input,
        }),
      ).timeout(_timeout);

      final data = _handleResponse(response);
      return {
        'action': data['action'],
        'message': data['message'],
        'record': AttendanceRecord.fromApiMap(data['record']),
      };
    } catch (e) {
      print('Error processing attendance: $e');
      throw Exception('Failed to process attendance: $e');
    }
  }

  // Health check
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Connection check failed: $e');
      return false;
    }
  }
}
