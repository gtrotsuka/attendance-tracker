# TA Attendance Tracker

A Flutter web application for tracking Teaching Assistant attendance with card swipe support and real-time data synchronization.

## ✨ Features

### Core Functionality
- **Card Swipe Processing** - Parse magnetic stripe card data
- **Manual Entry** - Enter student IDs manually
- **Points System** - Award points based on attendance duration
- **Event Management** - Create and manage attendance events
- **Real-time Leaderboard** - Live ranking of students by points
- **Cross-device Sync** - Firebase Realtime Database integration

### Technical Features
- **Offline-first Design** - Works without internet connection
- **Hybrid Storage** - Local storage with Firebase backup
- **Real-time Updates** - Live data synchronization
- **Web Responsive** - Works on desktop and mobile browsers
- **PWA Ready** - Can be installed as a web app

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.0+)
- Web browser (Chrome recommended)
- Firebase project (optional, for sync)

### Installation
```bash
# Clone the repository
git clone <repository-url>
cd attendance-tracker

# Install dependencies
flutter pub get

# Run the application
flutter run -d web-server --web-port 8080
```

### First Launch
1. Open http://localhost:8080 in your browser
2. Create a new event in the "Events" tab
3. Start scanning cards or entering student IDs
4. Monitor attendance in real-time

## 📊 Data Storage

The app supports two storage modes:

### Local Storage (Default)
- Uses browser SharedPreferences
- Works completely offline
- Data persists in browser storage
- Perfect for single-device use

### Firebase Integration (Optional)
- Real-time database synchronization
- Cross-device data sharing
- Offline-first with automatic sync
- Live leaderboard updates

See [FIREBASE_INTEGRATION.md](FIREBASE_INTEGRATION.md) for setup instructions.

## 🎯 Usage

### Card Swipe Format
The app parses magnetic stripe data in this format:
```
;1570=903774061=00=6017700007279520?
```
Where `903774061` is extracted as the student ID.

### Points System
- **Check-in**: 1 point (minimum)
- **15-30 min**: 3 points
- **30-60 min**: 5 points
- **1-2 hours**: 8 points
- **2+ hours**: 10 points (maximum)

### Manual Entry
If card readers aren't available, manually enter student IDs in the Check In tab.

## 🛠️ Development

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/
│   └── models.dart          # Data models
├── services/
│   ├── attendance_service.dart    # Core business logic
│   ├── database_service.dart      # Local storage
│   ├── firebase_service.dart      # Firebase integration
│   └── hybrid_attendance_service.dart # Hybrid storage
├── config/
│   └── firebase_config.dart       # Firebase configuration
└── web/
    └── index.html               # Web app shell
```

### Build Commands
```bash
# Development
flutter run -d web-server

# Production build
flutter build web --release

# Run tests
flutter test

# Code analysis
flutter analyze
```

## 🔧 Configuration

### Firebase Setup (Optional)
1. Create a Firebase project
2. Enable Realtime Database
3. Copy web configuration to `lib/config/firebase_config.dart`
4. Set `useDemoDatabase = false`
5. Rebuild the app

### Card Reader Integration
The app works with standard USB HID card readers that output keyboard data. No special drivers required.

## 📱 Deployment

### Firebase Hosting
```bash
flutter build web --release
firebase deploy
```

### Static Hosting
Upload the `build/web/` directory to any static hosting service.

### Local Network
```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For questions or issues:
1. Check the [Firebase Integration Guide](FIREBASE_INTEGRATION.md)
2. Review the code documentation
3. Open an issue on GitHub

---

**Note**: This application was designed for educational use in tracking TA attendance. Ensure compliance with your institution's data privacy policies.
