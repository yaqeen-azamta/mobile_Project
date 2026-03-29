<?php
header("Content-Type: application/json; charset=UTF-8");
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../api/loyalty_helper.php';

$customer_id = intval($_GET["customer_id"] ?? 0);
if ($customer_id <= 0) {
  echo json_encode(["success" => false, "message" => "Missing customer_id"]);
  exit;
}

ensureLoyaltyRow($customer_id);

$stmt = $conn->prepare("SELECT points, level, updated_at FROM loyalty WHERE customer_id = ?");
$stmt->bind_param("i", $customer_id);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();

$points = (int)($row["points"] ?? 0);
$level  = $row["level"] ?? "BRONZE";

// للـ Progress
$nextLevel = $level === "BRONZE" ? "SILVER" : ($level === "SILVER" ? "GOLD" : "GOLD");
$nextTarget = $level === "BRONZE" ? 500 : ($level === "SILVER" ? 1500 : 1500);
$prevTarget = $level === "BRONZE" ? 0 : ($level === "SILVER" ? 500 : 1500);

$progress = ($nextTarget == $prevTarget) ? 1.0 : (($points - $prevTarget) / ($nextTarget - $prevTarget));
if ($progress < 0) $progress = 0;
if ($progress > 1) $progress = 1;

echo json_encode([
  "success" => true,
  "loyalty" => [
    "points" => $points,
    "level" => $level,
    "next_level" => $nextLevel,
    "next_target" => $nextTarget,
    "progress" => $progress
  ]
]);
