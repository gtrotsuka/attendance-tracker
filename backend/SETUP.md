# Backend Setup Instructions

## Prerequisites

You need to install Node.js to run the backend server.

### Installing Node.js

1. **Download Node.js**: Go to [https://nodejs.org/](https://nodejs.org/) and download the LTS version for Windows.

2. **Install Node.js**: Run the downloaded installer and follow the installation instructions.

3. **Verify Installation**: Open a new PowerShell/Command Prompt window and run:
   ```bash
   node --version
   npm --version
   ```
   Both commands should return version numbers.

## Backend Setup

Once Node.js is installed:

1. **Navigate to the backend directory**:
   ```powershell
   cd "c:\Users\otsuk\Documents\CS 1100\attendance-tracker\backend"
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Initialize the database**:
   ```bash
   npm run init-db
   ```

4. **Start the development server**:
   ```bash
   npm run dev
   ```

   The server will start on `http://localhost:3000`

## For Production Deployment

### Option 1: Heroku

1. Install the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli)
2. Login to Heroku: `heroku login`
3. Create a new app: `heroku create your-app-name`
4. Add environment variables:
   ```bash
   heroku config:set NODE_ENV=production
   heroku config:set CORS_ORIGIN=https://yourdomain.github.io
   ```
5. Deploy: `git push heroku main`

### Option 2: Railway

1. Sign up at [Railway.app](https://railway.app)
2. Connect your GitHub repository
3. Set environment variables in the Railway dashboard
4. Deploy automatically from GitHub

### Option 3: Render

1. Sign up at [Render.com](https://render.com)
2. Connect your GitHub repository
3. Choose "Web Service"
4. Set build command: `npm install`
5. Set start command: `npm start`
6. Set environment variables

## Environment Variables for Production

```
NODE_ENV=production
PORT=3000
CORS_ORIGIN=https://yourdomain.github.io,https://your-custom-domain.com
DB_PATH=./database/attendance.db
```

## Testing the API

Once the server is running, you can test the endpoints:

- Health check: `GET http://localhost:3000/api/health`
- Get students: `GET http://localhost:3000/api/students`
- Get events: `GET http://localhost:3000/api/events`

## Flutter App Configuration

Update the `_baseUrl` in `lib/services/api_service.dart` to point to your deployed backend:

```dart
static const String _baseUrl = 'https://your-backend-url.herokuapp.com/api';
```

## Database

The backend uses SQLite for simplicity. For production, you might want to upgrade to PostgreSQL or MySQL. The database schema is designed to be compatible with most SQL databases.

To migrate to PostgreSQL:

1. Install `pg` package: `npm install pg`
2. Update the database connection in `database/database.js`
3. Update the SQL queries to use PostgreSQL syntax where needed

## Security Considerations

- The backend includes basic security measures (CORS, rate limiting, helmet)
- For production, consider adding authentication/authorization
- Use HTTPS in production
- Consider using a managed database service
- Set up proper logging and monitoring
