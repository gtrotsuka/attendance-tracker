import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/simple_firebase_service.dart';
import 'services/database_service.dart';
import 'config/firebase_config.dart';
import 'models/models.dart';

void main() async {
  // Ensure Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: FirebaseConfig.options,
    );
    print('🔥 Firebase initialized successfully');
    
    // Initialize the simple Firebase service
    await SimpleFirebaseService.initializeFirebase();
  } catch (e) {
    print('⚠️  Firebase initialization failed: $e');
    print('📱 App will run in local-only mode');
  }
  
  // Initialize database factory for desktop platforms
  await DatabaseService.initialize();
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AttendanceProvider(),
      child: MaterialApp(
        title: 'TA Attendance Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AttendanceScreen(),
      ),
    );
  }
}

class AttendanceProvider extends ChangeNotifier {
  final SimpleFirebaseService _attendanceService = SimpleFirebaseService();
  Event? _currentEvent;
  List<AttendanceRecord> _currentAttendance = [];
  List<Student> _leaderboard = [];
  String _statusMessage = 'Ready to scan cards or enter ID manually';
  bool _isLoading = false;

  AttendanceProvider() {
    _initializeServices();
    _setupFirebaseListeners();
  }
  void _setupFirebaseListeners() {
    // Listen for Firebase real-time updates and refresh provider state
    SimpleFirebaseService.eventListener?.cancel();
    SimpleFirebaseService.eventListener = SimpleFirebaseService.database?.ref('events').onValue.listen((event) async {
      print('🔄 [Provider] Events updated: ${event.snapshot.value}');
      await refreshData();
    });

    SimpleFirebaseService.attendanceListener?.cancel();
    SimpleFirebaseService.attendanceListener = SimpleFirebaseService.database?.ref('attendance').onValue.listen((event) async {
      print('🔄 [Provider] Attendance updated: ${event.snapshot.value}');
      await refreshData();
    });

    SimpleFirebaseService.leaderboardListener?.cancel();
    SimpleFirebaseService.leaderboardListener = SimpleFirebaseService.database?.ref('students').onValue.listen((event) async {
      print('🔄 [Provider] Leaderboard updated: ${event.snapshot.value}');
      await refreshData();
    });
  }

  Event? get currentEvent => _currentEvent;
  List<AttendanceRecord> get currentAttendance => _currentAttendance;
  List<Student> get leaderboard => _leaderboard;
  String get statusMessage => _statusMessage;
  bool get isLoading => _isLoading;

  Future<void> _initializeServices() async {
    try {
      final isFirebaseAvailable = SimpleFirebaseService.isFirebaseAvailable;
      _statusMessage = isFirebaseAvailable 
          ? 'Ready to scan cards - Firebase sync enabled'
          : 'Ready to scan cards - Local storage only';
      await refreshData();
    } catch (e) {
      _statusMessage = 'Initialization failed, using local storage only';
    }
  }

  Future<void> initialize() async {
    _isLoading = true;
    _statusMessage = 'Initializing database...';
    notifyListeners();
    
    try {
      _currentEvent = await _attendanceService.getCurrentEvent();
      await refreshData();
      _statusMessage = 'Ready to scan cards or enter ID manually';
    } catch (e) {
      _statusMessage = 'Initialization failed: ${e.toString()}';
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshData() async {
    try {
      _currentAttendance = await _attendanceService.getCurrentEventAttendance();
      _leaderboard = await _attendanceService.getLeaderboard();
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Failed to refresh data: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> processAttendance(String input, {bool isManual = false}) async {
    if (input.trim().isEmpty) {
      _statusMessage = 'Error: Empty input';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _statusMessage = 'Processing attendance...';
    notifyListeners();

    try {
      final result = await _attendanceService.processAttendance(input, isManual: isManual);
      _statusMessage = result;
      await refreshData();
    } catch (e) {
      _statusMessage = 'Error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createEvent(String eventName) async {
    _isLoading = true;
    _statusMessage = 'Creating event...';
    notifyListeners();

    try {
      await _attendanceService.createEvent(eventName);
      _currentEvent = await _attendanceService.getCurrentEvent();
      _statusMessage = 'Event "$eventName" created successfully';
      await refreshData();
    } catch (e) {
      _statusMessage = 'Error creating event: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> endCurrentEvent() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _attendanceService.endCurrentEvent();
      _currentEvent = null;
      _currentAttendance = [];
      _statusMessage = 'Event ended successfully';
    } catch (e) {
      _statusMessage = 'Error ending event: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteAttendanceRecord(AttendanceRecord record) async {
    _isLoading = true;
    notifyListeners();

    try {
      // For local storage, we need the integer ID
      if (record.id != null) {
        // Try to parse as int for local database
        final intId = int.tryParse(record.id!);
        if (intId != null) {
          await _attendanceService.deleteAttendanceRecord(intId, record.studentId);
        }
      }
      _statusMessage = 'Attendance record deleted';
      await refreshData();
    } catch (e) {
      _statusMessage = 'Error deleting record: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _cardInputController = TextEditingController();
  final TextEditingController _manualInputController = TextEditingController();
  final TextEditingController _eventNameController = TextEditingController();
  final FocusNode _cardInputFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _cardInputController.dispose();
    _manualInputController.dispose();
    _eventNameController.dispose();
    _cardInputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('TA Attendance Tracker'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.refreshData,
              ),
            ],
          ),
          body: Column(
            children: [
              // Event Status Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: provider.currentEvent != null ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: provider.currentEvent != null ? Colors.green : Colors.orange,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.currentEvent != null 
                          ? 'Active Event: ${provider.currentEvent!.name}'
                          : 'No Active Event',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (provider.currentEvent != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Started: ${DateFormat('MMM dd, yyyy - HH:mm').format(provider.currentEvent!.date)}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ],
                ),
              ),

              // Status Message
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  provider.statusMessage,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Tab Navigation
              Expanded(
                child: DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Colors.blue,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.blue,
                        tabs: [
                          Tab(text: 'Check In', icon: Icon(Icons.login)),
                          Tab(text: 'Attendance', icon: Icon(Icons.list)),
                          Tab(text: 'Leaderboard', icon: Icon(Icons.leaderboard)),
                          Tab(text: 'Events', icon: Icon(Icons.event)),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildCheckInTab(provider),
                            _buildAttendanceTab(provider),
                            _buildLeaderboardTab(provider),
                            _buildEventsTab(provider),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckInTab(AttendanceProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Card Swipe Input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Card Swipe',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Swipe card or paste card data here:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cardInputController,
                    focusNode: _cardInputFocus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: ';1570=903774061=00=6017700007279520?',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        provider.processAttendance(value);
                        _cardInputController.clear();
                        _cardInputFocus.requestFocus();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : () {
                        if (_cardInputController.text.isNotEmpty) {
                          provider.processAttendance(_cardInputController.text);
                          _cardInputController.clear();
                          _cardInputFocus.requestFocus();
                        }
                      },
                      child: provider.isLoading 
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Process Card'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Manual ID Input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manual ID Entry',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Enter student ID manually:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _manualInputController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '903774061',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        provider.processAttendance(value, isManual: true);
                        _manualInputController.clear();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : () {
                        if (_manualInputController.text.isNotEmpty) {
                          provider.processAttendance(_manualInputController.text, isManual: true);
                          _manualInputController.clear();
                        }
                      },
                      child: provider.isLoading 
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Manual Check In/Out'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(AttendanceProvider provider) {
    if (provider.currentEvent == null) {
      return const Center(
        child: Text(
          'No active event. Create an event to start tracking attendance.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Attendance for: ${provider.currentEvent!.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: provider.currentAttendance.isEmpty
                ? const Center(child: Text('No attendance records yet'))
                : ListView.builder(
                    itemCount: provider.currentAttendance.length,
                    itemBuilder: (context, index) {
                      final record = provider.currentAttendance[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: record.isCheckedOut ? Colors.green : Colors.orange,
                            child: Icon(
                              record.isCheckedOut ? Icons.check : Icons.access_time,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(record.studentId),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('In: ${DateFormat('HH:mm:ss').format(record.checkInTime)}'),
                              if (record.isCheckedOut) ...[
                                Text('Out: ${DateFormat('HH:mm:ss').format(record.checkOutTime!)}'),
                                Text('Duration: ${record.duration!.inMinutes} min, Points: ${record.points}'),
                              ] else
                                const Text('Still checked in'),
                              if (record.isManualEntry)
                                const Text('(Manual entry)', style: TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(context, provider, record),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(AttendanceProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Student Leaderboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: provider.leaderboard.isEmpty
                ? const Center(child: Text('No students in leaderboard yet'))
                : ListView.builder(
                    itemCount: provider.leaderboard.length,
                    itemBuilder: (context, index) {
                      final student = provider.leaderboard[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: index < 3 ? Colors.amber : Colors.blue,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(student.name ?? student.studentId),
                          subtitle: Text('Student ID: ${student.studentId}'),
                          trailing: Text(
                            '${student.totalPoints} pts',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab(AttendanceProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Create Event Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Event',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _eventNameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter event name',
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        provider.createEvent(value);
                        _eventNameController.clear();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: provider.isLoading ? null : () {
                      if (_eventNameController.text.isNotEmpty) {
                        provider.createEvent(_eventNameController.text);
                        _eventNameController.clear();
                      }
                    },
                    child: provider.isLoading 
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Event'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // End Event Section
          if (provider.currentEvent != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'End Current Event',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Current event: ${provider.currentEvent!.name}'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: provider.isLoading ? null : () {
                        _showEndEventConfirmation(context, provider);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: provider.isLoading 
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('End Event', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AttendanceProvider provider, AttendanceRecord record) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Attendance Record'),
          content: Text('Are you sure you want to delete the attendance record for ${record.studentId}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                provider.deleteAttendanceRecord(record);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showEndEventConfirmation(BuildContext context, AttendanceProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Event'),
          content: Text('Are you sure you want to end the event "${provider.currentEvent!.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                provider.endCurrentEvent();
              },
              child: const Text('End Event', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
