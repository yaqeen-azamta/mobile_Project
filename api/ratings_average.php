<?php
header("Content-Type: application/json; charset=UTF-8");
require_once __DIR__ . '/../config/db.php';

$car_id = $_GET['car_id'] ?? null;

if (!$car_id) {
    echo json_encode([
        "success" => false,
        "message" => "car_id required"
    ]);
    exit;
}

$stmt = $conn->prepare("
    SELECT 
        COUNT(*) AS total_reviews,
        ROUND(AVG(rating), 1) AS avg_rating
    FROM ratings
    WHERE car_id = ?
");

$stmt->bind_param("i", $car_id);
$stmt->execute();

$res = $stmt->get_result()->fetch_assoc();

echo json_encode([
    "success" => true,
    "car_id" => (int)$car_id,
    "average_rating" => $res['avg_rating'] ?? 0,
    "total_reviews" => (int)$res['total_reviews']
]);
