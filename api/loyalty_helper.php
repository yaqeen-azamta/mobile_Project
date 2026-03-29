<?php
require_once __DIR__ . '/../config/db.php';

/**
 * Rules (تقدري تغيريهم بسهولة):
 * - نقاط = كل 10 شيكل مصروف = 1 point
 * - Levels:
 *   BRONZE: 0 - 499
 *   SILVER: 500 - 1499
 *   GOLD:   1500+
 */
function loyaltyLevelFromPoints($points) {
  if ($points >= 1500) return "GOLD";
  if ($points >= 500) return "SILVER";
  return "BRONZE";
}

function ensureLoyaltyRow($customer_id) {
  global $conn;

  $check = $conn->prepare("SELECT customer_id FROM loyalty WHERE customer_id = ?");
  $check->bind_param("i", $customer_id);
  $check->execute();
  $res = $check->get_result();

  if ($res->num_rows === 0) {
    $ins = $conn->prepare("INSERT INTO loyalty (customer_id, points, level) VALUES (?, 0, 'BRONZE')");
    $ins->bind_param("i", $customer_id);
    $ins->execute();
  }
}

function addLoyaltyPointsByAmount($customer_id, $amount) {
  global $conn;

  ensureLoyaltyRow($customer_id);

  $amount = (float)$amount;
  $earned = (int) floor($amount / 10.0); // كل 10 شيكل = 1 نقطة
  if ($earned <= 0) return 0;

  // اجيب نقاط الحالية
  $stmt = $conn->prepare("SELECT points FROM loyalty WHERE customer_id = ?");
  $stmt->bind_param("i", $customer_id);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  $current = (int)($row["points"] ?? 0);

  $newPoints = $current + $earned;
  $newLevel = loyaltyLevelFromPoints($newPoints);

  $upd = $conn->prepare("UPDATE loyalty SET points = ?, level = ?, updated_at = NOW() WHERE customer_id = ?");
  $upd->bind_param("isi", $newPoints, $newLevel, $customer_id);
  $upd->execute();

  return $earned;
}
