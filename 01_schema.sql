-- ====================================================================
-- College Hostel Management System
-- Database Schema Definition (MySQL 8.0 / MySQL Workbench)
-- Project Code: T11
-- ====================================================================

CREATE DATABASE IF NOT EXISTS college_hostel_db;
USE college_hostel_db;

-- --------------------------------------------------------------------
-- Drop existing tables to ensure a clean setup (in dependency order)
-- --------------------------------------------------------------------
DROP TABLE IF EXISTS allocations;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS students;

-- --------------------------------------------------------------------
-- 1. Students Table
-- Stores student profile and emergency contact details
-- --------------------------------------------------------------------
CREATE TABLE students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    roll_no VARCHAR(30) NOT NULL UNIQUE,
    branch VARCHAR(50) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    parent_phone VARCHAR(15) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------------------
-- 2. Rooms Table
-- Stores hostel room information, bed capacity, occupancy, and status
-- --------------------------------------------------------------------
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

-- --------------------------------------------------------------------
-- 3. Allocations Table
-- Tracks student room allocations, dates, and allocation statuses
-- --------------------------------------------------------------------
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

-- Indexes for performance optimization on common search columns
CREATE INDEX idx_students_roll_no ON students(roll_no);
CREATE INDEX idx_rooms_block ON rooms(block_name);
CREATE INDEX idx_allocations_status ON allocations(status);
