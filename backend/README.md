# Attendance Tracker Backend

A Node.js/Express backend API for the Flutter attendance tracker application.

## Features

- RESTful API for managing students, events, and attendance
- SQLite database for data persistence
- CORS support for web applications
- Rate limiting for API protection
- Comprehensive error handling

## Setup

1. Install dependencies:
```bash
npm install
```

2. Initialize the database:
```bash
npm run init-db
```

3. Start the development server:
```bash
npm run dev
```

Or start the production server:
```bash
npm start
```

## Environment Variables

Copy `.env.example` to `.env` and configure:

- `NODE_ENV`: development or production
- `PORT`: Server port (default: 3000)
- `DB_PATH`: Path to SQLite database file
- `CORS_ORIGIN`: Allowed CORS origins (comma-separated)

## API Endpoints

### Students
- `GET /api/students` - Get all students
- `GET /api/students/:studentId` - Get student by ID
- `POST /api/students` - Create or update student
- `PATCH /api/students/:studentId/points` - Update student points
- `GET /api/students/leaderboard/top` - Get leaderboard
- `DELETE /api/students/:studentId` - Delete student

### Events
- `GET /api/events` - Get all events
- `GET /api/events/:id` - Get event by ID
- `GET /api/events/active/current` - Get active event
- `POST /api/events` - Create new event
- `PUT /api/events/:id` - Update event
- `PATCH /api/events/:id/activate` - Set active event
- `PATCH /api/events/deactivate/all` - Deactivate all events
- `DELETE /api/events/:id` - Delete event

### Attendance
- `GET /api/attendance` - Get all attendance records
- `GET /api/attendance/event/:eventId` - Get attendance for event
- `POST /api/attendance/process` - Process check-in/check-out
- `PATCH /api/attendance/:id/checkout` - Manual check-out
- `DELETE /api/attendance/:id` - Delete attendance record

### Health Check
- `GET /api/health` - Server health status

## Database Schema

### Students
- `id` (INTEGER PRIMARY KEY)
- `student_id` (TEXT UNIQUE)
- `name` (TEXT)
- `total_points` (INTEGER)
- `created_at` (DATETIME)
- `updated_at` (DATETIME)

### Events
- `id` (INTEGER PRIMARY KEY)
- `name` (TEXT)
- `description` (TEXT)
- `date` (TEXT)
- `is_active` (INTEGER BOOLEAN)
- `created_at` (DATETIME)
- `updated_at` (DATETIME)

### Attendance Records
- `id` (INTEGER PRIMARY KEY)
- `student_id` (TEXT)
- `event_id` (INTEGER)
- `check_in_time` (DATETIME)
- `check_out_time` (DATETIME)
- `points` (INTEGER)
- `is_checked_out` (INTEGER BOOLEAN)
- `created_at` (DATETIME)
- `updated_at` (DATETIME)

## Deployment

For production deployment:

1. Set `NODE_ENV=production` in your environment
2. Configure your CORS origins in the environment
3. Consider using a process manager like PM2
4. Set up proper logging and monitoring

## Security Features

- Helmet.js for security headers
- Rate limiting to prevent abuse
- CORS configuration
- Input validation
- SQL injection protection through parameterized queries
