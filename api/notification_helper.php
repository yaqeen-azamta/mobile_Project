<?php
require_once __DIR__ . '/../config/db.php';

function createNotification(
  $customer_id,
  $type,
  $title,
  $message,
  $status = null,
  $related_id = null
) {
  global $conn;

  $stmt = $conn->prepare("
    INSERT INTO notifications
      (customer_id, type, title, message, status, related_id)
    VALUES (?, ?, ?, ?, ?, ?)
  ");

  $stmt->bind_param(
    "issssi",
    $customer_id,
    $type,
    $title,
    $message,
    $status,
    $related_id
  );

  $stmt->execute();
}
