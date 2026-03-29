<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

require_once __DIR__ . '/../config/db.php';

try {
    $base = "http://localhost/car_rental_backend/images/carImage/";

    $sql = "
        SELECT
            r.rental_id,
            CONCAT(c.brand, ' ', c.model) AS car_name,
            cu.full_name AS customer_name,
            r.start_date,
            r.end_date,
            r.rental_status,
            r.payment_method,
            r.total_price,
            CONCAT('$base', MIN(ci.imageName)) AS image_url
        FROM rentals r
        JOIN cars c ON r.car_id = c.car_id
        JOIN customers cu ON r.customer_id = cu.customer_id
        LEFT JOIN car_images ci ON ci.car_id = c.car_id
        GROUP BY
            r.rental_id,
            c.brand,
            c.model,
            cu.full_name,
            r.start_date,
            r.end_date,
            r.rental_status,
            r.payment_method,
            r.total_price
        ORDER BY r.rental_id DESC
    ";

    $result = mysqli_query($conn, $sql);
    if (!$result) {
        throw new Exception(mysqli_error($conn));
    }

    $data = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $data[] = $row;
    }

    echo json_encode([
        "success" => true,
        "data" => $data
    ]);
} catch (Exception $e) {
    echo json_encode([
        "success" => false,
        "message" => $e->getMessage()
    ]);
}
