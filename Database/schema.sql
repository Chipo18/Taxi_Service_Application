CREATE DATABASE IF NOT EXISTS taxi_service_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE taxi_service_db;

CREATE TABLE IF NOT EXISTS users (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    username    VARCHAR(100) NOT NULL,
    email       VARCHAR(120) NOT NULL UNIQUE,
    password    VARCHAR(200) NOT NULL,
    role        VARCHAR(20) NOT NULL DEFAULT 'customer',
    is_active   BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS drivers (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    user_id         INT NOT NULL,
    car_details     VARCHAR(200),
    latitude        FLOAT,
    longitude       FLOAT,
    is_available    BOOLEAN DEFAULT TRUE,
    is_verified     BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS pricing (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    zone_name       VARCHAR(100) DEFAULT 'default',
    base_fare       FLOAT NOT NULL DEFAULT 200.0,
    price_per_km    FLOAT NOT NULL DEFAULT 100.0,
    minimum_fare    FLOAT NOT NULL DEFAULT 250.0,
    night_surcharge FLOAT DEFAULT 13.0,
    is_active       BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS trips (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    user_id             INT NOT NULL,
    driver_id           INT,
    pickup_lat          FLOAT NOT NULL,
    pickup_lng          FLOAT NOT NULL,
    pickup_address      VARCHAR(255),
    dropoff_lat         FLOAT NOT NULL,
    dropoff_lng         FLOAT NOT NULL,
    dropoff_address     VARCHAR(255),
    status              VARCHAR(50) DEFAULT 'requested',
    estimated_price     FLOAT,
    final_price         FLOAT,
    distance_km         FLOAT,
    requested_at        DATETIME DEFAULT CURRENT_TIMESTAMP,
    started_at          DATETIME,
    completed_at        DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (driver_id) REFERENCES drivers(id)
);