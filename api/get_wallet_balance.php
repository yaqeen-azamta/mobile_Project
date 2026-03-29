<?php
header("Content-Type: application/json; charset=UTF-8");
require_once __DIR__ . '/../config/db.php';

$customer_id = $_GET['customer_id'] ?? null;

if (!$customer_id) {
  echo json_encode(["success" => false, "message" => "Missing customer_id"]);
  exit;
}

$stmt = $conn->prepare(
  "SELECT balance FROM wallets WHERE customer_id = ?"
);
$stmt->bind_param("i", $customer_id);
$stmt->execute();
$res = $stmt->get_result();

if ($res->num_rows === 0) {
  echo json_encode(["success" => true, "balance" => 0]);
  exit;
}

$row = $res->fetch_assoc();
echo json_encode([
  "success" => true,
  "balance" => (float)$row['balance']
]);
