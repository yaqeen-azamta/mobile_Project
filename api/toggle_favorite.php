<?php
header("Content-Type: application/json; charset=UTF-8");
require_once __DIR__ . '/../config/db.php';

$raw = file_get_contents("php://input");
$data = json_decode($raw, true);

$customer_id = intval($data['customer_id'] ?? 0);
$car_id = intval($data['car_id'] ?? 0);

if ($customer_id<=0 || $car_id<=0) {
  echo json_encode(["success"=>false, "message"=>"Invalid data"]);
  exit;
}


$chk = $conn->prepare("SELECT favorite_id FROM favorites WHERE customer_id=? AND car_id=?");
$chk->bind_param("ii", $customer_id, $car_id);
$chk->execute();
$res = $chk->get_result();

if ($res->num_rows > 0) {

  $del = $conn->prepare("DELETE FROM favorites WHERE customer_id=? AND car_id=?");
  $del->bind_param("ii", $customer_id, $car_id);
  $del->execute();
  echo json_encode(["success"=>true, "favorited"=>false]);
} else {

  $ins = $conn->prepare("INSERT INTO favorites (customer_id, car_id) VALUES (?,?)");
  $ins->bind_param("ii", $customer_id, $car_id);
  $ins->execute();
  echo json_encode(["success"=>true, "favorited"=>true]);
}
