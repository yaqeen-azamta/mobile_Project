<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);
header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . '/../config/db.php';

$carId  = isset($_POST['car_id']) ? intval($_POST['car_id']) : 0;
$status = isset($_POST['status']) ? strtoupper(trim($_POST['status'])) : '';

$allowed = ['AVAILABLE', 'RENTED', 'MAINTENANCE', 'DISABLED'];

if ($carId <= 0 || !in_array($status, $allowed)) {
    echo json_encode([
        "success" => false,
        "message" => "Invalid car_id or status"
    ]);
    exit;
}

$stmt = $conn->prepare(
    "UPDATE cars SET status = ? WHERE car_id = ?"
);

$stmt->bind_param("si", $status, $carId);

if ($stmt->execute()) {
    echo json_encode(["success" => true]);
} else {
    echo json_encode([
        "success" => false,
        "message" => $stmt->error
    ]);
}

$stmt->close();
exit;
