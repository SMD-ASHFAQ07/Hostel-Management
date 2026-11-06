-- ====================================================================
-- College Hostel Management System
-- Realistic Sample Data for Demonstration & Testing
-- ====================================================================

USE college_hostel_db;

-- --------------------------------------------------------------------
-- 1. Insert Student Records
-- --------------------------------------------------------------------
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

-- --------------------------------------------------------------------
-- 2. Insert Room Records
-- (Occupied count is initialized to 0 and will be managed by triggers)
-- --------------------------------------------------------------------
INSERT INTO rooms (room_no, block_name, capacity, occupied, status) VALUES
('A-101', 'Block A (Boys)',  2, 0, 'Available'),
('A-102', 'Block A (Boys)',  2, 0, 'Available'),
('A-103', 'Block A (Boys)',  3, 0, 'Available'),
('A-104', 'Block A (Boys)',  2, 0, 'Maintenance'),
('B-201', 'Block B (Girls)', 2, 0, 'Available'),
('B-202', 'Block B (Girls)', 3, 0, 'Available'),
('B-203', 'Block B (Girls)', 2, 0, 'Available'),
('C-301', 'Block C (Boys)',  4, 0, 'Available');

-- --------------------------------------------------------------------
-- 3. Insert Room Allocations
-- Trigger 'trg_after_allocation_insert' will auto-increment 'occupied'
-- and mark rooms as 'Full' when capacity is reached.
-- --------------------------------------------------------------------

-- A-101 (Capacity 2): Allocate 2 students -> Becomes 'Full'
INSERT INTO allocations (student_id, room_id, allocation_date, status) VALUES
(1, 1, '2026-08-01', 'Active'),
(2, 1, '2026-08-01', 'Active');

-- A-102 (Capacity 2): Allocate 1 student -> Stays 'Available' (1 slot left)
INSERT INTO allocations (student_id, room_id, allocation_date, status) VALUES
(3, 2, '2026-08-05', 'Active');

-- A-103 (Capacity 3): Allocate 2 students -> Stays 'Available' (1 slot left)
INSERT INTO allocations (student_id, room_id, allocation_date, status) VALUES
(4, 3, '2026-08-10', 'Active'),
(8, 3, '2026-08-11', 'Active');

-- B-201 (Capacity 2): Allocate 2 students -> Becomes 'Full'
INSERT INTO allocations (student_id, room_id, allocation_date, status) VALUES
(5, 5, '2026-08-01', 'Active'),
(6, 5, '2026-08-02', 'Active');

-- B-202 (Capacity 3): Allocate 1 student -> Stays 'Available' (2 slots left)
INSERT INTO allocations (student_id, room_id, allocation_date, status) VALUES
(7, 6, '2026-08-05', 'Active');

-- Historical Past Allocations (Vacated)
-- Student 9 previously stayed in A-102 and vacated
INSERT INTO allocations (student_id, room_id, allocation_date, vacate_date, status) VALUES
(9, 2, '2026-01-10', '2026-06-30', 'Vacated');

-- Students 10, 11, 12 remain unallocated for demo testing
