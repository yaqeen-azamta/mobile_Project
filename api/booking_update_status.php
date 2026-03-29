<?php
ini_set('display_errors', 0);
error_reporting(0);
header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . '/../config/db.php';

$bookingId = isset($_POST['booking_id']) ? intval($_POST['booking_id']) : 0;
$status    = isset($_POST['status']) ? strtoupper(trim($_POST['status'])) : '';

$allowed = ['PENDING', 'ACTIVE', 'COMPLETED', 'CANCELLED'];

if ($bookingId <= 0 || !in_array($status, $allowed)) {
    echo json_encode([
        "success" => false,
        "message" => "Invalid booking_id or status"
    ]);
    exit;
}

$stmt = $conn->prepare(
    "UPDATE rentals SET rental_status = ? WHERE rental_id = ?"
);

$stmt->bind_param("si", $status, $bookingId);

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
