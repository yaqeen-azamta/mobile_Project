<?php
header("Content-Type: application/json; charset=UTF-8");
require_once __DIR__ . '/../config/db.php';

require_once __DIR__ . '/notification_helper.php';
require_once __DIR__ . '/loyalty_helper.php';


function fail($msg) {
  echo json_encode(["success" => false, "message" => $msg]);
  exit;
}


$raw = file_get_contents("php://input");
$data = json_decode($raw, true);

if (!is_array($data)) {
  fail("Invalid JSON body");
}

$customer_id = $data["customer_id"] ?? null;
$amount      = $data["amount"] ?? null;

if (!$customer_id || !is_numeric($amount) || $amount <= 0) {
  fail("Invalid data");
}


$stmt = $conn->prepare(
  "SELECT wallet_id, balance FROM wallets WHERE customer_id = ?"
);
$stmt->bind_param("i", $customer_id);
$stmt->execute();
$res = $stmt->get_result();

if ($res->num_rows > 0) {

  $row = $res->fetch_assoc();
  $newBalance = (float)$row["balance"] + (float)$amount;

  $upd = $conn->prepare(
    "UPDATE wallets SET balance = ?, updated_at = NOW() WHERE customer_id = ?"
  );
  $upd->bind_param("di", $newBalance, $customer_id);
  $upd->execute();
} else {

  $newBalance = (float)$amount;

  $ins = $conn->prepare(
    "INSERT INTO wallets (customer_id, balance, updated_at)
     VALUES (?, ?, NOW())"
  );
  $ins->bind_param("id", $customer_id, $newBalance);
  $ins->execute();
}


createNotification(
  $customer_id,
  "payment",
  "Wallet Recharged",
  $amount . " ₪ has been added to your wallet."
);



$earned = addLoyaltyPointsByAmount($customer_id, $amount);

if ($earned > 0) {
  createNotification(
    $customer_id,
    "system",
    "Loyalty Points Earned",
    "You earned $earned loyalty points from your wallet recharge 🎉"
  );
}

echo json_encode([
  "success" => true,
  "balance" => $newBalance,
  "earned_points" => $earned
]);
