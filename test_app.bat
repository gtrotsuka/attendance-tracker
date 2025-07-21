@echo off
echo.
echo ============================================
echo  🚀 Firebase Attendance Tracker - Quick Test
echo ============================================
echo.
echo Opening the app in your default browser...
echo.

REM Open the built web app
start "" "file:///%~dp0build\web\index.html"

echo.
echo ✅ App opened! Check for:
echo    - Status: "Firebase sync enabled" or "Local storage only"
echo    - Browser console (F12) for Firebase messages
echo.
echo 🧪 Test Steps:
echo    1. Create event: "Test Event"
echo    2. Add attendance: 903774061
echo    3. Check data appears in both tabs
echo    4. Watch console for sync messages
echo.
echo 🔥 Firebase Console: https://console.firebase.google.com/
echo    Project: gt-attendance-tracker-demo
echo.
pause
