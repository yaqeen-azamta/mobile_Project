<?php
header("Content-Type: application/json; charset=UTF-8");
require_once __DIR__ . '/../config/db.php';

$customer_id = intval($_GET['customer_id'] ?? 0);
if ($customer_id <= 0) {
  echo json_encode(["success"=>false, "message"=>"Missing customer_id"]);
  exit;
}

$stmt = $conn->prepare("
  SELECT c.car_id, c.brand, c.model, c.year, c.daily_price
  FROM favorites f
  JOIN cars c ON c.car_id = f.car_id
  WHERE f.customer_id = ?
  ORDER BY f.created_at DESC
");
$stmt->bind_param("i", $customer_id);
$stmt->execute();
$res = $stmt->get_result();

$data = [];
while ($row = $res->fetch_assoc()) $data[] = $row;

echo json_encode(["success"=>true, "favorites"=>$data]);
