<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . '/../config/db.php';

// ================= INPUT =================
$employee_id = $_GET['employee_id'] ?? null;

if (!$employee_id) {
    echo json_encode([
        "success" => false,
        "message" => "Missing employee_id"
    ]);
    exit;
}

// ================= QUERY =================
$sql = "
    SELECT
        employee_id,
        full_name,
        email,
        phone,
        national_id,
        imageName
    FROM employees
    WHERE employee_id = ?
    LIMIT 1
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $employee_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode([
        "success" => false,
        "message" => "Employee not found"
    ]);
    exit;
}

$employee = $result->fetch_assoc();

// ================= IMAGE URL =================
$baseImageUrl = "http://10.0.2.2/car_rental_backend/images/employeeimage/";

$employee["image_url"] =
    !empty($employee["imageName"])
        ? $baseImageUrl . $employee["imageName"]
        : null;

// ================= RESPONSE =================
echo json_encode([
    "success" => true,
    "employee" => $employee
]);
