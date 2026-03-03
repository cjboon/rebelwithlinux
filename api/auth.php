<?php
header('Content-Type: application/json');
session_start();
require_once 'db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    $action = $_POST['action'] ?? '';
    if ($action === 'register') {
        register();
    } elseif ($action === 'login') {
        login();
    } elseif ($action === 'logout') {
        logout();
    } else {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid action']);
    }
} elseif ($method === 'GET' && ($_GET['action'] ?? '') === 'check') {
    checkAuth();
}

function register() {
    $email = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid email address']);
        return;
    }

    if (strlen($password) < 6) {
        http_response_code(400);
        echo json_encode(['error' => 'Password must be at least 6 characters']);
        return;
    }

    $pdo = getDB();
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->execute([$email]);

    if ($stmt->fetch()) {
        http_response_code(400);
        echo json_encode(['error' => 'Email already registered']);
        return;
    }

    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
    $stmt = $pdo->prepare("INSERT INTO users (email, password) VALUES (?, ?)");
    $stmt->execute([$email, $hashedPassword]);

    $_SESSION['user_id'] = $pdo->lastInsertId();
    $_SESSION['email'] = $email;
    echo json_encode(['success' => true, 'email' => $email]);
}

function login() {
    $email = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';

    $pdo = getDB();
    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    if (!$user || !password_verify($password, $user['password'])) {
        http_response_code(401);
        echo json_encode(['error' => 'Invalid email or password']);
        return;
    }

    $_SESSION['user_id'] = $user['id'];
    $_SESSION['email'] = $user['email'];

    $stmt = $pdo->prepare("INSERT INTO login_events (user_id) VALUES (?)");
    $stmt->execute([$user['id']]);

    echo json_encode(['success' => true, 'email' => $email]);
}

function logout() {
    session_destroy();
    echo json_encode(['success' => true]);
}

function checkAuth() {
    if (isset($_SESSION['user_id'])) {
        echo json_encode(['authenticated' => true, 'email' => $_SESSION['email']]);
    } else {
        echo json_encode(['authenticated' => false]);
    }
}
