<?php
ob_start();

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// ================== HEADERS ==================
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  exit;
}

require_once __DIR__ . '/../config/db.php';

// ================== READ INPUT ==================
$raw = file_get_contents("php://input");
$input = json_decode($raw, true);

if (!is_array($input)) {
  echo json_encode([
    "success" => false,
    "message" => "Invalid JSON input"
  ]);
  exit;
}

$email    = trim($input["email"] ?? "");
$password = trim($input["password"] ?? "");

if ($email === "" || $password === "") {
  echo json_encode([
    "success" => false,
    "message" => "Email and password required"
  ]);
  exit;
}

// ================== LOGIN FUNCTION ==================
function try_login($conn, $table, $idField, $passField, $role, $email, $password) {

  $sql = "
    SELECT 
      $idField AS user_id,
      full_name,
      email,
      $passField AS user_password
    FROM $table
    WHERE email = ?
    LIMIT 1
  ";

  $stmt = mysqli_prepare($conn, $sql);
  if (!$stmt) return null;

  mysqli_stmt_bind_param($stmt, "s", $email);
  mysqli_stmt_execute($stmt);

  $res = mysqli_stmt_get_result($stmt);
  $row = mysqli_fetch_assoc($res);

  if (!$row) return null;

  $stored = $row["user_password"];

  $valid =
    password_verify($password, $stored) ||
    $password === $stored;

  if (!$valid) return null;

  return [
    "success" => true,
    "role" => $role,
    "user" => [
      "id" => (int)$row["user_id"],
      "full_name" => $row["full_name"],
      "email" => $row["email"]
    ]
  ];
}

// ================== TRY ROLES ==================
$roles = [
  ["manager",   "manager",   "manager_id",  "passwordManager"],
  ["employee",  "employees", "employee_id", "passwordEmp"],
  ["customer",  "customers", "customer_id", "passwordCustom"],
];

foreach ($roles as [$role, $table, $id, $pass]) {
  $found = try_login($conn, $table, $id, $pass, $role, $email, $password);
  if ($found) {
    ob_end_clean();
    echo json_encode($found);
    exit;
  }
}

// ================== FAILED ==================
ob_end_clean();
echo json_encode([
  "success" => false,
  "message" => "Invalid email or password"
]);
