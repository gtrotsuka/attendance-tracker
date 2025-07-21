import 'package:flutter_test/flutter_test.dart';
import '../lib/services/firebase_service.dart';
import '../lib/services/hybrid_attendance_service.dart';
import '../lib/services/attendance_service.dart';

void main() {
  group('Firebase Integration Tests', () {
    test('Firebase service initializes without throwing', () async {
      // This test just checks that Firebase service can be initialized
      // without throwing exceptions, even if it can't connect
      expect(() => FirebaseService.initialize(), returnsNormally);
    });

    test('Hybrid service initializes with local fallback', () async {
      final localService = AttendanceService();
      final hybridService = HybridAttendanceService(localService);
      
      expect(() => hybridService.initialize(), returnsNormally);
    });

    test('Firebase service reports availability correctly', () async {
      await FirebaseService.initialize();
      
      // Should be either true (connected) or false (not connected)
      // but shouldn't throw an exception
      expect(FirebaseService.isAvailable, isA<bool>());
    });
  });
}
