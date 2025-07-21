const express = require('express');
const { getDB } = require('../database/database');
const router = express.Router();

// Get all students
router.get('/', async (req, res) => {
  try {
    const db = await getDB();
    const students = await db.all('SELECT * FROM students ORDER BY total_points DESC, created_at ASC');
    res.json(students);
  } catch (error) {
    console.error('Error fetching students:', error);
    res.status(500).json({ error: 'Failed to fetch students' });
  }
});

// Get student by ID
router.get('/:studentId', async (req, res) => {
  try {
    const db = await getDB();
    const student = await db.get('SELECT * FROM students WHERE student_id = ?', [req.params.studentId]);
    
    if (!student) {
      return res.status(404).json({ error: 'Student not found' });
    }
    
    res.json(student);
  } catch (error) {
    console.error('Error fetching student:', error);
    res.status(500).json({ error: 'Failed to fetch student' });
  }
});

// Create or update student
router.post('/', async (req, res) => {
  try {
    const { student_id, name, total_points } = req.body;
    
    if (!student_id) {
      return res.status(400).json({ error: 'Student ID is required' });
    }

    const db = await getDB();
    
    // Check if student exists
    const existing = await db.get('SELECT id FROM students WHERE student_id = ?', [student_id]);
    
    if (existing) {
      // Update existing student
      const result = await db.run(
        'UPDATE students SET name = ?, total_points = ?, updated_at = CURRENT_TIMESTAMP WHERE student_id = ?',
        [name || null, total_points || 0, student_id]
      );
      
      const updatedStudent = await db.get('SELECT * FROM students WHERE student_id = ?', [student_id]);
      res.json(updatedStudent);
    } else {
      // Create new student
      const result = await db.run(
        'INSERT INTO students (student_id, name, total_points) VALUES (?, ?, ?)',
        [student_id, name || null, total_points || 0]
      );
      
      const newStudent = await db.get('SELECT * FROM students WHERE id = ?', [result.id]);
      res.status(201).json(newStudent);
    }
  } catch (error) {
    console.error('Error creating/updating student:', error);
    res.status(500).json({ error: 'Failed to create/update student' });
  }
});

// Update student points
router.patch('/:studentId/points', async (req, res) => {
  try {
    const { points } = req.body;
    const { studentId } = req.params;
    
    if (typeof points !== 'number') {
      return res.status(400).json({ error: 'Points must be a number' });
    }

    const db = await getDB();
    const result = await db.run(
      'UPDATE students SET total_points = total_points + ?, updated_at = CURRENT_TIMESTAMP WHERE student_id = ?',
      [points, studentId]
    );
    
    if (result.changes === 0) {
      return res.status(404).json({ error: 'Student not found' });
    }
    
    const updatedStudent = await db.get('SELECT * FROM students WHERE student_id = ?', [studentId]);
    res.json(updatedStudent);
  } catch (error) {
    console.error('Error updating student points:', error);
    res.status(500).json({ error: 'Failed to update student points' });
  }
});

// Get leaderboard (top students by points)
router.get('/leaderboard/top', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    const db = await getDB();
    
    const leaderboard = await db.all(
      'SELECT * FROM students WHERE total_points > 0 ORDER BY total_points DESC, created_at ASC LIMIT ?',
      [limit]
    );
    
    res.json(leaderboard);
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    res.status(500).json({ error: 'Failed to fetch leaderboard' });
  }
});

// Delete student
router.delete('/:studentId', async (req, res) => {
  try {
    const db = await getDB();
    
    // First delete associated attendance records
    await db.run('DELETE FROM attendance_records WHERE student_id = ?', [req.params.studentId]);
    
    // Then delete the student
    const result = await db.run('DELETE FROM students WHERE student_id = ?', [req.params.studentId]);
    
    if (result.changes === 0) {
      return res.status(404).json({ error: 'Student not found' });
    }
    
    res.json({ message: 'Student deleted successfully' });
  } catch (error) {
    console.error('Error deleting student:', error);
    res.status(500).json({ error: 'Failed to delete student' });
  }
});

module.exports = router;
