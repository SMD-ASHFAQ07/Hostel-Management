-- ====================================================================
-- College Hostel Management System
-- Reporting Views for Hostel Monitoring & Wardens
-- ====================================================================

USE college_hostel_db;

-- --------------------------------------------------------------------
-- View 1: Active Student Room Allocations
-- Wardens can view who is staying in which room with contact details
-- --------------------------------------------------------------------
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

-- --------------------------------------------------------------------
-- View 2: Room Occupancy Monitoring Report
-- Wardens can track live occupancy status and available capacity
-- --------------------------------------------------------------------
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

-- --------------------------------------------------------------------
-- View 3: Available Rooms for New Allocation
-- Quick filter for rooms that have available slots
-- --------------------------------------------------------------------
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

-- --------------------------------------------------------------------
-- View 4: Unallocated Students
-- Identifies students pending hostel room allocation
-- --------------------------------------------------------------------
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
