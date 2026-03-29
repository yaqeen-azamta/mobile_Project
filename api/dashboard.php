<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);
header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . '/../config/db.php';


$qCars = mysqli_query($conn, "SELECT COUNT(*) AS c FROM cars");

$qRentals = mysqli_query($conn, "SELECT COUNT(*) AS c FROM rentals");


$qActive = mysqli_query(
    $conn,
    "SELECT COUNT(*) AS c FROM rentals WHERE rental_status='ACTIVE'"
);


$qEmployees = mysqli_query($conn, "SELECT COUNT(*) AS c FROM employees");

echo json_encode([
    "success" => true,
    "totalCars" => (int) mysqli_fetch_assoc($qCars)['c'],
    "totalBookings" => (int) mysqli_fetch_assoc($qRentals)['c'],
    "activeBookings" => (int) mysqli_fetch_assoc($qActive)['c'],
    "totalEmployees" => (int) mysqli_fetch_assoc($qEmployees)['c']
]);
exit;
