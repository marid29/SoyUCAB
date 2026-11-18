<?php
header('Content-Type: application/json');

function conectar() {
    // Cambia los datos según tu configuración real
    $conn = @pg_connect("host=localhost port=5432 dbname=bdentrega2 user=postgres password=a");
    return $conn;
}

$conn = conectar();

// Si no hay conexión, enviamos el error y cortamos la ejecución
if (!$conn) {
    echo json_encode(["success" => false, "error" => "Error de conexión a la base de datos"]);
    exit;
}

// Usamos $_REQUEST para capturar tanto de GET como de POST
$accion = $_REQUEST['accion'] ?? 'listar_ubicaciones';

if ($accion === 'listar_ubicaciones') {
    // Asegúrate de que los nombres de las columnas coincidan con tu BD
    // En el JOIN: p.ubicacion_id debe coincidir con u.id_ubicacion
    $sql = "SELECT 
                p.nombres, 
                p.apellidos, 
                u.ciudad, 
                u.pais 
            FROM PERSONA p
            INNER JOIN UBICACION_GEOGRAFICA u ON p.ubicacion_id = u.id
            ORDER BY p.nombres ASC";

    $res = pg_query($conn, $sql);

    if ($res) {
        $usuarios = pg_fetch_all($res);
        // Si no hay datos, enviamos un array vacío, no un booleano false
        echo json_encode($usuarios ?: []);
    } else {
        echo json_encode(["success" => false, "error" => pg_last_error($conn)]);
    }
}

pg_close($conn);
?>