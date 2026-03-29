<?php
ini_set('display_errors', 0);
error_reporting(0);
header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . '/../config/db.php';

$status = isset($_GET['status']) ? strtoupper(trim($_GET['status'])) : '';

if ($status !== '') {
    $stmt = $conn->prepare(
        "SELECT * FROM rentals WHERE rental_status = ? ORDER BY rental_id DESC"
    );
    $stmt->bind_param("s", $status);
    $stmt->execute();
    $result = $stmt->get_result();
} else {
    $result = mysqli_query(
        $conn,
        "SELECT * FROM rentals ORDER BY rental_id DESC"
    );
}

$data = [];
while ($row = mysqli_fetch_assoc($result)) {
    $data[] = $row;
}

echo json_encode($data);
exit;
