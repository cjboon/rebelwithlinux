<?php
function getDB() {
    $socket = '/run/mysqld/mysqld.sock';
    $dbname = 'learning_platform';
    $user = 'webuser';
    $pass = 'webpass';
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
    session_start();
    return $_SESSION['user_id'] ?? null;
}
