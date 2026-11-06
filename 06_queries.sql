-- ====================================================================
-- College Hostel Management System
-- Demonstration & Analytical Queries
-- ====================================================================

USE college_hostel_db;

-- --------------------------------------------------------------------
-- Query 1: View all currently active hostel residents
-- --------------------------------------------------------------------
SELECT 
    s.roll_no,
    s.name AS student_name,
    s.branch,
    r.block_name,
    r.room_no,
    s.phone AS student_phone,
    s.parent_phone,
    a.allocation_date
FROM allocations a
JOIN students s ON a.student_id = s.student_id
JOIN rooms r ON a.room_id = r.room_id
WHERE a.status = 'Active'
ORDER BY r.block_name, r.room_no;

-- --------------------------------------------------------------------
-- Query 2: Room occupancy monitoring report
-- --------------------------------------------------------------------
SELECT * FROM vw_room_occupancy_report;

-- --------------------------------------------------------------------
-- Query 3: Block-wise summary of capacity, occupancy, and availability
-- --------------------------------------------------------------------
SELECT 
    block_name,
    COUNT(room_id) AS total_rooms,
    SUM(capacity) AS total_capacity,
    SUM(occupied) AS total_occupied,
    SUM(capacity - occupied) AS total_vacant_beds,
    ROUND((SUM(occupied) / SUM(capacity)) * 100, 1) AS block_occupancy_rate
FROM rooms
GROUP BY block_name;

-- --------------------------------------------------------------------
-- Query 4: Find all rooms that have at least one vacant bed
-- --------------------------------------------------------------------
SELECT * FROM vw_available_rooms;

-- --------------------------------------------------------------------
-- Query 5: Find students pending hostel room allocation
-- --------------------------------------------------------------------
SELECT * FROM vw_unallocated_students;

-- --------------------------------------------------------------------
-- Query 6: Search student profile and allocation by Roll Number
-- --------------------------------------------------------------------
SELECT 
    s.student_id,
    s.roll_no,
    s.name,
    s.branch,
    s.phone,
    r.block_name,
    r.room_no,
    a.allocation_date,
    COALESCE(a.status, 'No Active Room') AS current_status
FROM students s
LEFT JOIN allocations a ON s.student_id = a.student_id AND a.status = 'Active'
LEFT JOIN rooms r ON a.room_id = r.room_id
WHERE s.roll_no = '21CS001';

-- --------------------------------------------------------------------
-- Query 7: Procedure Demo - Allocate an unallocated student (Student 10 to Room 7: B-203)
-- --------------------------------------------------------------------
CALL sp_allocate_room(10, 7);

-- Verify that B-203 occupied count increased from 0 to 1
SELECT * FROM rooms WHERE room_id = 7;

-- --------------------------------------------------------------------
-- Query 8: Procedure Demo - Vacate student 1 from Room 1 (A-101)
-- --------------------------------------------------------------------
CALL sp_vacate_room(1);

-- Verify that A-101 occupied count decreased and status changed from 'Full' to 'Available'
SELECT * FROM rooms WHERE room_id = 1;

-- --------------------------------------------------------------------
-- Query 9: Procedure Demo - Update student contact details
-- --------------------------------------------------------------------
CALL sp_update_student_details(2, '9988776655', '9988776600');

-- Verify updated phone numbers
SELECT student_id, name, roll_no, phone, parent_phone FROM students WHERE student_id = 2;

-- --------------------------------------------------------------------
-- Query 10: Trigger Safety Test - Attempt to allocate a student who already has a room
-- (This will raise error: "Validation Error: Student already has an active room allocation.")
-- --------------------------------------------------------------------
-- UNCOMMENT TO TEST ERROR HANDLING:
-- CALL sp_allocate_room(2, 2);
