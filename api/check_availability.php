<?php
header("Content-Type: application/json");
require_once __DIR__ . '/../config/db.php';


$car_id     = $_POST['car_id'] ?? null;
$start_date = $_POST['start_date'] ?? null;
$end_date   = $_POST['end_date'] ?? null;

if (!$car_id || !$start_date || !$end_date) {
    echo json_encode(["success" => false, "message" => "Missing data"]);
    exit;
}

$sql = "
SELECT rental_id
FROM rentals
WHERE car_id = ?
AND rental_status IN ('PENDING', 'CONFIRMED')
AND (
    start_date <= ?
    AND end_date >= ?
)
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("iss", $car_id, $end_date, $start_date);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    echo json_encode([
        "success" => false,
        "available" => false,
        "message" => "Dates not available"
    ]);
} else {
    echo json_encode([
        "success" => true,
        "available" => true
    ]);
}
