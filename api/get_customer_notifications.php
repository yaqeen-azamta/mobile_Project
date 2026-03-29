<?php
header("Content-Type: application/json; charset=UTF-8");
require_once __DIR__ . '/../config/db.php';

$customer_id = intval($_GET['customer_id'] ?? 0);

if ($customer_id <= 0) {
  echo json_encode(["success" => false]);
  exit;
}

$stmt = $conn->prepare("
  SELECT * FROM notifications
  WHERE customer_id = ?
  ORDER BY created_at DESC
");
$stmt->bind_param("i", $customer_id);
$stmt->execute();
$res = $stmt->get_result();

$notifications = [];
while ($row = $res->fetch_assoc()) {
  $notifications[] = $row;
}

echo json_encode([
  "success" => true,
  "notifications" => $notifications
]);
