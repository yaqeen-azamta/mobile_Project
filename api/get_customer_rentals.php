<?php
header("Content-Type: application/json; charset=UTF-8");
require_once __DIR__ . '/../config/db.php';


$customer_id = $_GET['customer_id'] ?? null;

if (!$customer_id) {
  echo json_encode(["success" => false, "message" => "Missing customer_id"]);
  exit;
}

$sql = "
  SELECT 
    r.rental_id,
    r.start_date,
    r.end_date,
    r.total_price,
    r.rental_status,
    r.payment_method,
    c.brand,
    c.model,
    c.year
  FROM rentals r
  JOIN cars c ON r.car_id = c.car_id
  WHERE r.customer_id = ?
  ORDER BY r.rental_id DESC
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $customer_id);
$stmt->execute();
$result = $stmt->get_result();

$rentals = [];
while ($row = $result->fetch_assoc()) {
  $rentals[] = $row;
}

echo json_encode([
  "success" => true,
  "rentals" => $rentals
]);
