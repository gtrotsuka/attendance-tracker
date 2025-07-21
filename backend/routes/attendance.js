const express = require('express');
const { getDB } = require('../database/database');
const router = express.Router();

// Get all attendance records
router.get('/', async (req, res) => {
  try {
    const { event_id, student_id } = req.query;
    const db = await getDB();
    
    let query = `
      SELECT ar.*, s.name as student_name, e.name as event_name 
      FROM attendance_records ar 
      LEFT JOIN students s ON ar.student_id = s.student_id 
      LEFT JOIN events e ON ar.event_id = e.id
      WHERE 1=1
    `;
    const params = [];
    
    if (event_id) {
      query += ' AND ar.event_id = ?';
      params.push(event_id);
    }
    
    if (student_id) {
      query += ' AND ar.student_id = ?';
      params.push(student_id);
    }
    
    query += ' ORDER BY ar.check_in_time DESC';
    
    const records = await db.all(query, params);
    
    // Convert is_checked_out from integer to boolean
    const formattedRecords = records.map(record => ({
      ...record,
      is_checked_out: Boolean(record.is_checked_out)
    }));
    
    res.json(formattedRecords);
  } catch (error) {
    console.error('Error fetching attendance records:', error);
    res.status(500).json({ error: 'Failed to fetch attendance records' });
  }
});

// Get attendance for specific event
router.get('/event/:eventId', async (req, res) => {
  try {
    const { eventId } = req.params;
    const db = await getDB();
    
    const records = await db.all(`
      SELECT ar.*, s.name as student_name, e.name as event_name 
      FROM attendance_records ar 
      LEFT JOIN students s ON ar.student_id = s.student_id 
      LEFT JOIN events e ON ar.event_id = e.id
      WHERE ar.event_id = ?
      ORDER BY ar.check_in_time DESC
    `, [eventId]);
    
    // Convert is_checked_out from integer to boolean
    const formattedRecords = records.map(record => ({
      ...record,
      is_checked_out: Boolean(record.is_checked_out)
    }));
    
    res.json(formattedRecords);
  } catch (error) {
    console.error('Error fetching event attendance:', error);
    res.status(500).json({ error: 'Failed to fetch event attendance' });
  }
});

// Process attendance (check-in or check-out)
router.post('/process', async (req, res) => {
  try {
    const { student_id, event_id, is_manual = false, input } = req.body;
    
    if (!student_id || !event_id) {
      return res.status(400).json({ error: 'Student ID and Event ID are required' });
    }

    const db = await getDB();
    
    // Check if student exists, create if not
    let student = await db.get('SELECT * FROM students WHERE student_id = ?', [student_id]);
    if (!student) {
      await db.run('INSERT INTO students (student_id) VALUES (?)', [student_id]);
      student = await db.get('SELECT * FROM students WHERE student_id = ?', [student_id]);
    }
    
    // Check if event exists and is active
    const event = await db.get('SELECT * FROM events WHERE id = ? AND is_active = 1', [event_id]);
    if (!event) {
      return res.status(400).json({ error: 'Event not found or not active' });
    }
    
    // Check if student is already checked in for this event
    const existingRecord = await db.get(`
      SELECT * FROM attendance_records 
      WHERE student_id = ? AND event_id = ? AND is_checked_out = 0
      ORDER BY check_in_time DESC LIMIT 1
    `, [student_id, event_id]);
    
    if (existingRecord) {
      // Student is checking out
      const checkOutTime = new Date().toISOString();
      const checkInTime = new Date(existingRecord.check_in_time);
      const duration = new Date(checkOutTime) - checkInTime;
      const points = calculatePoints(duration);
      
      await db.run(`
        UPDATE attendance_records 
        SET check_out_time = ?, points = ?, is_checked_out = 1, updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
      `, [checkOutTime, points, existingRecord.id]);
      
      // Update student's total points
      await db.run(`
        UPDATE students 
        SET total_points = total_points + ?, updated_at = CURRENT_TIMESTAMP
        WHERE student_id = ?
      `, [points, student_id]);
      
      const updatedRecord = await db.get(`
        SELECT ar.*, s.name as student_name, e.name as event_name 
        FROM attendance_records ar 
        LEFT JOIN students s ON ar.student_id = s.student_id 
        LEFT JOIN events e ON ar.event_id = e.id
        WHERE ar.id = ?
      `, [existingRecord.id]);
      
      res.json({
        action: 'check_out',
        message: `Checked out successfully! Duration: ${Math.round(duration / (1000 * 60))} minutes, Points: ${points}`,
        record: {
          ...updatedRecord,
          is_checked_out: Boolean(updatedRecord.is_checked_out)
        }
      });
    } else {
      // Student is checking in
      const checkInTime = new Date().toISOString();
      
      const result = await db.run(`
        INSERT INTO attendance_records (student_id, event_id, check_in_time) 
        VALUES (?, ?, ?)
      `, [student_id, event_id, checkInTime]);
      
      const newRecord = await db.get(`
        SELECT ar.*, s.name as student_name, e.name as event_name 
        FROM attendance_records ar 
        LEFT JOIN students s ON ar.student_id = s.student_id 
        LEFT JOIN events e ON ar.event_id = e.id
        WHERE ar.id = ?
      `, [result.id]);
      
      res.status(201).json({
        action: 'check_in',
        message: 'Checked in successfully!',
        record: {
          ...newRecord,
          is_checked_out: Boolean(newRecord.is_checked_out)
        }
      });
    }
  } catch (error) {
    console.error('Error processing attendance:', error);
    res.status(500).json({ error: 'Failed to process attendance' });
  }
});

// Manual check-out (admin function)
router.patch('/:id/checkout', async (req, res) => {
  try {
    const { id } = req.params;
    const db = await getDB();
    
    const record = await db.get('SELECT * FROM attendance_records WHERE id = ? AND is_checked_out = 0', [id]);
    if (!record) {
      return res.status(404).json({ error: 'Active attendance record not found' });
    }
    
    const checkOutTime = new Date().toISOString();
    const checkInTime = new Date(record.check_in_time);
    const duration = new Date(checkOutTime) - checkInTime;
    const points = calculatePoints(duration);
    
    await db.run(`
      UPDATE attendance_records 
      SET check_out_time = ?, points = ?, is_checked_out = 1, updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `, [checkOutTime, points, id]);
    
    // Update student's total points
    await db.run(`
      UPDATE students 
      SET total_points = total_points + ?, updated_at = CURRENT_TIMESTAMP
      WHERE student_id = ?
    `, [points, record.student_id]);
    
    const updatedRecord = await db.get(`
      SELECT ar.*, s.name as student_name, e.name as event_name 
      FROM attendance_records ar 
      LEFT JOIN students s ON ar.student_id = s.student_id 
      LEFT JOIN events e ON ar.event_id = e.id
      WHERE ar.id = ?
    `, [id]);
    
    res.json({
      message: 'Manual check-out completed',
      record: {
        ...updatedRecord,
        is_checked_out: Boolean(updatedRecord.is_checked_out)
      }
    });
  } catch (error) {
    console.error('Error processing manual checkout:', error);
    res.status(500).json({ error: 'Failed to process manual checkout' });
  }
});

// Delete attendance record
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const db = await getDB();
    
    // Get the record to subtract points if necessary
    const record = await db.get('SELECT * FROM attendance_records WHERE id = ?', [id]);
    if (!record) {
      return res.status(404).json({ error: 'Attendance record not found' });
    }
    
    // If the record has points, subtract them from student's total
    if (record.points > 0) {
      await db.run(`
        UPDATE students 
        SET total_points = total_points - ?, updated_at = CURRENT_TIMESTAMP
        WHERE student_id = ?
      `, [record.points, record.student_id]);
    }
    
    // Delete the record
    await db.run('DELETE FROM attendance_records WHERE id = ?', [id]);
    
    res.json({ message: 'Attendance record deleted successfully' });
  } catch (error) {
    console.error('Error deleting attendance record:', error);
    res.status(500).json({ error: 'Failed to delete attendance record' });
  }
});

// Helper function to calculate points based on duration
function calculatePoints(durationMs) {
  const minutes = Math.floor(durationMs / (1000 * 60));
  if (minutes < 15) return 1; // Minimum attendance
  if (minutes < 30) return 3;
  if (minutes < 60) return 5;
  if (minutes < 120) return 8;
  return 10; // Maximum points for 2+ hours
}

module.exports = router;
