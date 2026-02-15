-- ========================================
-- COLLEGE CLUB & EVENTS MANAGEMENT SYSTEM
-- Database Schema (MySQL/PostgreSQL)
-- ========================================

-- Drop tables if they exist (for clean installation)
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS registrations;
DROP TABLE IF EXISTS memberships;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS clubs;
DROP TABLE IF EXISTS users;

-- ========================================
-- USERS TABLE
-- ========================================
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL, -- Should be hashed (bcrypt recommended)
    full_name VARCHAR(255) NOT NULL,
    role ENUM('student', 'admin', 'faculty') DEFAULT 'student',
    department VARCHAR(100),
    year INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role)
);

-- ========================================
-- CLUBS TABLE
-- ========================================
CREATE TABLE clubs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category ENUM('Technical', 'Cultural', 'Arts', 'Sports', 'Social') NOT NULL,
    faculty_coordinator VARCHAR(255) NOT NULL,
    student_head_id INT,
    established_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_head_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_category (category),
    INDEX idx_student_head (student_head_id)
);

-- ========================================
-- EVENTS TABLE
-- ========================================
CREATE TABLE events (
    id INT PRIMARY KEY AUTO_INCREMENT,
    club_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    event_time TIME NOT NULL,
    venue VARCHAR(255) NOT NULL,
    max_participants INT NOT NULL,
    registration_deadline DATE NOT NULL,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_club_id (club_id),
    INDEX idx_event_date (event_date),
    INDEX idx_created_by (created_by)
);

-- ========================================
-- MEMBERSHIPS TABLE
-- ========================================
CREATE TABLE memberships (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    club_id INT NOT NULL,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    joined_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE,
    UNIQUE KEY unique_membership (user_id, club_id),
    INDEX idx_user_id (user_id),
    INDEX idx_club_id (club_id),
    INDEX idx_status (status)
);

-- ========================================
-- REGISTRATIONS TABLE
-- ========================================
CREATE TABLE registrations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    event_id INT NOT NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('registered', 'attended', 'cancelled') DEFAULT 'registered',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
    UNIQUE KEY unique_registration (user_id, event_id),
    INDEX idx_user_id (user_id),
    INDEX idx_event_id (event_id),
    INDEX idx_status (status)
);

-- ========================================
-- NOTIFICATIONS TABLE
-- ========================================
CREATE TABLE notifications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('event_reminder', 'club_approval', 'club_rejection', 'event_registration', 'system') NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_is_read (is_read),
    INDEX idx_type (type)
);

-- ========================================
-- SAMPLE DATA
-- ========================================

-- Insert sample users
INSERT INTO users (email, password, full_name, role, department, year) VALUES
('admin@college.edu', '$2a$10$samplehash1', 'Admin User', 'admin', NULL, NULL),
('john@student.edu', '$2a$10$samplehash2', 'John Doe', 'student', 'Computer Science', 2),
('jane@student.edu', '$2a$10$samplehash3', 'Jane Smith', 'student', 'Electronics', 3),
('faculty@college.edu', '$2a$10$samplehash4', 'Dr. Faculty', 'faculty', 'Computer Science', NULL),
('alice@student.edu', '$2a$10$samplehash5', 'Alice Johnson', 'student', 'Mechanical', 1);

-- Insert sample clubs
INSERT INTO clubs (name, description, category, faculty_coordinator, student_head_id, established_date) VALUES
('Tech Club', 'Explore the latest in technology and innovation', 'Technical', 'Dr. Faculty', 2, '2020-01-15'),
('Dance Society', 'Express yourself through various dance forms', 'Cultural', 'Prof. Arts', 3, '2019-03-20'),
('Coding Warriors', 'Competitive programming and hackathons', 'Technical', 'Dr. Faculty', 2, '2021-06-10'),
('Music Band', 'Create beautiful melodies together', 'Arts', 'Prof. Music', NULL, '2018-09-05'),
('Sports Club', 'Stay fit and compete in various sports', 'Sports', 'Coach Sports', NULL, '2017-04-12');

-- Insert sample events
INSERT INTO events (club_id, name, description, event_date, event_time, venue, max_participants, registration_deadline, created_by) VALUES
(1, 'Tech Talk 2026', 'Annual technology conference featuring industry experts', '2026-03-15', '10:00:00', 'Main Auditorium', 200, '2026-03-10', 1),
(2, 'Cultural Night', 'Showcase of diverse cultural performances', '2026-03-20', '18:00:00', 'Open Air Theatre', 500, '2026-03-15', 1),
(3, 'Hackathon 2026', '24-hour coding competition with amazing prizes', '2026-04-01', '09:00:00', 'Computer Lab', 100, '2026-03-25', 2),
(4, 'Music Festival', 'Live performances by college bands', '2026-04-10', '17:00:00', 'College Ground', 1000, '2026-04-05', 1),
(1, 'AI Workshop', 'Hands-on workshop on Artificial Intelligence', '2026-03-25', '14:00:00', 'Lab 301', 50, '2026-03-20', 2);

-- Insert sample memberships
INSERT INTO memberships (user_id, club_id, status, joined_date) VALUES
(2, 1, 'approved', '2026-01-15'),
(2, 3, 'approved', '2026-01-20'),
(3, 2, 'approved', '2026-01-18'),
(3, 1, 'pending', '2026-02-10'),
(5, 1, 'pending', '2026-02-12');

-- Insert sample registrations
INSERT INTO registrations (user_id, event_id, status) VALUES
(2, 1, 'registered'),
(2, 3, 'registered'),
(3, 2, 'registered'),
(3, 1, 'registered'),
(5, 1, 'registered');

-- Insert sample notifications
INSERT INTO notifications (user_id, title, message, type, is_read) VALUES
(2, 'Welcome!', 'Welcome to Tech Club!', 'club_approval', TRUE),
(3, 'Membership Pending', 'Your membership request for Tech Club is under review', 'system', FALSE),
(2, 'Event Reminder', 'Tech Talk 2026 is coming up on March 15th', 'event_reminder', FALSE),
(3, 'Registration Confirmed', 'You are registered for Cultural Night', 'event_registration', FALSE),
(5, 'Membership Pending', 'Your request to join Tech Club is being processed', 'system', FALSE);

-- ========================================
-- USEFUL VIEWS
-- ========================================

-- View to get club statistics
CREATE VIEW club_statistics AS
SELECT 
    c.id,
    c.name,
    c.category,
    COUNT(DISTINCT m.id) as total_members,
    COUNT(DISTINCT e.id) as total_events,
    COUNT(DISTINCT CASE WHEN m.status = 'pending' THEN m.id END) as pending_requests
FROM clubs c
LEFT JOIN memberships m ON c.id = m.club_id AND m.status = 'approved'
LEFT JOIN events e ON c.id = e.club_id
GROUP BY c.id, c.name, c.category;

-- View to get event details with registration count
CREATE VIEW event_details AS
SELECT 
    e.id,
    e.name,
    e.event_date,
    e.event_time,
    e.venue,
    e.max_participants,
    c.name as club_name,
    c.category as club_category,
    COUNT(r.id) as registered_count,
    (e.max_participants - COUNT(r.id)) as available_spots
FROM events e
JOIN clubs c ON e.club_id = c.id
LEFT JOIN registrations r ON e.id = r.event_id AND r.status = 'registered'
GROUP BY e.id, e.name, e.event_date, e.event_time, e.venue, e.max_participants, c.name, c.category;

-- View to get user dashboard information
CREATE VIEW user_dashboard AS
SELECT 
    u.id as user_id,
    u.full_name,
    COUNT(DISTINCT m.club_id) as clubs_joined,
    COUNT(DISTINCT r.event_id) as events_registered,
    COUNT(DISTINCT CASE WHEN n.is_read = FALSE THEN n.id END) as unread_notifications
FROM users u
LEFT JOIN memberships m ON u.id = m.user_id AND m.status = 'approved'
LEFT JOIN registrations r ON u.id = r.user_id AND r.status = 'registered'
LEFT JOIN notifications n ON u.id = n.user_id
GROUP BY u.id, u.full_name;

-- ========================================
-- USEFUL STORED PROCEDURES
-- ========================================

-- Procedure to approve membership
DELIMITER //
CREATE PROCEDURE approve_membership(IN membership_id INT)
BEGIN
    DECLARE v_user_id INT;
    DECLARE v_club_id INT;
    DECLARE v_club_name VARCHAR(255);
    
    -- Get membership details
    SELECT user_id, club_id INTO v_user_id, v_club_id
    FROM memberships WHERE id = membership_id;
    
    -- Get club name
    SELECT name INTO v_club_name FROM clubs WHERE id = v_club_id;
    
    -- Update membership status
    UPDATE memberships SET status = 'approved' WHERE id = membership_id;
    
    -- Create notification
    INSERT INTO notifications (user_id, title, message, type)
    VALUES (v_user_id, 'Membership Approved!', 
            CONCAT('Your membership request for ', v_club_name, ' has been approved!'),
            'club_approval');
END //
DELIMITER ;

-- Procedure to register for event
DELIMITER //
CREATE PROCEDURE register_for_event(IN p_user_id INT, IN p_event_id INT)
BEGIN
    DECLARE v_current_registrations INT;
    DECLARE v_max_participants INT;
    DECLARE v_event_name VARCHAR(255);
    
    -- Get event details
    SELECT COUNT(*), e.max_participants, e.name 
    INTO v_current_registrations, v_max_participants, v_event_name
    FROM registrations r
    JOIN events e ON r.event_id = e.id
    WHERE r.event_id = p_event_id AND r.status = 'registered'
    GROUP BY e.max_participants, e.name;
    
    -- Check if event is full
    IF v_current_registrations < v_max_participants THEN
        -- Register user
        INSERT INTO registrations (user_id, event_id, status)
        VALUES (p_user_id, p_event_id, 'registered');
        
        -- Create notification
        INSERT INTO notifications (user_id, title, message, type)
        VALUES (p_user_id, 'Registration Confirmed', 
                CONCAT('You have successfully registered for ', v_event_name),
                'event_registration');
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Event is full';
    END IF;
END //
DELIMITER ;

-- ========================================
-- USEFUL QUERIES
-- ========================================

/*
-- Get all events with registration details
SELECT 
    e.name,
    e.event_date,
    c.name as club_name,
    COUNT(r.id) as registrations,
    e.max_participants,
    (e.max_participants - COUNT(r.id)) as spots_remaining
FROM events e
JOIN clubs c ON e.club_id = c.id
LEFT JOIN registrations r ON e.id = r.event_id AND r.status = 'registered'
GROUP BY e.id
ORDER BY e.event_date;

-- Get pending membership requests
SELECT 
    u.full_name,
    u.email,
    c.name as club_name,
    m.joined_date,
    m.status
FROM memberships m
JOIN users u ON m.user_id = u.id
JOIN clubs c ON m.club_id = c.id
WHERE m.status = 'pending'
ORDER BY m.joined_date;

-- Get user's clubs and upcoming events
SELECT 
    c.name as club_name,
    e.name as event_name,
    e.event_date,
    e.venue
FROM memberships m
JOIN clubs c ON m.club_id = c.id
JOIN events e ON c.id = e.club_id
WHERE m.user_id = 2 
  AND m.status = 'approved'
  AND e.event_date >= CURRENT_DATE
ORDER BY e.event_date;

-- Get club popularity statistics
SELECT 
    c.name,
    c.category,
    COUNT(DISTINCT m.user_id) as member_count,
    COUNT(DISTINCT e.id) as event_count,
    AVG(reg_count.registrations) as avg_event_attendance
FROM clubs c
LEFT JOIN memberships m ON c.id = m.club_id AND m.status = 'approved'
LEFT JOIN events e ON c.id = e.club_id
LEFT JOIN (
    SELECT event_id, COUNT(*) as registrations
    FROM registrations
    WHERE status = 'registered'
    GROUP BY event_id
) reg_count ON e.id = reg_count.event_id
GROUP BY c.id
ORDER BY member_count DESC;
*/

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================

-- Additional composite indexes for common queries
CREATE INDEX idx_membership_status_club ON memberships(club_id, status);
CREATE INDEX idx_registration_status_event ON registrations(event_id, status);
CREATE INDEX idx_events_date_club ON events(club_id, event_date);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read);

-- ========================================
-- DATABASE SETUP COMPLETE
-- ========================================

-- Display success message
SELECT 'Database schema created successfully!' as status;
SELECT 'Sample data inserted!' as status;
SELECT 'Views and procedures created!' as status;