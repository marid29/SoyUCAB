<?php
$conn = pg_connect("
    host=localhost
    port=[colocar]
    dbname=bdentrega4
    user=[colocar]
    password=[colocar]
");

if (!$conn) {
    die("Error de conexión");
}
?>
