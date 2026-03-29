<?php
header("Content-Type: application/json; charset=UTF-8");


ini_set('display_errors', 0);
error_reporting(0);

require_once __DIR__ . '/../config/db.php';

$raw = file_get_contents("php://input");
$data = json_decode($raw, true);


if (!is_array($data)) {
  echo json_encode([
    "success" => false,
    "message" => "Invalid JSON body",
    "raw" => $raw
  ]);
  exit;
}


$customer_id = $data["customer_id"] ?? null;
$full_name   = trim($data["full_name"] ?? "");
$email       = trim($data["email"] ?? "");
$phone       = trim($data["phone"] ?? "");


if (!$customer_id || $full_name === "" || $email === "" || $phone === "") {
  echo json_encode([
    "success" => false,
    "message" => "Missing required fields",
    "received" => [
      "customer_id" => $customer_id,
      "full_name" => $full_name,
      "email" => $email,
      "phone" => $phone
    ]
  ]);
  exit;
}

$sql = "
  UPDATE customers 
  SET full_name = ?, email = ?, phone = ?
  WHERE customer_id = ?
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("sssi", $full_name, $email, $phone, $customer_id);

if ($stmt->execute()) {
  echo json_encode([
    "success" => true,
    "affected_rows" => $stmt->affected_rows,
    "updated_data" => [
      "customer_id" => $customer_id,
      "full_name" => $full_name,
      "email" => $email,
      "phone" => $phone
    ]
  ]);
} else {
  echo json_encode([
    "success" => false,
    "message" => "Update failed"
  ]);
}

exit;
