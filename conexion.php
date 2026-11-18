<?php
$conn = pg_connect("
    host=localhost
    port=5432
    dbname=bdentrega2
    user=postgres
    password=a
");

if (!$conn) {
    die("Error de conexión");
}
?>