<?php
ini_set('display_errors', 0);
error_reporting(0);
header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . '/../config/db.php';

$fullName   = trim($_POST['full_name'] ?? "");
$email      = trim($_POST['email'] ?? "");
$nationalId = trim($_POST['national_id'] ?? "");
$password   = $_POST['password'] ?? "";
$phone      = trim($_POST['phone'] ?? "");

if ($fullName === "" || $email === "" || $nationalId === "" || $password === "") {
    echo json_encode(["success" => false, "message" => "Missing fields"]);
    exit;
}

$hashed = password_hash($password, PASSWORD_DEFAULT);

// image upload
$imageName = null;
if (!empty($_FILES['image']['name'])) {
    $imageName = time() . "_" . $_FILES['image']['name'];
    move_uploaded_file(
        $_FILES['image']['tmp_name'],
        __DIR__ . "/../images/employeeimage/" . $imageName
    );
}

$stmt = $conn->prepare("
    INSERT INTO employees 
    (full_name, email, phone, passwordEmp, national_id, imageName)
    VALUES (?, ?, ?, ?, ?, ?)
");

$stmt->bind_param(
    "ssssss",
    $fullName,
    $email,
    $phone,
    $hashed,
    $nationalId,
    $imageName
);

if ($stmt->execute()) {
    echo json_encode(["success" => true]);
} else {
    echo json_encode(["success" => false, "message" => $stmt->error]);
}

$stmt->close();
