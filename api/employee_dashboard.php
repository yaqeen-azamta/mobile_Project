<?php
require_once __DIR__ . '/../config/db.php';
header('Content-Type: application/json; charset=utf-8');

function fail($msg, $err = null) {
  echo json_encode([
    "success" => false,
    "message" => $msg,
    "error" => $err
  ]);
  exit;
}

$today = date('Y-m-d');

// =========================
// 1) Rentals per day (last 7 days)
// =========================
$sqlRentals7 = "
SELECT DATE(start_date) AS day, COUNT(*) AS count
FROM rentals
WHERE start_date >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
GROUP BY DATE(start_date)
ORDER BY day ASC
";
$res = mysqli_query($conn, $sqlRentals7);
if (!$res) fail("Query rentals7 failed", mysqli_error($conn));

$rentals7 = [];
while ($row = mysqli_fetch_assoc($res)) $rentals7[] = $row;

// =========================
// 2) Car availability now (available vs rented)
// rented_now: rentals where today between start & end and rental_status != 'cancelled'
// =========================
$sqlRentedNow = "
SELECT COUNT(DISTINCT car_id) AS rented_now
FROM rentals
WHERE CURDATE() BETWEEN DATE(start_date) AND DATE(end_date)
  AND (rental_status IS NULL OR rental_status NOT IN ('cancelled'))
";
$res = mysqli_query($conn, $sqlRentedNow);
if (!$res) fail("Query rented_now failed", mysqli_error($conn));
$rentedNow = (int) mysqli_fetch_assoc($res)['rented_now'];

$sqlTotalCars = "SELECT COUNT(*) AS total_cars FROM cars";
$res = mysqli_query($conn, $sqlTotalCars);
if (!$res) fail("Query total_cars failed", mysqli_error($conn));
$totalCars = (int) mysqli_fetch_assoc($res)['total_cars'];

$availableNow = max(0, $totalCars - $rentedNow);

// =========================
// 3) Revenue (last 6 months) using start_date month
// =========================
$sqlRevenue = "
SELECT DATE_FORMAT(start_date, '%Y-%m') AS ym, COALESCE(SUM(total_price),0) AS revenue
FROM rentals
WHERE start_date >= DATE_SUB(CURDATE(), INTERVAL 5 MONTH)
GROUP BY DATE_FORMAT(start_date, '%Y-%m')
ORDER BY ym ASC
";
$res = mysqli_query($conn, $sqlRevenue);
if (!$res) fail("Query revenue failed", mysqli_error($conn));

$revenue = [];
while ($row = mysqli_fetch_assoc($res)) $revenue[] = $row;

// =========================
// 4) Top 5 cars by rentals count
// =========================
$sqlTopCars = "
SELECT c.car_id, CONCAT(c.brand, ' ', c.model) AS car_name, COUNT(r.rental_id) AS count
FROM rentals r
JOIN cars c ON c.car_id = r.car_id
GROUP BY c.car_id, c.brand, c.model
ORDER BY count DESC
LIMIT 5
";
$res = mysqli_query($conn, $sqlTopCars);
if (!$res) fail("Query top cars failed", mysqli_error($conn));

$topCars = [];
while ($row = mysqli_fetch_assoc($res)) $topCars[] = $row;

// =========================
// 5) Top 5 customers by rentals count
// =========================
$sqlTopCustomers = "
SELECT cu.customer_id, cu.full_name, COUNT(r.rental_id) AS count
FROM rentals r
JOIN customers cu ON cu.customer_id = r.customer_id
GROUP BY cu.customer_id, cu.full_name
ORDER BY count DESC
LIMIT 5
";
$res = mysqli_query($conn, $sqlTopCustomers);
if (!$res) fail("Query top customers failed", mysqli_error($conn));

$topCustomers = [];
while ($row = mysqli_fetch_assoc($res)) $topCustomers[] = $row;

// =========================
// 6) Extra KPIs
// - active rentals now
// - total rentals
// - total customers
// =========================
$sqlActive = "
SELECT COUNT(*) AS active_now
FROM rentals
WHERE CURDATE() BETWEEN DATE(start_date) AND DATE(end_date)
  AND (rental_status IS NULL OR rental_status NOT IN ('cancelled'))
";
$res = mysqli_query($conn, $sqlActive);
if (!$res) fail("Query active failed", mysqli_error($conn));
$activeNow = (int) mysqli_fetch_assoc($res)['active_now'];

$sqlTotalRentals = "SELECT COUNT(*) AS total_rentals FROM rentals";
$res = mysqli_query($conn, $sqlTotalRentals);
if (!$res) fail("Query total rentals failed", mysqli_error($conn));
$totalRentals = (int) mysqli_fetch_assoc($res)['total_rentals'];

$sqlTotalCustomers = "SELECT COUNT(*) AS total_customers FROM customers";
$res = mysqli_query($conn, $sqlTotalCustomers);
if (!$res) fail("Query total customers failed", mysqli_error($conn));
$totalCustomers = (int) mysqli_fetch_assoc($res)['total_customers'];

echo json_encode([
  "success" => true,
  "data" => [
    "rentals_last_7_days" => $rentals7,
    "cars_status" => [
      "total_cars" => $totalCars,
      "rented_now" => $rentedNow,
      "available_now" => $availableNow
    ],
    "revenue_last_6_months" => $revenue,
    "top_cars" => $topCars,
    "top_customers" => $topCustomers,
    "kpis" => [
      "active_rentals_now" => $activeNow,
      "total_rentals" => $totalRentals,
      "total_customers" => $totalCustomers
    ]
  ]
]);
