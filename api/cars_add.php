<?php
ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);
header("Content-Type: application/json; charset=UTF-8");


require_once __DIR__ . '/../config/db.php';


$required = [
    'brand', 'model', 'year', 'plate_number',
    'type', 'daily_price', 'status', 'color', 'seats'
];

foreach ($required as $r) {
    if (!isset($_POST[$r]) || trim($_POST[$r]) === '') {
        echo json_encode([
            "success" => false,
            "message" => "Missing field: $r"
        ]);
        exit;
    }
}


$stmt = $conn->prepare("
    INSERT INTO cars
    (plate_number, brand, model, year, type, daily_price, status, color, seats)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
");

$stmt->bind_param(
    "sssissssi",
    $_POST['plate_number'],
    $_POST['brand'],
    $_POST['model'],
    $_POST['year'],
    $_POST['type'],
    $_POST['daily_price'],
    strtoupper($_POST['status']),
    $_POST['color'],
    $_POST['seats']
);

if (!$stmt->execute()) {
    echo json_encode([
        "success" => false,
        "message" => $stmt->error
    ]);
    exit;
}

$carId = $conn->insert_id;

$uploadDir = __DIR__ . '/../images/carimage/';
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

$allowedExt = ['jpg', 'jpeg', 'png', 'webp'];
$images = ['image1', 'image2'];
$imageNumber = 1;

$imgStmt = $conn->prepare(
    "INSERT INTO car_images (car_id, imageName) VALUES (?, ?)"
);

foreach ($images as $img) {

    if (!isset($_FILES[$img])) {
        echo json_encode([
            "success" => false,
            "message" => "$img not received"
        ]);
        exit;
    }

    if ($_FILES[$img]['error'] !== UPLOAD_ERR_OK) {
        echo json_encode([
            "success" => false,
            "message" => "$img upload error: " . $_FILES[$img]['error']
        ]);
        exit;
    }

    $ext = strtolower(pathinfo($_FILES[$img]['name'], PATHINFO_EXTENSION));
    if (!in_array($ext, $allowedExt)) {
        echo json_encode([
            "success" => false,
            "message" => "Invalid image type: $ext"
        ]);
        exit;
    }

    $fileName = "car{$carId}_{$imageNumber}.$ext";
    $targetPath = $uploadDir . $fileName;

    if (!move_uploaded_file($_FILES[$img]['tmp_name'], $targetPath)) {
        echo json_encode([
            "success" => false,
            "message" => "Failed to move uploaded file: $fileName"
        ]);
        exit;
    }

    $imgStmt->bind_param("is", $carId, $fileName);
    $imgStmt->execute();

    $imageNumber++;
}
