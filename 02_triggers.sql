-- ====================================================================
-- College Hostel Management System
-- Automated Triggers for Room Occupancy & Validation
-- ====================================================================

USE college_hostel_db;

DROP TRIGGER IF EXISTS trg_before_allocation_insert;
DROP TRIGGER IF EXISTS trg_after_allocation_insert;
DROP TRIGGER IF EXISTS trg_after_allocation_update;
DROP TRIGGER IF EXISTS trg_after_allocation_delete;

DELIMITER $$

-- --------------------------------------------------------------------
-- Trigger 1: Validate room availability and student eligibility before allocation
-- Prevents double allocation and overbooking
-- --------------------------------------------------------------------
CREATE TRIGGER trg_before_allocation_insert
BEFORE INSERT ON allocations
FOR EACH ROW
BEGIN
    DECLARE v_active_count INT;
    DECLARE v_occupied INT;
    DECLARE v_capacity INT;
    DECLARE v_room_status VARCHAR(20);

    IF NEW.status = 'Active' THEN
        -- Check if student already holds an active allocation
        SELECT COUNT(*) INTO v_active_count
        FROM allocations
        WHERE student_id = NEW.student_id AND status = 'Active';

        IF v_active_count > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Validation Error: Student already has an active room allocation.';
        END IF;

        -- Check room capacity and maintenance status
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

-- --------------------------------------------------------------------
-- Trigger 2: Automatically update room occupancy when an allocation is created
-- --------------------------------------------------------------------
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

-- --------------------------------------------------------------------
-- Trigger 3: Automatically adjust occupancy when a room is vacated
-- --------------------------------------------------------------------
CREATE TRIGGER trg_after_allocation_update
AFTER UPDATE ON allocations
FOR EACH ROW
BEGIN
    -- Student vacating the room
    IF OLD.status = 'Active' AND NEW.status IN ('Vacated', 'Cancelled') THEN
        UPDATE rooms
        SET occupied = GREATEST(0, occupied - 1),
            status = 'Available'
        WHERE room_id = NEW.room_id;
    
    -- Reactivating an allocation
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

-- --------------------------------------------------------------------
-- Trigger 4: Safely decrement room occupancy if an active allocation is deleted
-- --------------------------------------------------------------------
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
