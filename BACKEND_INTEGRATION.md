# Backend Integration Guide
## College Club & Events Management System

This document explains how to integrate the frontend application with a SQL database backend.

---

## Architecture Overview

The application uses a **3-tier architecture**:

1. **Frontend (HTML/CSS/JavaScript)**: User interface and client-side logic
2. **Backend API (Node.js/Express recommended)**: RESTful API endpoints
3. **Database (MySQL/PostgreSQL)**: Data persistence layer

---

## Current Implementation

The application currently uses **localStorage** to simulate a database. All data is stored in the browser and persists across sessions. The `BackendAPI` object in `main.html` provides a complete API layer that mirrors how a real backend would work.

---

## Database Setup

### 1. Install Database Server

**MySQL:**
```bash
# Ubuntu/Debian
sudo apt-get install mysql-server

# macOS
brew install mysql
```

**PostgreSQL:**
```bash
# Ubuntu/Debian
sudo apt-get install postgresql postgresql-contrib

# macOS
brew install postgresql
```

### 2. Create Database

```sql
CREATE DATABASE club_management;
USE club_management;
```

### 3. Run Schema

```bash
mysql -u root -p club_management < database-schema.sql
# OR for PostgreSQL:
psql -U postgres -d club_management -f database-schema.sql
```

---

## Backend API Implementation

### Recommended Stack

- **Node.js** with **Express.js** framework
- **mysql2** or **pg** for database connection
- **bcrypt** for password hashing
- **jsonwebtoken** for authentication
- **cors** for cross-origin requests

### Installation

```bash
npm init -y
npm install express mysql2 bcrypt jsonwebtoken cors dotenv
```

### Sample Backend Server (server.js)

```javascript
const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(express.json());
app.use(cors());

// Database connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'club_management',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Middleware to verify JWT token
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access denied' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid token' });
    }
    req.user = user;
    next();
  });
};

// ========================================
// AUTHENTICATION ENDPOINTS
// ========================================

// Register new user
app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password, full_name, role, department, year } = req.body;

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    const [result] = await pool.execute(
      'INSERT INTO users (email, password, full_name, role, department, year) VALUES (?, ?, ?, ?, ?, ?)',
      [email, hashedPassword, full_name, role || 'student', department, year]
    );

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      userId: result.insertId
    });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      res.status(400).json({ success: false, error: 'Email already exists' });
    } else {
      res.status(500).json({ success: false, error: error.message });
    }
  }
});

// Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    const [users] = await pool.execute(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );

    if (users.length === 0) {
      return res.status(401).json({ success: false, error: 'Invalid credentials' });
    }

    const user = users[0];
    const validPassword = await bcrypt.compare(password, user.password);

    if (!validPassword) {
      return res.status(401).json({ success: false, error: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    // Don't send password back
    delete user.password;

    res.json({
      success: true,
      token,
      user
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ========================================
// USER ENDPOINTS
// ========================================

// Get current user
app.get('/api/users/me', authenticateToken, async (req, res) => {
  try {
    const [users] = await pool.execute(
      'SELECT id, email, full_name, role, department, year, created_at FROM users WHERE id = ?',
      [req.user.id]
    );

    if (users.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    res.json({ success: true, data: users[0] });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Update user
app.put('/api/users/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { full_name, department, year } = req.body;

    await pool.execute(
      'UPDATE users SET full_name = ?, department = ?, year = ? WHERE id = ?',
      [full_name, department, year, id]
    );

    res.json({ success: true, message: 'User updated successfully' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ========================================
// CLUB ENDPOINTS
// ========================================

// Get all clubs
app.get('/api/clubs', async (req, res) => {
  try {
    const { category } = req.query;
    let query = 'SELECT * FROM clubs';
    let params = [];

    if (category) {
      query += ' WHERE category = ?';
      params.push(category);
    }

    const [clubs] = await pool.execute(query, params);
    res.json({ success: true, data: clubs });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get club by ID
app.get('/api/clubs/:id', async (req, res) => {
  try {
    const [clubs] = await pool.execute(
      'SELECT * FROM clubs WHERE id = ?',
      [req.params.id]
    );

    if (clubs.length === 0) {
      return res.status(404).json({ success: false, error: 'Club not found' });
    }

    res.json({ success: true, data: clubs[0] });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Create club (admin only)
app.post('/api/clubs', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    const { name, description, category, faculty_coordinator, student_head_id, established_date } = req.body;

    const [result] = await pool.execute(
      'INSERT INTO clubs (name, description, category, faculty_coordinator, student_head_id, established_date) VALUES (?, ?, ?, ?, ?, ?)',
      [name, description, category, faculty_coordinator, student_head_id, established_date]
    );

    res.status(201).json({
      success: true,
      message: 'Club created successfully',
      clubId: result.insertId
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Update club (admin only)
app.put('/api/clubs/:id', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    const { id } = req.params;
    const { name, description, category, faculty_coordinator, student_head_id } = req.body;

    await pool.execute(
      'UPDATE clubs SET name = ?, description = ?, category = ?, faculty_coordinator = ?, student_head_id = ? WHERE id = ?',
      [name, description, category, faculty_coordinator, student_head_id, id]
    );

    res.json({ success: true, message: 'Club updated successfully' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Delete club (admin only)
app.delete('/api/clubs/:id', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    await pool.execute('DELETE FROM clubs WHERE id = ?', [req.params.id]);
    res.json({ success: true, message: 'Club deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ========================================
// EVENT ENDPOINTS
// ========================================

// Get all events
app.get('/api/events', async (req, res) => {
  try {
    const { club_id, upcoming } = req.query;
    let query = 'SELECT * FROM events WHERE 1=1';
    let params = [];

    if (club_id) {
      query += ' AND club_id = ?';
      params.push(club_id);
    }

    if (upcoming) {
      query += ' AND event_date >= CURDATE()';
    }

    query += ' ORDER BY event_date ASC';

    const [events] = await pool.execute(query, params);
    res.json({ success: true, data: events });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Create event
app.post('/api/events', authenticateToken, async (req, res) => {
  try {
    const { club_id, name, description, event_date, event_time, venue, max_participants, registration_deadline } = req.body;

    const [result] = await pool.execute(
      'INSERT INTO events (club_id, name, description, event_date, event_time, venue, max_participants, registration_deadline, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [club_id, name, description, event_date, event_time, venue, max_participants, registration_deadline, req.user.id]
    );

    res.status(201).json({
      success: true,
      message: 'Event created successfully',
      eventId: result.insertId
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ========================================
// MEMBERSHIP ENDPOINTS
// ========================================

// Get user memberships
app.get('/api/memberships/user/:userId', authenticateToken, async (req, res) => {
  try {
    const [memberships] = await pool.execute(
      `SELECT m.*, c.name as club_name, c.category 
       FROM memberships m 
       JOIN clubs c ON m.club_id = c.id 
       WHERE m.user_id = ?`,
      [req.params.userId]
    );

    res.json({ success: true, data: memberships });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Request club membership
app.post('/api/memberships', authenticateToken, async (req, res) => {
  try {
    const { club_id } = req.body;

    const [result] = await pool.execute(
      'INSERT INTO memberships (user_id, club_id, status, joined_date) VALUES (?, ?, ?, CURDATE())',
      [req.user.id, club_id, 'pending']
    );

    res.status(201).json({
      success: true,
      message: 'Membership request submitted',
      membershipId: result.insertId
    });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      res.status(400).json({ success: false, error: 'Already a member or request pending' });
    } else {
      res.status(500).json({ success: false, error: error.message });
    }
  }
});

// Approve/reject membership (admin only)
app.put('/api/memberships/:id/status', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    const { status } = req.body;

    // Use stored procedure for approval
    if (status === 'approved') {
      await pool.execute('CALL approve_membership(?)', [req.params.id]);
    } else {
      await pool.execute(
        'UPDATE memberships SET status = ? WHERE id = ?',
        [status, req.params.id]
      );
    }

    res.json({ success: true, message: 'Membership status updated' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ========================================
// REGISTRATION ENDPOINTS
// ========================================

// Register for event
app.post('/api/registrations', authenticateToken, async (req, res) => {
  try {
    const { event_id } = req.body;

    // Use stored procedure
    await pool.execute('CALL register_for_event(?, ?)', [req.user.id, event_id]);

    res.status(201).json({
      success: true,
      message: 'Successfully registered for event'
    });
  } catch (error) {
    if (error.sqlMessage && error.sqlMessage.includes('full')) {
      res.status(400).json({ success: false, error: 'Event is full' });
    } else {
      res.status(500).json({ success: false, error: error.message });
    }
  }
});

// Get user registrations
app.get('/api/registrations/user/:userId', authenticateToken, async (req, res) => {
  try {
    const [registrations] = await pool.execute(
      `SELECT r.*, e.name as event_name, e.event_date, e.venue, c.name as club_name
       FROM registrations r
       JOIN events e ON r.event_id = e.id
       JOIN clubs c ON e.club_id = c.id
       WHERE r.user_id = ?`,
      [req.params.userId]
    );

    res.json({ success: true, data: registrations });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ========================================
// ANALYTICS ENDPOINTS
// ========================================

// Get dashboard statistics
app.get('/api/analytics/dashboard', authenticateToken, async (req, res) => {
  try {
    const [clubCount] = await pool.execute('SELECT COUNT(*) as count FROM clubs');
    const [eventCount] = await pool.execute('SELECT COUNT(*) as count FROM events WHERE event_date >= CURDATE()');
    const [memberCount] = await pool.execute('SELECT COUNT(*) as count FROM memberships WHERE status = "approved"');
    const [pendingCount] = await pool.execute('SELECT COUNT(*) as count FROM memberships WHERE status = "pending"');

    res.json({
      success: true,
      data: {
        totalClubs: clubCount[0].count,
        upcomingEvents: eventCount[0].count,
        totalMemberships: memberCount[0].count,
        pendingRequests: pendingCount[0].count
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ========================================
// START SERVER
// ========================================

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

---

## Environment Variables

Create a `.env` file:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=club_management
JWT_SECRET=your_super_secret_jwt_key_change_this
PORT=3000
```

---

## Frontend Integration

### Update API Configuration

In `main.html`, modify the `BackendAPI.config`:

```javascript
const BackendAPI = {
    config: {
        apiUrl: 'http://localhost:3000/api',  // Point to your backend
        localStorage: false,  // Disable localStorage
        autoSave: false
    },
    // ... rest of the code
}
```

### Update API Calls

Replace localStorage operations with fetch calls:

```javascript
// Example: User login
async function handleLogin(email, password) {
    try {
        const response = await fetch(`${BackendAPI.config.apiUrl}/auth/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ email, password })
        });

        const data = await response.json();
        
        if (data.success) {
            localStorage.setItem('authToken', data.token);
            localStorage.setItem('currentUser', JSON.stringify(data.user));
            // Redirect to dashboard
        } else {
            alert(data.error);
        }
    } catch (error) {
        console.error('Login error:', error);
    }
}
```

---

## Deployment

### Production Checklist

1. **Security**
   - Use HTTPS for all requests
   - Implement rate limiting
   - Add input validation and sanitization
   - Use prepared statements (already done)
   - Hash all passwords with bcrypt
   - Set secure JWT secret

2. **Database**
   - Create database backups
   - Set up connection pooling
   - Add database indices (already done)
   - Enable query logging

3. **Server**
   - Use environment variables
   - Enable CORS properly
   - Add error logging (Winston, Morgan)
   - Implement request validation

4. **Frontend**
   - Minify JavaScript and CSS
   - Enable gzip compression
   - Use CDN for static assets
   - Implement service workers for offline support

---

## Testing

### API Testing with Postman/curl

```bash
# Register user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password123","full_name":"Test User"}'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password123"}'

# Get clubs (with token)
curl http://localhost:3000/api/clubs \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## Troubleshooting

### Common Issues

1. **CORS errors**: Make sure CORS is enabled in your backend
2. **Database connection failed**: Check credentials in `.env`
3. **Token expired**: Implement token refresh mechanism
4. **Port already in use**: Change PORT in `.env`

---

## Additional Resources

- [Express.js Documentation](https://expressjs.com/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [JWT Best Practices](https://jwt.io/)
- [REST API Design Guide](https://restfulapi.net/)

---

## Support

For issues or questions:
- Check the database logs
- Review API endpoint responses
- Test with sample data from `database-schema.sql`