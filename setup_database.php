<?php
$host = 'localhost';
$dbname = 'learning_platform';
$user = 'root';
$pass = '';

try {
    $pdo = new PDO("mysql:host=$host", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $pdo->exec("CREATE DATABASE IF NOT EXISTS $dbname");
    $pdo->exec("USE $dbname");
    
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            email VARCHAR(255) UNIQUE NOT NULL,
            password VARCHAR(255) NOT NULL,
            theme VARCHAR(20) DEFAULT 'dark',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ");
    
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS progress (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            course VARCHAR(50) NOT NULL,
            lesson_id INT NOT NULL,
            completed BOOLEAN DEFAULT FALSE,
            quiz_score INT DEFAULT 0,
            completed_at TIMESTAMP NULL,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            UNIQUE KEY unique_progress (user_id, course, lesson_id)
        )
    ");

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS login_events (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
    ");
    
    echo "Database setup complete!";
} catch (PDOException $e) {
    die("Database error: " . $e->getMessage());
}
