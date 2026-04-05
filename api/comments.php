<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: https://rebelwithlinux.com');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

function getDB() {
    static $pdo = null;
    if ($pdo === null) {
        try {
            $pdo = new PDO(
                'mysql:dbname=' . getenv('DB_NAME') . ';unix_socket=' . getenv('DB_SOCKET'),
                getenv('DB_USER'),
                getenv('DB_PASS')
            );
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch (PDOException $e) {
            http_response_code(500);
            die(json_encode(['error' => 'Database connection failed']));
        }
    }
    return $pdo;
}

function rateLimit($key, $maxRequests = 10, $windowSeconds = 60) {
    $ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
    $cacheFile = '/tmp/ratelimit_' . md5($key . $ip);
    $now = time();
    
    if (file_exists($cacheFile)) {
        $data = json_decode(file_get_contents($cacheFile), true);
        if ($data['expires'] > $now) {
            if ($data['count'] >= $maxRequests) {
                http_response_code(429);
                die(json_encode(['error' => 'Too many requests']));
            }
            $data['count']++;
        } else {
            $data = ['count' => 1, 'expires' => $now + $windowSeconds];
        }
    } else {
        $data = ['count' => 1, 'expires' => $now + $windowSeconds];
    }
    
    file_put_contents($cacheFile, json_encode($data));
}

function sanitize($str) {
    return htmlspecialchars($str, ENT_QUOTES | ENT_HTML5, 'UTF-8');
}

rateLimit('comments');

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $slug = $_GET['slug'] ?? '';
    if (!$slug) {
        echo json_encode([]);
        exit;
    }
    
    $pdo = getDB();
    $stmt = $pdo->prepare('SELECT id, author, content, created_at FROM comments WHERE post_slug = ? ORDER BY created_at DESC');
    $stmt->execute([$slug]);
    $comments = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($comments as &$c) {
        $c['author'] = sanitize($c['author']);
        $c['content'] = sanitize($c['content']);
        $c['created_at'] = date('M j, Y', strtotime($c['created_at']));
    }
    
    echo json_encode($comments);
    exit;
}

if ($method === 'POST') {
    rateLimit('comments_post');
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    $slug = trim($input['slug'] ?? '');
    $author = trim($input['author'] ?? '');
    $email = trim($input['email'] ?? '');
    $content = trim($input['content'] ?? '');
    
    if (!$slug || !$author || !$email || !$content) {
        http_response_code(400);
        echo json_encode(['error' => 'All fields are required']);
        exit;
    }
    
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid email address']);
        exit;
    }
    
    if (strlen($author) > 100 || strlen($content) > 5000) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid field length']);
        exit;
    }
    
    if (preg_match('/[<>]/', $author) || preg_match('/[<>]/', $content)) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid characters detected']);
        exit;
    }
    
    $pdo = getDB();
    $stmt = $pdo->prepare('INSERT INTO comments (post_slug, author, email, content) VALUES (?, ?, ?, ?)');
    
    try {
        $stmt->execute([$slug, $author, $email, $content]);
        echo json_encode(['success' => true, 'id' => $pdo->lastInsertId()]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to save comment']);
    }
    exit;
}

echo json_encode(['error' => 'Method not allowed']);
