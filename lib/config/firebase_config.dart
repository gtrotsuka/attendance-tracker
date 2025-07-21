// Firebase configuration for the attendance tracker
// 
// To set up Firebase for your project:
// 
// 1. Go to https://console.firebase.google.com/
// 2. Create a new project or select existing project
// 3. Enable Realtime Database
// 4. Set up authentication rules (optional)
// 5. Get your Firebase config from Project Settings > General > Your apps
// 6. Replace the values below with your actual Firebase config

import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: "AIzaSyBPSqOWKVhD1lS6YPpxsjoAikd3Td7OSMY",
    authDomain: "attendance-tracker-a20e5.firebaseapp.com", 
    databaseURL: "https://attendance-tracker-a20e5-default-rtdb.firebaseio.com",
    projectId: "attendance-tracker-a20e5",
    storageBucket: "attendance-tracker-a20e5.firebasestorage.app",
    messagingSenderId: "1063953384447",
    appId: "1:1063953384447:web:1aec9ccfac08bc4b59ddca",
  );

  // Demo configuration for testing (points to a public demo database)
  // You can use this for initial testing, but create your own for production
  static const FirebaseOptions demoOptions = FirebaseOptions(
    apiKey: "AIzaSyBdCOF7QJrF8zJYYyJ5o5ZGDm5Q7CXIuGs", // Demo API key
    authDomain: "attendance-demo-flutter.firebaseapp.com",
    databaseURL: "https://attendance-demo-flutter-default-rtdb.firebaseio.com",
    projectId: "attendance-demo-flutter",
    storageBucket: "attendance-demo-flutter.appspot.com",
    messagingSenderId: "484596467896", 
    appId: "1:484596467896:web:5f8e6a59e2f8b9c4c7d8e9",
  );

  // Set this to false to use your actual Firebase project
  static const bool useDemoDatabase = false;

  static FirebaseOptions get options => useDemoDatabase ? demoOptions : webOptions;
}
