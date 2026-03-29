<?php
ini_set('display_errors', 0);
error_reporting(0);
header("Content-Type: application/json; charset=UTF-8");


require_once __DIR__ . '/../config/db.php';

$bookingId = isset($_POST['booking_id']) ? intval($_POST['booking_id']) : 0;
$carId     = isset($_POST['car_id']) ? intval($_POST['car_id']) : 0;

if ($bookingId <= 0 || $carId <= 0) {
    echo json_encode([
        "success" => false,
        "message" => "Invalid booking_id or car_id"
    ]);
    exit;
}


$stmt = $conn->prepare(
    "UPDATE rentals SET car_id = ? WHERE rental_id = ?"
);

$stmt->bind_param("ii", $carId, $bookingId);

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
