import '../models/models.dart';
import 'api_service.dart';

class AttendanceService {
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

    try {
      // Get active event
      final activeEvent = await ApiService.getActiveEvent();
      if (activeEvent == null) {
        return 'Error: No active event found';
      }

      // Process attendance through API
      final result = await ApiService.processAttendance(
        studentId: studentId,
        eventId: activeEvent.id!,
        isManual: isManual,
        input: input,
      );

      return result['message'] as String;
    } catch (e) {
      print('Error processing attendance: $e');
      return 'Error: Failed to process attendance - $e';
    }
  }

  // Get students by points (leaderboard)
  Future<List<Student>> getStudentsByPoints({int limit = 10}) async {
    try {
      return await ApiService.getLeaderboard(limit: limit);
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }

  // Get all events
  Future<List<Event>> getEvents() async {
    try {
      return await ApiService.getEvents();
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  // Get active event
  Future<Event?> getActiveEvent() async {
    try {
      return await ApiService.getActiveEvent();
    } catch (e) {
      print('Error fetching active event: $e');
      return null;
    }
  }

  // Create new event
  Future<Event?> createEvent(String name, String? description, DateTime date, {bool setActive = true}) async {
    try {
      final event = Event(
        name: name,
        description: description,
        date: date,
        isActive: setActive,
      );
      return await ApiService.createEvent(event);
    } catch (e) {
      print('Error creating event: $e');
      return null;
    }
  }

  // Activate an event
  Future<Event?> activateEvent(int eventId) async {
    try {
      return await ApiService.activateEvent(eventId);
    } catch (e) {
      print('Error activating event: $e');
      return null;
    }
  }

  // Get attendance for specific event
  Future<List<AttendanceRecord>> getEventAttendance(int eventId) async {
    try {
      return await ApiService.getEventAttendance(eventId);
    } catch (e) {
      print('Error fetching event attendance: $e');
      return [];
    }
  }

  // Get all attendance records
  Future<List<AttendanceRecord>> getAllAttendance() async {
    try {
      return await ApiService.getAttendanceRecords();
    } catch (e) {
      print('Error fetching all attendance: $e');
      return [];
    }
  }

  // Check API connection
  Future<bool> checkConnection() async {
    return await ApiService.checkConnection();
  }
}
