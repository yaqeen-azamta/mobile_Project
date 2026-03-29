<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . '/../config/db.php';

$car_id = isset($_GET['car_id']) ? intval($_GET['car_id']) : 0;

if ($car_id <= 0) {
  echo json_encode([
    "success" => false,
    "message" => "car_id is required"
  ]);
  exit;
}

$stmt = mysqli_prepare(
  $conn,
  "SELECT imageName FROM car_images WHERE car_id = ? ORDER BY car_images_id ASC"
);

mysqli_stmt_bind_param($stmt, "i", $car_id);
mysqli_stmt_execute($stmt);

$result = mysqli_stmt_get_result($stmt);

if (!$result) {
  echo json_encode([
    "success" => false,
    "message" => "Query failed",
    "error" => mysqli_error($conn)
  ]);
  exit;
}

$imgs = [];
while ($row = mysqli_fetch_assoc($result)) {
  $imgs[] = $row["imageName"];
}

echo json_encode([
  "success" => true,
  "images" => $imgs
]);
