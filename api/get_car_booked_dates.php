<?php
header("Content-Type: application/json");
require_once __DIR__ . '/../config/db.php';

$car_id = $_GET['car_id'] ?? null;

if (!$car_id) {
  echo json_encode(["success" => false, "message" => "Missing car_id"]);
  exit;
}

$sql = "
SELECT start_date, end_date
FROM rentals
WHERE car_id = ?
AND rental_status IN ('PENDING', 'CONFIRMED')
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $car_id);
$stmt->execute();
$res = $stmt->get_result();

$dates = [];
while ($row = $res->fetch_assoc()) {
  $dates[] = $row;
}

echo json_encode([
  "success" => true,
  "booked_dates" => $dates
]);
