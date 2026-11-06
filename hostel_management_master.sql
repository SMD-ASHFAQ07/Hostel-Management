-- ====================================================================
-- COLLEGE HOSTEL MANAGEMENT SYSTEM
-- Master All-In-One Database Script for MySQL Workbench
-- Project Code: T11
-- ====================================================================

-- --------------------------------------------------------------------
-- STEP 1: CREATE DATABASE & USE
-- --------------------------------------------------------------------
DROP DATABASE IF EXISTS college_hostel_db;
CREATE DATABASE college_hostel_db;
USE college_hostel_db;

-- --------------------------------------------------------------------
-- STEP 2: CREATE TABLES
-- --------------------------------------------------------------------

-- Table 1: students
CREATE TABLE students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    roll_no VARCHAR(30) NOT NULL UNIQUE,
    branch VARCHAR(50) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    parent_phone VARCHAR(15) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table 2: rooms
CREATE TABLE rooms (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    room_no VARCHAR(20) NOT NULL,
    block_name VARCHAR(50) NOT NULL,
    capacity INT NOT NULL DEFAULT 2,
    occupied INT NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'Available',
    CONSTRAINT uq_block_room UNIQUE (block_name, room_no),
    CONSTRAINT chk_capacity CHECK (capacity > 0),
    CONSTRAINT chk_occupied CHECK (occupied >= 0 AND occupied <= capacity),
    CONSTRAINT chk_room_status CHECK (status IN ('Available', 'Full', 'Maintenance'))
);

-- Table 3: allocations
CREATE TABLE allocations (
    allocation_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    room_id INT NOT NULL,
    allocation_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    vacate_date DATE DEFAULT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    CONSTRAINT fk_alloc_student FOREIGN KEY (student_id) 
        REFERENCES students(student_id) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE,
    CONSTRAINT fk_alloc_room FOREIGN KEY (room_id) 
        REFERENCES rooms(room_id) 
        ON UPDATE CASCADE 
        ON DELETE RESTRICT,
    CONSTRAINT chk_alloc_status CHECK (status IN ('Active', 'Vacated', 'Cancelled'))
);

-- Performance Indexes
CREATE INDEX idx_students_roll_no ON students(roll_no);
CREATE INDEX idx_rooms_block ON rooms(block_name);
CREATE INDEX idx_allocations_status ON allocations(status);

-- --------------------------------------------------------------------
-- STEP 3: AUTOMATED BUSINESS LOGIC TRIGGERS
-- --------------------------------------------------------------------
DELIMITER $$

-- Trigger 1: Validation before allocation (Prevent double rooming and overbooking)
CREATE TRIGGER trg_before_allocation_insert
BEFORE INSERT ON allocations
FOR EACH ROW
BEGIN
    DECLARE v_active_count INT;
    DECLARE v_occupied INT;
    DECLARE v_capacity INT;
    DECLARE v_room_status VARCHAR(20);

    IF NEW.status = 'Active' THEN
        -- Check if student already holds an active room
        SELECT COUNT(*) INTO v_active_count
        FROM allocations
        WHERE student_id = NEW.student_id AND status = 'Active';

        IF v_active_count > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Validation Error: Student already has an active room allocation.';
        END IF;

        -- Check room capacity and maintenance state
        SELECT occupied, capacity, status INTO v_occupied, v_capacity, v_room_status
        FROM rooms
        WHERE room_id = NEW.room_id;

        IF v_room_status = 'Maintenance' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Validation Error: Cannot allocate. Room is currently under Maintenance.';
        END IF;

        IF v_occupied >= v_capacity THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Validation Error: Cannot allocate room. Room is already at full capacity.';
        END IF;
    END IF;
END$$

-- Trigger 2: Auto-increment room occupied count & mark Full
CREATE TRIGGER trg_after_allocation_insert
AFTER INSERT ON allocations
FOR EACH ROW
BEGIN
    IF NEW.status = 'Active' THEN
        UPDATE rooms
        SET occupied = occupied + 1,
            status = CASE 
                WHEN (occupied + 1) >= capacity THEN 'Full'
                ELSE 'Available'
            END
        WHERE room_id = NEW.room_id;
    END IF;
END$$

-- Trigger 3: Auto-decrement room occupied count on vacating
CREATE TRIGGER trg_after_allocation_update
AFTER UPDATE ON allocations
FOR EACH ROW
BEGIN
    IF OLD.status = 'Active' AND NEW.status IN ('Vacated', 'Cancelled') THEN
        UPDATE rooms
        SET occupied = GREATEST(0, occupied - 1),
            status = 'Available'
        WHERE room_id = NEW.room_id;
    ELSEIF OLD.status IN ('Vacated', 'Cancelled') AND NEW.status = 'Active' THEN
        UPDATE rooms
        SET occupied = occupied + 1,
            status = CASE 
                WHEN (occupied + 1) >= capacity THEN 'Full'
                ELSE 'Available'
            END
        WHERE room_id = NEW.room_id;
    END IF;
END$$

-- Trigger 4: Safety decrement on allocation delete
CREATE TRIGGER trg_after_allocation_delete
AFTER DELETE ON allocations
FOR EACH ROW
BEGIN
    IF OLD.status = 'Active' THEN
        UPDATE rooms
        SET occupied = GREATEST(0, occupied - 1),
            status = 'Available'
        WHERE room_id = OLD.room_id;
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------------------
-- STEP 4: STORED PROCEDURES FOR WARDEN ACTIONS
-- --------------------------------------------------------------------
DELIMITER $$

-- Procedure 1: Warden allocates a room to a student
CREATE PROCEDURE sp_allocate_room(
    IN p_student_id INT,
    IN p_room_id INT
)
BEGIN
    DECLARE v_student_exists INT;
    DECLARE v_room_exists INT;

    SELECT COUNT(*) INTO v_student_exists FROM students WHERE student_id = p_student_id;
    IF v_student_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Warden Action Error: Student ID not found.';
    END IF;

    SELECT COUNT(*) INTO v_room_exists FROM rooms WHERE room_id = p_room_id;
    IF v_room_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Warden Action Error: Room ID not found.';
    END IF;

    INSERT INTO allocations (student_id, room_id, allocation_date, status)
    VALUES (p_student_id, p_room_id, CURDATE(), 'Active');

    SELECT CONCAT('Success: Student ', p_student_id, ' successfully allocated to Room ID ', p_room_id) AS result_message;
END$$

-- Procedure 2: Warden vacates a student
CREATE PROCEDURE sp_vacate_room(
    IN p_student_id INT
)
BEGIN
    DECLARE v_allocation_id INT;

    SELECT allocation_id INTO v_allocation_id
    FROM allocations
    WHERE student_id = p_student_id AND status = 'Active'
    LIMIT 1;

    IF v_allocation_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Warden Action Error: No active room allocation found for this student.';
    END IF;

    UPDATE allocations
    SET status = 'Vacated',
        vacate_date = CURDATE()
    WHERE allocation_id = v_allocation_id;

    SELECT CONCAT('Success: Student ', p_student_id, ' has vacated the room.') AS result_message;
END$$

-- Procedure 3: Update student contact details
CREATE PROCEDURE sp_update_student_details(
    IN p_student_id INT,
    IN p_phone VARCHAR(15),
    IN p_parent_phone VARCHAR(15)
)
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count FROM students WHERE student_id = p_student_id;

    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Warden Action Error: Student does not exist.';
    END IF;

    UPDATE students
    SET phone = p_phone,
        parent_phone = p_parent_phone
    WHERE student_id = p_student_id;

    SELECT CONCAT('Success: Contact details updated for student ID ', p_student_id) AS result_message;
END$$

-- Procedure 4: View student hostel profile
CREATE PROCEDURE sp_get_student_hostel_profile(
    IN p_student_id INT
)
BEGIN
    SELECT 
        s.student_id,
        s.name AS student_name,
        s.roll_no,
        s.branch,
        s.phone AS student_phone,
        s.parent_phone,
        r.room_no,
        r.block_name,
        a.allocation_date,
        a.vacate_date,
        COALESCE(a.status, 'Not Allocated') AS allocation_status
    FROM students s
    LEFT JOIN allocations a ON s.student_id = a.student_id AND a.status = 'Active'
    LEFT JOIN rooms r ON a.room_id = r.room_id
    WHERE s.student_id = p_student_id;
END$$

DELIMITER ;

-- --------------------------------------------------------------------
-- STEP 5: VIEWS FOR MONITORING & REPORTING
-- --------------------------------------------------------------------

-- View 1: Active allocations with student & room details
CREATE OR REPLACE VIEW vw_active_allocations AS
SELECT 
    a.allocation_id,
    s.student_id,
    s.roll_no,
    s.name AS student_name,
    s.branch,
    s.phone AS student_phone,
    s.parent_phone,
    r.room_id,
    r.room_no,
    r.block_name,
    a.allocation_date,
    a.status AS allocation_status
FROM allocations a
JOIN students s ON a.student_id = s.student_id
JOIN rooms r ON a.room_id = r.room_id
WHERE a.status = 'Active';

-- View 2: Live Room Occupancy Report
CREATE OR REPLACE VIEW vw_room_occupancy_report AS
SELECT 
    r.room_id,
    r.block_name,
    r.room_no,
    r.capacity AS total_capacity,
    r.occupied AS currently_occupied,
    (r.capacity - r.occupied) AS available_beds,
    ROUND((r.occupied / r.capacity) * 100, 1) AS occupancy_percentage,
    r.status AS room_status
FROM rooms r
ORDER BY r.block_name, r.room_no;

-- View 3: Available Rooms for allocation
CREATE OR REPLACE VIEW vw_available_rooms AS
SELECT 
    room_id,
    block_name,
    room_no,
    capacity,
    occupied,
    (capacity - occupied) AS vacant_beds,
    status
FROM rooms
WHERE status = 'Available' AND occupied < capacity;

-- View 4: Unallocated students
CREATE OR REPLACE VIEW vw_unallocated_students AS
SELECT 
    s.student_id,
    s.roll_no,
    s.name AS student_name,
    s.branch,
    s.phone,
    s.parent_phone
FROM students s
WHERE s.student_id NOT IN (
    SELECT student_id 
    FROM allocations 
    WHERE status = 'Active'
);

-- --------------------------------------------------------------------
-- STEP 6: INSERT SAMPLE DATA
-- --------------------------------------------------------------------

-- Insert Students
INSERT INTO students (name, roll_no, branch, phone, parent_phone) VALUES
('Aarav Sharma',    '21CS001', 'Computer Science',        '9876543210', '9876543201'),
('Rohan Verma',     '21CS045', 'Computer Science',        '9876543211', '9876543202'),
('Aditya Nair',     '21EC012', 'Electronics & Comm',      '9876543212', '9876543203'),
('Karthik Reddy',   '21ME034', 'Mechanical Engineering',  '9876543213', '9876543204'),
('Priya Patel',     '21IT023', 'Information Technology',  '9876543214', '9876543205'),
('Sneha Kulkarni',  '21IT056', 'Information Technology',  '9876543215', '9876543206'),
('Ananya Gupta',    '21CS078', 'Computer Science',        '9876543216', '9876543207'),
('Vikram Singh',    '21CE019', 'Civil Engineering',       '9876543217', '9876543208'),
('Rahul Deshmukh',  '21EE040', 'Electrical Engineering',  '9876543218', '9876543209'),
('Meera Iyer',      '21AI015', 'Artificial Intelligence', '9876543219', '9876543210'),
('Kavya Menon',     '21EC044', 'Electronics & Comm',      '9876543220', '9876543211'),
('Arjun Das',       '21ME052', 'Mechanical Engineering',  '9876543221', '9876543212');

-- Insert Rooms
INSERT INTO rooms (room_no, block_name, capacity, occupied, status) VALUES
('A-101', 'Block A (Boys)',  2, 0, 'Available'),
('A-102', 'Block A (Boys)',  2, 0, 'Available'),
('A-103', 'Block A (Boys)',  3, 0, 'Available'),
('A-104', 'Block A (Boys)',  2, 0, 'Maintenance'),
('B-201', 'Block B (Girls)', 2, 0, 'Available'),
('B-202', 'Block B (Girls)', 3, 0, 'Available'),
('B-203', 'Block B (Girls)', 2, 0, 'Available'),
('C-301', 'Block C (Boys)',  4, 0, 'Available');

-- Insert Allocations (Triggers will auto-update room occupancy)
INSERT INTO allocations (student_id, room_id, allocation_date, status) VALUES
(1, 1, '2026-08-01', 'Active'),
(2, 1, '2026-08-01', 'Active'),
(3, 2, '2026-08-05', 'Active'),
(4, 3, '2026-08-10', 'Active'),
(8, 3, '2026-08-11', 'Active'),
(5, 5, '2026-08-01', 'Active'),
(6, 5, '2026-08-02', 'Active'),
(7, 6, '2026-08-05', 'Active');

-- Historical Vacated Allocation
INSERT INTO allocations (student_id, room_id, allocation_date, vacate_date, status) VALUES
(9, 2, '2026-01-10', '2026-06-30', 'Vacated');

-- --------------------------------------------------------------------
-- STEP 7: VERIFICATION QUERIES
-- --------------------------------------------------------------------
SELECT '=== ACTIVE ALLOCATIONS ===' AS Title;
SELECT * FROM vw_active_allocations;

SELECT '=== LIVE ROOM OCCUPANCY REPORT ===' AS Title;
SELECT * FROM vw_room_occupancy_report;

SELECT '=== AVAILABLE ROOMS ===' AS Title;
SELECT * FROM vw_available_rooms;

SELECT '=== UNALLOCATED STUDENTS ===' AS Title;
SELECT * FROM vw_unallocated_students;
