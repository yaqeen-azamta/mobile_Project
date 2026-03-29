<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . '/../config/db.php';

$sql = "SELECT 
  c.car_id,
  c.plate_number,
  c.brand,
  c.model,
  c.year,
  c.type,
  c.daily_price,
  c.status,
  c.color,
  c.seats,
  MIN(ci.imageName) AS imageName
FROM cars c
LEFT JOIN car_images ci ON ci.car_id = c.car_id
GROUP BY 
  c.car_id,
  c.plate_number,
  c.brand,
  c.model,
  c.year,
  c.type,
  c.daily_price,
  c.status,
  c.color,
  c.seats";

$result = mysqli_query($conn, $sql);

if (!$result) {
  echo json_encode([
    "success" => false,
    "message" => "Query failed",
    "error" => mysqli_error($conn)
  ]);
  exit;
}

$data = [];
while ($row = mysqli_fetch_assoc($result)) {
  $data[] = $row;
}

echo json_encode([
  "success" => true,
  "cars" => $data
]);
