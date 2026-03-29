<?php
ini_set('display_errors', 0);
error_reporting(0);
header("Content-Type: application/json; charset=UTF-8");


require_once __DIR__ . '/../config/db.php';

$result = mysqli_query($conn, "SELECT * FROM cars");

if (!$result) {
    echo json_encode([
        "success" => false,
        "message" => mysqli_error($conn)
    ]);
    exit;
}

$cars = [];
while ($row = mysqli_fetch_assoc($result)) {
    $cars[] = $row;
}

echo json_encode([
    "success" => true,
    "data" => $cars
]);
exit;
