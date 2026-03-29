<?php
require_once __DIR__ . '/../config/db.php';

$car_id = $_GET['car_id'] ?? 0;

$stmt = $pdo->prepare("
    SELECT 
        ROUND(AVG(rating), 1) AS avg_rating,
        COUNT(*) AS reviews_count
    FROM ratings
    WHERE car_id = ?
");
$stmt->execute([$car_id]);
$row = $stmt->fetch(PDO::FETCH_ASSOC);

echo json_encode([
    "success" => true,
    "avg_rating" => $row["avg_rating"] ?? 0,
    "reviews_count" => $row["reviews_count"] ?? 0,
]);
