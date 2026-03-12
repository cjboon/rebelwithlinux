<?php
if (session_status() === PHP_SESSION_NONE) {
    ini_set('session.cookie_lifetime', 86400);
    ini_set('session.gc_maxlifetime', 86400);
    session_start();
}

function getDB() {
    $socket = '/run/mysqld/mysqld.sock';
    $dbname = getenv('DB_NAME') ?: 'learning_platform';
    $user = getenv('DB_USER') ?: 'webuser';
    $pass = getenv('DB_PASS') ?: 'webpass';
    static $pdo = null;

    if ($pdo === null) {
        try {
            $pdo = new PDO("mysql:dbname=$dbname;unix_socket=$socket", $user, $pass);
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch (PDOException $e) {
            http_response_code(500);
            die(json_encode(['error' => 'Database connection failed']));
        }
    }

    return $pdo;
}

function getCurrentUserId() {
    return $_SESSION['user_id'] ?? null;
}
