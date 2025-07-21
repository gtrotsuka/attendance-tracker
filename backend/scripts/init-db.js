const { Database } = require('../database/database');

async function initializeDatabase() {
  console.log('🚀 Initializing database...');
  
  try {
    const db = await Database.initialize();
    console.log('✅ Database initialized successfully');
    
    // Optionally add some sample data
    console.log('📊 Adding sample data...');
    
    // Sample event
    await db.run(`
      INSERT OR IGNORE INTO events (name, description, date, is_active) 
      VALUES (?, ?, ?, ?)
    `, ['Sample TA Session', 'First TA session of the semester', '2025-01-21', 1]);
    
    // Sample students
    const sampleStudents = [
      { student_id: '123456789', name: 'John Doe' },
      { student_id: '987654321', name: 'Jane Smith' },
      { student_id: '456789123', name: 'Bob Johnson' }
    ];
    
    for (const student of sampleStudents) {
      await db.run(`
        INSERT OR IGNORE INTO students (student_id, name) 
        VALUES (?, ?)
      `, [student.student_id, student.name]);
    }
    
    console.log('✅ Sample data added');
    console.log('🎉 Database setup complete!');
    
    await db.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Database initialization failed:', error);
    process.exit(1);
  }
}

initializeDatabase();
