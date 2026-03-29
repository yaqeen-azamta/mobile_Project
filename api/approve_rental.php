<?php

ini_set('display_errors', 0);
error_reporting(0);



header("Content-Type: application/json; charset=UTF-8");
require_once __DIR__ . '/../config/db.php';

require_once __DIR__ . '/notification_helper.php';
require_once __DIR__ . '/loyalty_helper.php';

function error($msg) {
  echo json_encode(["success" => false, "message" => $msg]);
  exit;
}

$rental_id = $_POST['rental_id'] ?? null;
$action = $_POST['action'] ?? null; 

if (!$rental_id || !$action) {
  error("Missing rental_id or action");
}


$stmt = $conn->prepare(
  "SELECT customer_id, total_price, payment_method, rental_status
   FROM rentals WHERE rental_id = ?"
);
$stmt->bind_param("i", $rental_id);
$stmt->execute();
$res = $stmt->get_result();

if ($res->num_rows === 0) {
  error("Rental not found");
}

$rental = $res->fetch_assoc();

if ($rental['rental_status'] !== 'PENDING') {
  error("Rental already processed");
}


if ($action === 'reject') {

  $stmt = $conn->prepare(
    "UPDATE rentals SET rental_status = 'CANCELLED' WHERE rental_id = ?"
  );
  $stmt->bind_param("i", $rental_id);
  $stmt->execute();

  createNotification(
    $rental['customer_id'],
    "booking",
    "Rental Rejected",
    "Unfortunately, your rental request has been rejected by the employee.",
    "REJECTED",
    $rental_id
  );

  echo json_encode([
    "success" => true,
    "message" => "Rental rejected successfully"
  ]);
  exit;
}


if ($action !== 'approve') {
  error("Invalid action");
}


if ($rental['payment_method'] === 'WALLET') {

  $stmt = $conn->prepare(
    "SELECT balance FROM wallets WHERE customer_id = ?"
  );
  $stmt->bind_param("i", $rental['customer_id']);
  $stmt->execute();
  $walletRes = $stmt->get_result();

  if ($walletRes->num_rows === 0) {
    error("Wallet not found");
  }

  $wallet = $walletRes->fetch_assoc();
  $balance = (float)$wallet['balance'];

  if ($balance < $rental['total_price']) {
    createNotification(
      $rental['customer_id'],
      "payment",
      "Payment Failed",
      "Your wallet balance is insufficient to complete the rental payment."
    );
    error("Insufficient wallet balance");
  }

  $stmt = $conn->prepare(
    "UPDATE wallets SET balance = balance - ? WHERE customer_id = ?"
  );
  $stmt->bind_param(
    "di",
    $rental['total_price'],
    $rental['customer_id']
  );
  $stmt->execute();

  createNotification(
    $rental['customer_id'],
    "payment",
    "Payment Deducted",
    $rental['total_price'] . " ₪ has been deducted from your wallet."
  );
}

// تحديث الحالة
$stmt = $conn->prepare(
  "UPDATE rentals SET rental_status = 'ACTIVE' WHERE rental_id = ?"
);
$stmt->bind_param("i", $rental_id);
$stmt->execute();

createNotification(
  $rental['customer_id'],
  "booking",
  "Rental Confirmed",
  "Your rental request has been approved successfully.",
  "CONFIRMED",
  $rental_id
);

$earned = addLoyaltyPointsByAmount(
  $rental['customer_id'],
  $rental['total_price']
);

if ($earned > 0) {
  createNotification(
    $rental['customer_id'],
    "system",
    "Loyalty Points Earned",
    "You earned $earned loyalty points from this rental 🎉"
  );
}

echo json_encode([
  "success" => true,
  "message" => "Rental approved successfully",
  "earned_points" => $earned
]);
