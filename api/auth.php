<?php
header('Content-Type: application/json');
header('Cache-Control: no-store, no-cache, must-revalidate');
header('Pragma: no-cache');
if (session_status() === PHP_SESSION_NONE) {
    ini_set('session.cookie_lifetime', 86400);
    ini_set('session.gc_maxlifetime', 86400);
    session_start();
}
require_once 'db.php';

$method = $_SERVER['REQUEST_METHOD'];

function generateCSRFToken() {
    if (!isset($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function validateCSRFToken($token) {
    return isset($_SESSION['csrf_token']) && hash_equals($_SESSION['csrf_token'], $token);
}

function isRateLimited($action, $maxAttempts = 5, $windowSeconds = 300) {
    $ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
    $rateFile = '/tmp/rate_limit_' . $action . '_' . md5($ip);
    $now = time();
    
    if (file_exists($rateFile)) {
        $data = json_decode(file_get_contents($rateFile), true);
        if ($data && $data['expires'] > $now) {
            if ($data['attempts'] >= $maxAttempts) {
                return true;
            }
            $data['attempts']++;
            $data['expires'] = $now + $windowSeconds;
        } else {
            $data = ['attempts' => 1, 'expires' => $now + $windowSeconds];
        }
    } else {
        $data = ['attempts' => 1, 'expires' => $now + $windowSeconds];
    }
    
    file_put_contents($rateFile, json_encode($data));
    return false;
}

function checkRateLimit($action) {
    if (isRateLimited($action)) {
        http_response_code(429);
        echo json_encode(['error' => 'Too many requests. Please try again later.']);
        exit;
    }
}

if ($method === 'GET') {
    $action = $_GET['action'] ?? '';
    error_log("GET request to auth.php, action param: '$action'");
    if ($action === 'check') {
        checkAuth();
    } elseif ($action === 'csrf') {
        echo json_encode(['token' => generateCSRFToken()]);
    }
} elseif ($method === 'POST') {
    $action = $_POST['action'] ?? '';
    error_log("POST request, action: $action");
    
    // Skip rate limiting for 'check' action
    if ($action !== 'check') {
        $publicActions = ['register', 'login'];
        if (in_array($action, $publicActions)) {
            checkRateLimit($action, 10, 60); // More lenient: 10 attempts per minute
        } elseif (isset($_SESSION['user_id'])) {
            checkRateLimit($action, 20, 60);
        }
    }
    
    // Skip CSRF for now
    // if (!validateCSRFToken($_POST['csrf_token'] ?? '')) {
    //     http_response_code(403);
    //     echo json_encode(['error' => 'Invalid CSRF token']);
    //     exit;
    // }
    
    if ($action === 'register') {
        register();
    } elseif ($action === 'login') {
        login();
    } elseif ($action === 'logout') {
        logout();
    } elseif ($action === 'updateTheme') {
        updateTheme();
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
    $username = trim($_POST['username'] ?? '');

    if (strlen($username) < 3) {
        http_response_code(400);
        echo json_encode(['error' => 'Username must be at least 3 characters']);
        return;
    }

    if (!preg_match('/^[a-zA-Z0-9_]+$/', $username)) {
        http_response_code(400);
        echo json_encode(['error' => 'Username can only contain letters, numbers, and underscores']);
        return;
    }

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

    try {
        $pdo = getDB();
        
        $stmt = $pdo->prepare("SELECT id FROM users WHERE username = ?");
        $stmt->execute([$username]);
        if ($stmt->fetch()) {
            http_response_code(400);
            echo json_encode(['error' => 'Username already taken']);
            return;
        }

        $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
        $stmt->execute([$email]);

        if ($stmt->fetch()) {
            http_response_code(400);
            echo json_encode(['error' => 'Email already registered']);
            return;
        }

        $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
        $theme = 'dark';
        
        try {
            $stmt = $pdo->prepare("INSERT INTO users (username, email, password, theme) VALUES (?, ?, ?, ?)");
            $stmt->execute([$username, $email, $hashedPassword, $theme]);
        } catch (Exception $e) {
            $stmt = $pdo->prepare("INSERT INTO users (email, password, theme) VALUES (?, ?, ?)");
            $stmt->execute([$email, $hashedPassword, $theme]);
        }

        $_SESSION['user_id'] = $pdo->lastInsertId();
        $_SESSION['email'] = $email;
        $_SESSION['username'] = $username;
        echo json_encode(['success' => true, 'email' => $email, 'username' => $username, 'theme' => $theme]);
    } catch (Exception $e) {
        error_log("Register error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['error' => 'Registration failed. Please try again.']);
    }
}

function login() {
    $email = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';

    try {
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

        try {
            $stmt = $pdo->prepare("INSERT INTO login_events (user_id) VALUES (?)");
            $stmt->execute([$user['id']]);
        } catch (Exception $e) {
            // Login events table might not exist, that's ok
        }

        echo json_encode(['success' => true, 'email' => $email, 'theme' => $user['theme'] ?? 'dark']);
    } catch (Exception $e) {
        error_log("Login error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['error' => 'Login failed. Please try again.']);
    }
}

function logout() {
    session_destroy();
    echo json_encode(['success' => true]);
}

function checkAuth() {
    error_log("=== checkAuth() CALLED ===");
    error_log("Session user_id: " . ($_SESSION['user_id'] ?? 'NOT SET'));
    error_log("Session email: " . ($_SESSION['email'] ?? 'NOT SET'));
    error_log("Session ID: " . session_id());
    
    if (isset($_SESSION['user_id']) && $_SESSION['user_id'] > 0) {
        try {
            $pdo = getDB();
            $stmt = $pdo->prepare("SELECT theme FROM users WHERE id = ?");
            $stmt->execute([$_SESSION['user_id']]);
            $user = $stmt->fetch();
            $response = ['authenticated' => true, 'email' => $_SESSION['email'], 'theme' => $user['theme'] ?? 'dark'];
            error_log("Auth SUCCESS: " . $_SESSION['email']);
            echo json_encode($response);
        } catch (Exception $e) {
            error_log("checkAuth DB error: " . $e->getMessage());
            echo json_encode(['authenticated' => false, 'error' => $e->getMessage()]);
        }
    } else {
        error_log("Auth FAILED - no valid user_id in session");
        error_log("Full session dump: " . print_r($_SESSION, true));
        echo json_encode(['authenticated' => false, 'reason' => 'no_session']);
    }
}

function updateTheme() {
    if (!isset($_SESSION['user_id'])) {
        http_response_code(401);
        echo json_encode(['error' => 'Not authenticated']);
        return;
    }
    
    $theme = $_POST['theme'] ?? 'dark';
    if (!in_array($theme, ['dark', 'light'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid theme']);
        return;
    }
    
    $pdo = getDB();
    $stmt = $pdo->prepare("UPDATE users SET theme = ? WHERE id = ?");
    $stmt->execute([$theme, $_SESSION['user_id']]);
    
    echo json_encode(['success' => true, 'theme' => $theme]);
}
