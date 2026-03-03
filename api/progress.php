<?php
header('Content-Type: application/json');
require_once 'db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    getProgress();
} elseif ($method === 'POST') {
    saveProgress();
} else {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
}

function getProgress() {
    $userId = getCurrentUserId();

    if (!$userId) {
        http_response_code(401);
        echo json_encode(['error' => 'Not authenticated']);
        return;
    }

    $course = $_GET['course'] ?? '';
    $pdo = getDB();

    if ($course) {
        $stmt = $pdo->prepare("SELECT * FROM progress WHERE user_id = ? AND course = ?");
        $stmt->execute([$userId, $course]);
    } else {
        $stmt = $pdo->prepare("SELECT * FROM progress WHERE user_id = ?");
        $stmt->execute([$userId]);
    }

    $progress = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($progress);
}

function saveProgress() {
    $userId = getCurrentUserId();

    if (!$userId) {
        http_response_code(401);
        echo json_encode(['error' => 'Not authenticated']);
        return;
    }

    $data = json_decode(file_get_contents('php://input'), true);
    $course = $data['course'] ?? '';
    $lessonId = $data['lesson_id'] ?? 0;
    $completed = $data['completed'] ?? false;
    $quizScore = $data['quiz_score'] ?? 0;

    if (!$course || !$lessonId) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing required fields']);
        return;
    }

    $pdo = getDB();
    $stmt = $pdo->prepare("INSERT INTO progress (user_id, course, lesson_id, completed, quiz_score, completed_at) VALUES (?, ?, ?, ?, ?, NOW()) ON DUPLICATE KEY UPDATE completed = VALUES(completed), quiz_score = VALUES(quiz_score), completed_at = IF(VALUES(completed), NOW(), completed_at)");
    $stmt->execute([$userId, $course, $lessonId, $completed ? 1 : 0, $quizScore]);
    echo json_encode(['success' => true]);
}
