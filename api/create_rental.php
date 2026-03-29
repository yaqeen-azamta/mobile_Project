<?php
header("Content-Type: application/json; charset=UTF-8");
require_once __DIR__ . '/../config/db.php';


function fail($msg) {
  echo json_encode([
    "success" => false,
    "message" => $msg
  ]);
  exit;
}

$raw = file_get_contents("php://input");
$data = json_decode($raw, true);

if (!is_array($data)) {
  fail("Invalid JSON body");
}


$customer_id  = $data['customer_id'] ?? null;
$car_id       = $data['car_id'] ?? null;
$start_date   = $data['start_date'] ?? null;
$end_date     = $data['end_date'] ?? null;
$total_price  = $data['total_price'] ?? null;
$payment      = $data['payment_method'] ?? null;

$pickup_lat   = $data['pickup_lat'] ?? null;
$pickup_lng   = $data['pickup_lng'] ?? null;
$pickup_name  = $data['pickup_location_name'] ?? null;

$dropoff_lat  = $data['dropoff_lat'] ?? null;
$dropoff_lng  = $data['dropoff_lng'] ?? null;
$dropoff_name = $data['dropoff_location_name'] ?? null;


if (
  !$customer_id || !$car_id ||
  !$start_date || !$end_date ||
  !$total_price || !$payment ||
  $pickup_lat === null || $pickup_lng === null ||
  $dropoff_lat === null || $dropoff_lng === null
) {
  fail("Missing required fields");
}

if (!in_array($payment, ['CASH', 'WALLET'])) {
  fail("Invalid payment method");
}


$check = $conn->prepare("
  SELECT rental_id
  FROM rentals
  WHERE car_id = ?
    AND rental_status IN ('PENDING','ACTIVE')
    AND start_date <= ?
    AND end_date >= ?
");
$check->bind_param("iss", $car_id, $end_date, $start_date);
$check->execute();
$res = $check->get_result();

if ($res->num_rows > 0) {
  fail("Car is already booked in selected dates");
}


if ($payment === 'WALLET') {

  $w = $conn->prepare(
    "SELECT balance FROM wallets WHERE customer_id = ?"
  );
  $w->bind_param("i", $customer_id);
  $w->execute();
  $wr = $w->get_result();

  if ($wr->num_rows === 0) {
    fail("Wallet not found");
  }

  $wallet = $wr->fetch_assoc();

  if ((float)$wallet['balance'] < (float)$total_price) {
    fail("Insufficient wallet balance");
  }

}
$stmt = $conn->prepare("
  INSERT INTO rentals (
    customer_id,
    car_id,
    start_date,
    end_date,
    rental_status,
    total_price,
    payment_method,
    pickup_lat,
    pickup_lng,
    pickup_location_name,
    dropoff_lat,
    dropoff_lng,
    dropoff_location_name
  ) VALUES (
    ?, ?, ?, ?, 'PENDING', ?, ?,
    ?, ?, ?, ?, ?, ?
  )
");

/
$stmt->bind_param(
  "iissdsddsdds",
  $customer_id,
  $car_id,
  $start_date,
  $end_date,
  $total_price,
  $payment,
  $pickup_lat,
  $pickup_lng,
  $pickup_name,
  $dropoff_lat,
  $dropoff_lng,
  $dropoff_name
);

if (!$stmt->execute()) {
  fail("Failed to create rental");
}

echo json_encode([
  "success" => true,
  "rental_id" => $stmt->insert_id
]);
