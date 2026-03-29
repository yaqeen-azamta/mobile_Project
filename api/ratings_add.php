<?php
header("Content-Type: application/json");
require_once __DIR__ . '/../config/db.php';

$data = json_decode(file_get_contents("php://input"), true);

$rental_id   = $data['rental_id'] ?? null;
$car_id      = $data['car_id'] ?? null;
$customer_id = $data['customer_id'] ?? null;
$rating      = $data['rating'] ?? null;
$comment     = $data['comment'] ?? null;

if (!$rental_id || !$car_id || !$customer_id || !$rating) {
    echo json_encode(["success" => false, "message" => "Missing data"]);
    exit;
}

$stmt = $conn->prepare("
    INSERT INTO ratings (rental_id, car_id, customer_id, rating, comment)
    VALUES (?, ?, ?, ?, ?)
");

$stmt->bind_param("iiiis",
    $rental_id,
    $car_id,
    $customer_id,
    $rating,
    $comment
);

if ($stmt->execute()) {
    echo json_encode(["success" => true]);
} else {
    echo json_encode([
        "success" => false,
        "message" => $stmt->error
    ]);
}
