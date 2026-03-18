<?php
require_once 'db.php';

header('Content-Type: application/json');

$pdo = getDB();

try {
    // Count completed items from progress table as XP (each completed item = 100 XP)
    $stmt = $pdo->prepare("
        SELECT u.username, COALESCE(COUNT(p.id) * 100, 0) as xp 
        FROM users u 
        LEFT JOIN progress p ON u.id = p.user_id AND p.completed = 1
        WHERE u.username IS NOT NULL
        GROUP BY u.id, u.username 
        ORDER BY xp DESC 
        LIMIT 10
    ");
    $stmt->execute();
    
    $leaderboard = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'leaderboard' => $leaderboard
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Failed to fetch leaderboard'
    ]);
}
