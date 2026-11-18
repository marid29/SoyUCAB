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

$tipo = $_GET['tipo'] ?? '';

if ($tipo === 'total_miembros') {
    $sql = "SELECT COUNT(id) AS total FROM persona"; // 
    $res = pg_query($conn, $sql);
    $data = pg_fetch_assoc($res);
    echo json_encode($data);
}

elseif ($tipo === 'ranking_usuarios') {
    // Ranking usuarios activos mes actual [cite: 1]
    $sql = "SELECT p.nombres, p.apellidos, COUNT(pub.id_publicacion) AS total
            FROM PERSONA p
            JOIN CREA c ON c.persona_id = p.id
            JOIN PUBLICACION pub ON pub.id_publicacion = c.publicacion_id
            WHERE EXTRACT(MONTH FROM pub.fecha) = EXTRACT(MONTH FROM CURRENT_DATE)
                AND EXTRACT(YEAR FROM pub.fecha) = EXTRACT(YEAR FROM CURRENT_DATE)
            GROUP BY p.id, p.nombres, p.apellidos
            ORDER BY total DESC LIMIT 10";
    $res = pg_query($conn, $sql);
    echo json_encode(pg_fetch_all($res) ?: []);

} elseif ($tipo === 'ranking_paises') {
    $sql = "SELECT UG.pais, COUNT(E.persona_id) AS total
            FROM EGRESADO E
            JOIN PERSONA P ON E.persona_id = P.id
            JOIN UBICACION_GEOGRAFICA UG ON P.ubicacion_id = UG.id
            GROUP BY UG.pais ORDER BY total DESC";
    $res = pg_query($conn, $sql);
    echo json_encode(pg_fetch_all($res) ?: []);
}

pg_close($conn);
// Puedes agregar los de profesores [cite: 2] y grupos [cite: 3] siguiendo el mismo patrón
?>