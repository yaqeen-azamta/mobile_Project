<?php
header("Content-Type: application/json; charset=UTF-8");


$host = "localhost";
$user = "root";
$pass = "";
$db   = "carrentel";

$conn = mysqli_connect($host, $user, $pass, $db);

if (!$conn) {
  echo json_encode([
    "success" => false,
    "message" => "DB connection failed"
  ]);
  exit;
}

mysqli_set_charset($conn, "utf8");


$sql = "
  SELECT 
    customer_id,
    full_name,
    national_id,
    email,
    phone,
    imageName
  FROM customers
  ORDER BY customer_id ASC
";

$result = mysqli_query($conn, $sql);

if (!$result) {
  echo json_encode([
    "success" => false,
    "message" => "Query failed"
  ]);
  exit;
}

$customers = [];

while ($row = mysqli_fetch_assoc($result)) {
  $customers[] = $row;
}


echo json_encode([
  "success" => true,
  "customers" => $customers
]);

mysqli_close($conn);
