const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

class Database {
  constructor() {
    this.db = null;
  }

  static async initialize() {
    const instance = new Database();
    await instance.connect();
    await instance.createTables();
    return instance;
  }

  async connect() {
    return new Promise((resolve, reject) => {
      const dbPath = process.env.DB_PATH || './database/attendance.db';
      const dbDir = path.dirname(dbPath);
      
      // Ensure database directory exists
      if (!fs.existsSync(dbDir)) {
        fs.mkdirSync(dbDir, { recursive: true });
      }

      this.db = new sqlite3.Database(dbPath, (err) => {
        if (err) {
          console.error('❌ Database connection failed:', err);
          reject(err);
        } else {
          console.log('📁 Connected to SQLite database at:', dbPath);
          // Enable foreign keys
          this.db.run('PRAGMA foreign_keys = ON');
          resolve();
        }
      });
    });
  }

  async createTables() {
    const createStudentsTable = `
      CREATE TABLE IF NOT EXISTS students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT UNIQUE NOT NULL,
        name TEXT,
        total_points INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `;

    const createEventsTable = `
      CREATE TABLE IF NOT EXISTS events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        is_active INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `;

    const createAttendanceTable = `
      CREATE TABLE IF NOT EXISTS attendance_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL,
        event_id INTEGER NOT NULL,
        check_in_time DATETIME NOT NULL,
        check_out_time DATETIME,
        points INTEGER DEFAULT 0,
        is_checked_out INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (student_id) REFERENCES students (student_id),
        FOREIGN KEY (event_id) REFERENCES events (id)
      )
    `;

    // Create indexes for better performance
    const createIndexes = [
      'CREATE INDEX IF NOT EXISTS idx_students_student_id ON students (student_id)',
      'CREATE INDEX IF NOT EXISTS idx_attendance_student_id ON attendance_records (student_id)',
      'CREATE INDEX IF NOT EXISTS idx_attendance_event_id ON attendance_records (event_id)',
      'CREATE INDEX IF NOT EXISTS idx_attendance_check_in ON attendance_records (check_in_time)',
      'CREATE INDEX IF NOT EXISTS idx_events_date ON events (date)',
      'CREATE INDEX IF NOT EXISTS idx_events_active ON events (is_active)'
    ];

    try {
      await this.run(createStudentsTable);
      await this.run(createEventsTable);
      await this.run(createAttendanceTable);
      
      for (const indexQuery of createIndexes) {
        await this.run(indexQuery);
      }
      
      console.log('✅ Database tables and indexes created successfully');
    } catch (error) {
      console.error('❌ Error creating tables:', error);
      throw error;
    }
  }

  // Helper method to promisify database operations
  run(sql, params = []) {
    return new Promise((resolve, reject) => {
      this.db.run(sql, params, function(err) {
        if (err) {
          reject(err);
        } else {
          resolve({ id: this.lastID, changes: this.changes });
        }
      });
    });
  }

  get(sql, params = []) {
    return new Promise((resolve, reject) => {
      this.db.get(sql, params, (err, row) => {
        if (err) {
          reject(err);
        } else {
          resolve(row);
        }
      });
    });
  }

  all(sql, params = []) {
    return new Promise((resolve, reject) => {
      this.db.all(sql, params, (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
  }

  close() {
    return new Promise((resolve, reject) => {
      this.db.close((err) => {
        if (err) {
          reject(err);
        } else {
          console.log('📁 Database connection closed');
          resolve();
        }
      });
    });
  }
}

// Global database instance
let dbInstance = null;

const getDB = async () => {
  if (!dbInstance) {
    dbInstance = await Database.initialize();
  }
  return dbInstance;
};

module.exports = {
  Database,
  getDB
};
