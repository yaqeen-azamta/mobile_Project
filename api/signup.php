<?php
ob_start();
ini_set('display_errors', 1);
error_reporting(E_ALL);

// CORS
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  exit;
}

require_once __DIR__ . '/../config/db.php';

function bad($msg, $code = 400) {
  http_response_code($code);
  ob_clean();
  echo json_encode([
    "success" => false,
    "message" => $msg
  ]);
  exit;
}

// ================= INPUT =================
$full_name   = trim($_POST['full_name'] ?? "");
$national_id = trim($_POST['national_id'] ?? "");
$email       = trim($_POST['email'] ?? "");
$phone       = trim($_POST['phone'] ?? "");
$password    = trim($_POST['passwordCustom'] ?? "");

if ($full_name === "" || $national_id === "" || $email === "" || $phone === "" || $password === "") {
  bad("Missing required fields");
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
  bad("Invalid email");
}

// ================= CHECK EMAIL =================
$stmt = mysqli_prepare($conn, "SELECT customer_id FROM customers WHERE email = ?");
mysqli_stmt_bind_param($stmt, "s", $email);
mysqli_stmt_execute($stmt);
$res = mysqli_stmt_get_result($stmt);
if ($res && mysqli_num_rows($res) > 0) {
  bad("Email already exists", 409);
}
mysqli_stmt_close($stmt);

// ================= CHECK NATIONAL ID =================
$stmt = mysqli_prepare($conn, "SELECT customer_id FROM customers WHERE national_id = ?");
mysqli_stmt_bind_param($stmt, "s", $national_id);
mysqli_stmt_execute($stmt);
$res = mysqli_stmt_get_result($stmt);
if ($res && mysqli_num_rows($res) > 0) {
  bad("National ID already exists", 409);
}
mysqli_stmt_close($stmt);

// ================= INSERT USER =================
$imageName = null;

$stmt = mysqli_prepare(
  $conn,
  "INSERT INTO customers
   (full_name, national_id, email, phone, passwordCustom, imageName)
   VALUES (?, ?, ?, ?, ?, ?)"
);

mysqli_stmt_bind_param(
  $stmt,
  "ssssss",
  $full_name,
  $national_id,
  $email,
  $phone,
  $password,   // (Plain text مؤقتًا – لاحقًا نعمل hash)
  $imageName
);

try {
  if (!mysqli_stmt_execute($stmt)) {
    bad("Insert failed", 500);
  }
} catch (mysqli_sql_exception $e) {
  bad("DB ERROR: " . $e->getMessage(), 409);
}

$customer_id = mysqli_insert_id($conn);
mysqli_stmt_close($stmt);

// ================= IMAGE UPLOAD =================
if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {

  $uploadDir = __DIR__ . "/../images/customerimage/";

  if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0777, true);
  }

  if (!is_writable($uploadDir)) {
    bad("Upload directory not writable");
  }

  $tmpName  = $_FILES['image']['tmp_name'];
  $origName = $_FILES['image']['name'];

  $ext = strtolower(pathinfo($origName, PATHINFO_EXTENSION));
  $allowed = ["jpg", "jpeg", "png", "webp"];

  if (!in_array($ext, $allowed)) {
    bad("Only jpg/jpeg/png/webp allowed");
  }

  $imageName = $customer_id . "." . $ext;
  $destPath = $uploadDir . $imageName;

  if (!move_uploaded_file($tmpName, $destPath)) {
    bad("Failed to move uploaded file");
  }

  $stmt = mysqli_prepare(
    $conn,
    "UPDATE customers SET imageName = ? WHERE customer_id = ?"
  );
  mysqli_stmt_bind_param($stmt, "si", $imageName, $customer_id);
  mysqli_stmt_execute($stmt);
  mysqli_stmt_close($stmt);
}

// ================= RESPONSE =================
$baseImageUrl = "http://10.0.2.2/car_rental_backend/images/customerimage/";

ob_clean();
echo json_encode([
  "success" => true,
  "message" => "Account created successfully",
  "customer_id" => $customer_id,
  "image_url" => $imageName ? $baseImageUrl . $imageName : null
]);
