<?php
ini_set('display_errors', 0);
error_reporting(0);
header("Content-Type: application/json; charset=UTF-8");


require_once __DIR__ . '/../config/db.php';

$data = $_POST;


$required = ['car_id', 'brand', 'model', 'year', 'daily_price', 'status'];

foreach ($required as $r) {
    if (!isset($data[$r]) || trim($data[$r]) === '') {
        echo json_encode([
            "success" => false,
            "message" => "Missing field: $r"
        ]);
        exit;
    }
}

$imageSql = "";
$types = "sssds"; 
$params = [
    $data['brand'],
    $data['model'],
    $data['year'],
    $data['daily_price'],
    strtoupper($data['status'])
];


if (!empty($_FILES['image']['name'])) {
    $imageName = time() . "_" . $_FILES['image']['name'];
    move_uploaded_file(
        $_FILES['image']['tmp_name'],
        __DIR__ . "/uploads/cars/" . $imageName
    );

    $imageSql = ", imageName = ?";
    $types .= "s";
    $params[] = $imageName;
}


$types .= "i";
$params[] = $data['car_id'];

$sql = "
    UPDATE cars
    SET brand = ?, model = ?, year = ?, daily_price = ?, status = ?
    $imageSql
    WHERE car_id = ?
";

$stmt = $conn->prepare($sql);
$stmt->bind_param($types, ...$params);

if ($stmt->execute()) {
    echo json_encode(["success" => true]);
} else {
    echo json_encode([
        "success" => false,
        "message" => $stmt->error
    ]);
}

$stmt->close();
exit;
