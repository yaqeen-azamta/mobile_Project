<?php
ini_set('display_errors', 0);
error_reporting(0);
header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . '/../config/db.php';

$period = $_GET['period'] ?? 'month';

/*
  rentals table:
  - total_price
  - payment_method (CASH | WALLET)
  - rental_status (PENDING | ACTIVE | COMPLETED | CANCELLED)
  - start_date
  - car_id
*/

/* ---------- Period filter ---------- */
switch ($period) {
    case 'day':
        $where = "DATE(start_date) = CURDATE()";
        $group = "HOUR(start_date)";
        break;

    case 'week':
        $where = "YEARWEEK(start_date) = YEARWEEK(CURDATE())";
        $group = "DATE(start_date)";
        break;

    case 'year':
        $where = "YEAR(start_date) = YEAR(CURDATE())";
        $group = "MONTH(start_date)";
        break;

    case 'month':
    default:
        $where = "MONTH(start_date) = MONTH(CURDATE())
                  AND YEAR(start_date) = YEAR(CURDATE())";
        $group = "DATE(start_date)";
        break;
}

/* ---------- Revenue by payment ---------- */
$sql = "
    SELECT payment_method, SUM(total_price) AS total
    FROM rentals
    WHERE $where
    GROUP BY payment_method
";

$res = mysqli_query($conn, $sql);
$byPayment = ["cash" => 0, "wallet" => 0];

if ($res) {
    while ($r = mysqli_fetch_assoc($res)) {
        if (strtoupper($r['payment_method']) === 'CASH') {
            $byPayment['cash'] = (float)$r['total'];
        }
        if (strtoupper($r['payment_method']) === 'WALLET') {
            $byPayment['wallet'] = (float)$r['total'];
        }
    }
}

/* ---------- Revenue by status ---------- */
$sql = "
    SELECT rental_status, SUM(total_price) AS total
    FROM rentals
    WHERE $where
    GROUP BY rental_status
";

$res = mysqli_query($conn, $sql);
$byStatus = [
    "active" => 0,
    "completed" => 0,
    "pending" => 0,
    "cancelled" => 0
];

if ($res) {
    while ($r = mysqli_fetch_assoc($res)) {
        $status = strtoupper($r['rental_status']);
        if ($status === 'ACTIVE') {
            $byStatus['active'] = (float)$r['total'];
        }
        if ($status === 'COMPLETED') {
            $byStatus['completed'] = (float)$r['total'];
        }
        if ($status === 'PENDING') {
            $byStatus['pending'] = (float)$r['total'];
        }
        if ($status === 'CANCELLED') {
            $byStatus['cancelled'] = (float)$r['total'];
        }
    }
}

/* ---------- Revenue by car ---------- */
$sql = "
    SELECT c.brand, c.model, SUM(r.total_price) AS revenue
    FROM rentals r
    JOIN cars c ON c.car_id = r.car_id
    WHERE $where
    GROUP BY r.car_id
    ORDER BY revenue DESC
";

$res = mysqli_query($conn, $sql);
$byCar = [];

if ($res) {
    while ($r = mysqli_fetch_assoc($res)) {
        $byCar[] = [
            "car_name" => $r['brand'] . " " . $r['model'],
            "revenue"  => (float)$r['revenue']
        ];
    }
}

/* ---------- Daily / Line chart ---------- */
$sql = "
    SELECT $group AS label, SUM(total_price) AS revenue
    FROM rentals
    WHERE $where
    GROUP BY label
    ORDER BY label
";

$res = mysqli_query($conn, $sql);
$daily = [];

if ($res) {
    while ($r = mysqli_fetch_assoc($res)) {
        $daily[] = [
            "label"   => $r['label'],
            "revenue" => (float)$r['revenue']
        ];
    }
}

/* ---------- Final JSON ---------- */
echo json_encode([
    "success"     => true,
    "by_payment" => $byPayment,
    "by_status"  => $byStatus,
    "by_car"     => $byCar,
    "daily"      => $daily
]);

exit;
