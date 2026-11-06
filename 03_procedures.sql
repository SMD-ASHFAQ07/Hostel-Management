-- ====================================================================
-- College Hostel Management System
-- Stored Procedures for Warden Management Operations
-- ====================================================================

USE college_hostel_db;

DROP PROCEDURE IF EXISTS sp_allocate_room;
DROP PROCEDURE IF EXISTS sp_vacate_room;
DROP PROCEDURE IF EXISTS sp_update_student_details;
DROP PROCEDURE IF EXISTS sp_get_student_hostel_profile;

DELIMITER $$

-- --------------------------------------------------------------------
-- Procedure 1: Warden allocates a room to a student
-- --------------------------------------------------------------------
CREATE PROCEDURE sp_allocate_room(
    IN p_student_id INT,
    IN p_room_id INT
)
BEGIN
    DECLARE v_student_exists INT;
    DECLARE v_room_exists INT;

    -- Verify student exists
    SELECT COUNT(*) INTO v_student_exists FROM students WHERE student_id = p_student_id;
    IF v_student_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Warden Action Error: Student ID not found.';
    END IF;

    -- Verify room exists
    SELECT COUNT(*) INTO v_room_exists FROM rooms WHERE room_id = p_room_id;
    IF v_room_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Warden Action Error: Room ID not found.';
    END IF;

    -- Insert allocation (Validation triggers will ensure capacity and active allocation check)
    INSERT INTO allocations (student_id, room_id, allocation_date, status)
    VALUES (p_student_id, p_room_id, CURDATE(), 'Active');

    SELECT CONCAT('Success: Student ', p_student_id, ' successfully allocated to Room ID ', p_room_id) AS result_message;
END$$

-- --------------------------------------------------------------------
-- Procedure 2: Warden vacates a student from their allocated room
-- --------------------------------------------------------------------
CREATE PROCEDURE sp_vacate_room(
    IN p_student_id INT
)
BEGIN
    DECLARE v_allocation_id INT;

    -- Find active allocation
    SELECT allocation_id INTO v_allocation_id
    FROM allocations
    WHERE student_id = p_student_id AND status = 'Active'
    LIMIT 1;

    IF v_allocation_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Warden Action Error: No active room allocation found for this student.';
    END IF;

    -- Update allocation record
    UPDATE allocations
    SET status = 'Vacated',
        vacate_date = CURDATE()
    WHERE allocation_id = v_allocation_id;

    SELECT CONCAT('Success: Student ', p_student_id, ' has vacated the room.') AS result_message;
END$$

-- --------------------------------------------------------------------
-- Procedure 3: Update student and parent contact details
-- --------------------------------------------------------------------
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

-- --------------------------------------------------------------------
-- Procedure 4: View complete student hostel profile
-- --------------------------------------------------------------------
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
