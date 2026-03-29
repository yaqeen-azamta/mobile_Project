<?php
ini_set('display_errors', 0);
error_reporting(0);
header("Content-Type: application/json; charset=UTF-8");


require_once __DIR__ . '/../config/db.php';

$q = trim($_GET['q'] ?? "");

if ($q !== "") {
    $stmt = $conn->prepare("
        SELECT 
            employee_id,
            full_name,
            email,
            national_id,
            phone,
            imageName
        FROM employees
        WHERE full_name LIKE ?
           OR email LIKE ?
           OR national_id LIKE ?
    ");

    $like = "%$q%";
    $stmt->bind_param("sss", $like, $like, $like);
    $stmt->execute();
    $result = $stmt->get_result();

} else {
    $result = $conn->query("
        SELECT 
            employee_id,
            full_name,
            email,
            national_id,
            phone,
            imageName
        FROM employees
    ");
}

$employees = [];
while ($row = $result->fetch_assoc()) {
    $employees[] = $row;
}

echo json_encode($employees);
