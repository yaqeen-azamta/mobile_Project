<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

$host = "127.0.0.1";
$user = "appuser";
$pass = "app123";
$db   = "carrentel";

$conn = mysqli_connect($host, $user, $pass, $db);

if (!$conn) {
  die("DB error: " . mysqli_connect_error());
}

?>
