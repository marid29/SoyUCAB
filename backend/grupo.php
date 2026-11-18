<?php
error_reporting(E_ALL);
ini_set('display_errors', 0);
header('Content-Type: application/json; charset=utf-8');

$accion = $_REQUEST['accion'] ?? '';

function conectar() {
    // Recuerda cambiar dbname=Proyecto_Marlene si es necesario
    return @pg_connect("host=localhost 
                        port=5432 
                        dbname=bdentrega2
                        user=postgres 
                        password=a");
}

function responderError($mensaje) {
    echo json_encode([
        'success' => false, 
        'error' => $mensaje], 
        JSON_UNESCAPED_UNICODE);
    exit;
}

$conn = conectar();
if (!$conn) responderError('Error de conexión a la base de datos.');

// --- ACCIÓN: CREAR GRUPO ---
if ($accion === 'crear') {
    $nombre = $_POST['nombre'] ?? '';
    $descripcion = $_POST['descripcion'] ?? '';
    $estado = $_POST['estado'] ?? 'público'; // público, privado, secreto
    $id_creador = $_POST['id_creador'] ?? '';
    $id_admin = $_POST['id_admin'] ?? ''; // Puede ser el mismo creador inicialmente

    if (empty($nombre) || empty($id_creador)) {
        responderError('El nombre del grupo y el creador son obligatorios.');
    }

    // Usamos CURRENT_DATE para la fecha de creación automática
    $query = "INSERT INTO grupo (nombre, descripcion, fecha_creacion, estado, id_creador, id_admin) 
              VALUES ($1, $2, CURRENT_DATE, $3, $4, $5)";
    
    $res = pg_query_params($conn, $query, [$nombre, $descripcion, $estado, $id_creador, $id_admin]);

    if ($res) {
        echo json_encode(['success' => true, 'mensaje' => 'Grupo creado exitosamente']);
    } else {
        responderError('Error al insertar en la base de datos: ' . pg_last_error($conn));
    }
}

// --- ACCIÓN: LISTAR GRUPOS ---
if ($accion === 'listar') {
    // Esta consulta trae los datos del grupo y los nombres de las personas (creador y admin)
    $query = "SELECT g.*, 
              p1.nombre as nombre_creador, 
              p2.nombre as nombre_admin 
              FROM grupo g
              LEFT JOIN persona p1 ON g.id_creador = p1.id_persona
              LEFT JOIN persona p2 ON g.id_admin = p2.id_persona";
              
    $res = pg_query($conn, $query);
    $grupos = pg_fetch_all($res) ?: [];
    echo json_encode(['success' => true, 'grupos' => $grupos]);
}

// --- ACCIÓN: AÑADIR MIEMBRO AL GRUPO ---
if ($accion === 'añadir_miembro') {
    $id_grupo = $_POST['id_grupo'] ?? '';
    $id_persona = $_POST['id_persona'] ?? '';

    if (empty($id_grupo) || empty($id_persona)) {
        responderError('Debe seleccionar un grupo y una persona.');
    }

    // Insertamos en la tabla que une a personas con grupos
    $query = "INSERT INTO pertenece (id_grupo, id_persona, fecha_union) VALUES ($1, $2, CURRENT_DATE)";
    $res = pg_query_params($conn, $query, [$id_grupo, $id_persona]);

    if ($res) {
        echo json_encode(['success' => true, 'mensaje' => 'Miembro añadido correctamente']);
    } else {
        responderError('La persona ya pertenece a este grupo o hubo un error.');
    }
}




pg_close($conn);
?>
