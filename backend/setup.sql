CREATE DATABASE IF NOT EXISTS auraaxon;
USE auraaxon;

CREATE TABLE IF NOT EXISTS products (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    version VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    releaseDate VARCHAR(50) NOT NULL
);

-- Insert dummy data for initial testing
INSERT INTO products (id, name, version, status, releaseDate) VALUES 
('API-PRD-001', 'Auraaxon Pro (from DB)', 'v2.1.0', 'Active', '2023-10-15'),
('API-PRD-002', 'Auraaxon Starter (from DB)', 'v1.5.2', 'Active', '2023-08-22');
