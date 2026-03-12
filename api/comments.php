<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

function getDB() {
    static $pdo = null;
    if ($pdo === null) {
        try {
            $pdo = new PDO('mysql:dbname=learning_platform;unix_socket=/run/mysqld/mysqld.sock', 'webuser', 'webpass');
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch (PDOException $e) {
            http_response_code(500);
            die(json_encode(['error' => 'Database connection failed']));
        }
    }
    return $pdo;
}

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
        $c['created_at'] = date('M j, Y', strtotime($c['created_at']));
    }
    
    echo json_encode($comments);
    exit;
}

if ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $slug = $input['slug'] ?? '';
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
    
    if (strlen($content) > 5000) {
        http_response_code(400);
        echo json_encode(['error' => 'Comment too long (max 5000 characters)']);
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
