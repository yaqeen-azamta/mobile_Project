<?php
header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . '/../config/db.php';

$customer_id = $_GET['customer_id'] ?? null;

if (!$customer_id) {
  echo json_encode([
    "success" => false,
    "message" => "Missing customer_id"
  ]);
  exit;
}

$sql = "
  SELECT 
    c.customer_id,
    c.full_name,
    c.email,
    c.phone,
    c.imageName,
    IFNULL(w.balance, 0) AS balance
  FROM customers c
  LEFT JOIN wallets w ON c.customer_id = w.customer_id
  WHERE c.customer_id = ?
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $customer_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
  echo json_encode([
    "success" => false,
    "message" => "Customer not found"
  ]);
  exit;
}

$data = $result->fetch_assoc();

/* ===============================
   ADD IMAGE URL
   =============================== */
$imageBaseUrl = "http://10.0.2.2/car_rental_backend/images/customerimage/";

if (!empty($data["imageName"])) {
  $data["image_url"] = $imageBaseUrl . $data["imageName"];
} else {
  $data["image_url"] = null;
}

echo json_encode([
  "success" => true,
  "customer" => $data
]);
