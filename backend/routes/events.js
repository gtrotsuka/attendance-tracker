const express = require('express');
const { getDB } = require('../database/database');
const router = express.Router();

// Get all events
router.get('/', async (req, res) => {
  try {
    const db = await getDB();
    const events = await db.all('SELECT * FROM events ORDER BY date DESC, created_at DESC');
    
    // Convert is_active from integer to boolean
    const formattedEvents = events.map(event => ({
      ...event,
      is_active: Boolean(event.is_active)
    }));
    
    res.json(formattedEvents);
  } catch (error) {
    console.error('Error fetching events:', error);
    res.status(500).json({ error: 'Failed to fetch events' });
  }
});

// Get event by ID
router.get('/:id', async (req, res) => {
  try {
    const db = await getDB();
    const event = await db.get('SELECT * FROM events WHERE id = ?', [req.params.id]);
    
    if (!event) {
      return res.status(404).json({ error: 'Event not found' });
    }
    
    // Convert is_active from integer to boolean
    const formattedEvent = {
      ...event,
      is_active: Boolean(event.is_active)
    };
    
    res.json(formattedEvent);
  } catch (error) {
    console.error('Error fetching event:', error);
    res.status(500).json({ error: 'Failed to fetch event' });
  }
});

// Get active event
router.get('/active/current', async (req, res) => {
  try {
    const db = await getDB();
    const event = await db.get('SELECT * FROM events WHERE is_active = 1 LIMIT 1');
    
    if (!event) {
      return res.status(404).json({ error: 'No active event found' });
    }
    
    // Convert is_active from integer to boolean
    const formattedEvent = {
      ...event,
      is_active: Boolean(event.is_active)
    };
    
    res.json(formattedEvent);
  } catch (error) {
    console.error('Error fetching active event:', error);
    res.status(500).json({ error: 'Failed to fetch active event' });
  }
});

// Create new event
router.post('/', async (req, res) => {
  try {
    const { name, description, date, is_active } = req.body;
    
    if (!name || !date) {
      return res.status(400).json({ error: 'Name and date are required' });
    }

    const db = await getDB();
    
    // If this event should be active, deactivate all other events first
    if (is_active) {
      await db.run('UPDATE events SET is_active = 0, updated_at = CURRENT_TIMESTAMP');
    }
    
    const result = await db.run(
      'INSERT INTO events (name, description, date, is_active) VALUES (?, ?, ?, ?)',
      [name, description || null, date, is_active ? 1 : 0]
    );
    
    const newEvent = await db.get('SELECT * FROM events WHERE id = ?', [result.id]);
    
    // Convert is_active from integer to boolean
    const formattedEvent = {
      ...newEvent,
      is_active: Boolean(newEvent.is_active)
    };
    
    res.status(201).json(formattedEvent);
  } catch (error) {
    console.error('Error creating event:', error);
    res.status(500).json({ error: 'Failed to create event' });
  }
});

// Update event
router.put('/:id', async (req, res) => {
  try {
    const { name, description, date, is_active } = req.body;
    const { id } = req.params;
    
    if (!name || !date) {
      return res.status(400).json({ error: 'Name and date are required' });
    }

    const db = await getDB();
    
    // If this event should be active, deactivate all other events first
    if (is_active) {
      await db.run('UPDATE events SET is_active = 0, updated_at = CURRENT_TIMESTAMP WHERE id != ?', [id]);
    }
    
    const result = await db.run(
      'UPDATE events SET name = ?, description = ?, date = ?, is_active = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [name, description || null, date, is_active ? 1 : 0, id]
    );
    
    if (result.changes === 0) {
      return res.status(404).json({ error: 'Event not found' });
    }
    
    const updatedEvent = await db.get('SELECT * FROM events WHERE id = ?', [id]);
    
    // Convert is_active from integer to boolean
    const formattedEvent = {
      ...updatedEvent,
      is_active: Boolean(updatedEvent.is_active)
    };
    
    res.json(formattedEvent);
  } catch (error) {
    console.error('Error updating event:', error);
    res.status(500).json({ error: 'Failed to update event' });
  }
});

// Set active event (deactivates all others)
router.patch('/:id/activate', async (req, res) => {
  try {
    const { id } = req.params;
    const db = await getDB();
    
    // Check if event exists
    const event = await db.get('SELECT id FROM events WHERE id = ?', [id]);
    if (!event) {
      return res.status(404).json({ error: 'Event not found' });
    }
    
    // Deactivate all events
    await db.run('UPDATE events SET is_active = 0, updated_at = CURRENT_TIMESTAMP');
    
    // Activate the specified event
    await db.run('UPDATE events SET is_active = 1, updated_at = CURRENT_TIMESTAMP WHERE id = ?', [id]);
    
    const updatedEvent = await db.get('SELECT * FROM events WHERE id = ?', [id]);
    
    // Convert is_active from integer to boolean
    const formattedEvent = {
      ...updatedEvent,
      is_active: Boolean(updatedEvent.is_active)
    };
    
    res.json(formattedEvent);
  } catch (error) {
    console.error('Error activating event:', error);
    res.status(500).json({ error: 'Failed to activate event' });
  }
});

// Deactivate all events
router.patch('/deactivate/all', async (req, res) => {
  try {
    const db = await getDB();
    await db.run('UPDATE events SET is_active = 0, updated_at = CURRENT_TIMESTAMP');
    res.json({ message: 'All events deactivated' });
  } catch (error) {
    console.error('Error deactivating events:', error);
    res.status(500).json({ error: 'Failed to deactivate events' });
  }
});

// Delete event
router.delete('/:id', async (req, res) => {
  try {
    const db = await getDB();
    
    // First delete associated attendance records
    await db.run('DELETE FROM attendance_records WHERE event_id = ?', [req.params.id]);
    
    // Then delete the event
    const result = await db.run('DELETE FROM events WHERE id = ?', [req.params.id]);
    
    if (result.changes === 0) {
      return res.status(404).json({ error: 'Event not found' });
    }
    
    res.json({ message: 'Event deleted successfully' });
  } catch (error) {
    console.error('Error deleting event:', error);
    res.status(500).json({ error: 'Failed to delete event' });
  }
});

module.exports = router;
