<?php
// Configuración de cabeceras para JSON y CORS
header('Content-Type: application/json; charset=utf-8');
header("Access-Control-Allow-Origin: *");

function conectar() {
    // Usamos @ para manejar el error manualmente si la extensión no está activa
    $conn = @pg_connect("host=localhost port=5432 dbname=bdentrega2 user=postgres password=a");
    return $conn;
}

$accion = $_REQUEST['accion'] ?? '';
$conn = conectar();

if (!$conn) {
    echo json_encode(["success" => false, "error" => "Error de conexión: " . pg_last_error()]);
    exit;
}

switch ($accion) {
    
    case 'listar':
    $sql = "SELECT 
                p.id_publicacion, 
                p.codigo_pub, 
                p.fecha, 
                p.descripcion,
                COALESCE(tp.nombre_tipo_publ, 'Sin tipo') as nombre_tipo_publ, 
                -- COALESCE para mostrar el autor (Persona o Grupo) En la tabla GRUPO la columna es 'nombre
                COALESCE(per.nombres || ' ' || per.apellidos, g.nombre, 'Desconocido') as autor
            FROM publicacion p
            LEFT JOIN publicacion_tipo pt ON p.id_publicacion = pt.id_publicacion
            LEFT JOIN tipo_publ tp ON pt.id_tipo_publ = tp.id_tipo_publ
            LEFT JOIN crea c ON p.id_publicacion = c.publicacion_id
            LEFT JOIN persona per ON c.persona_id = per.id
            LEFT JOIN elabora e ON p.id_publicacion = e.publicacion_id
            -- RELACIÓN CORRECTA: e.grupo_nombre se une con g.nombre
            LEFT JOIN grupo g ON e.grupo_nombre = g.nombre
            ORDER BY p.fecha DESC";
            
    $res = pg_query($conn, $sql);
    
    if (!$res) {
        die(json_encode(["error" => pg_last_error($conn)]));
    }

    $datos = pg_fetch_all($res);
    echo json_encode($datos ?: []);
    break;


case 'cargar_listas':
    $tipos = pg_fetch_all(pg_query($conn, "SELECT id_tipo_publ, nombre_tipo_publ FROM tipo_publ ORDER BY nombre_tipo_publ"));
    $personas = pg_fetch_all(pg_query($conn, "SELECT id, nombres || ' ' || apellidos as nombre FROM persona ORDER BY nombres"));
    $grupos = pg_fetch_all(pg_query($conn, "SELECT nombre FROM grupo ORDER BY nombre"));
    
    echo json_encode([
        "tipos" => $tipos ?: [],
        "personas" => $personas ?: [],
        "grupos" => $grupos ?: []
    ]);
    break;

case 'insertar':
    $codigo = $_POST['codigo_pub'];
    $descripcion = $_POST['descripcion'];
    $tipo_id = $_POST['id_tipo_publ'];
    $creador_tipo = $_POST['creador_tipo']; 
    $creador_id = $_POST['creador_id']; 

    pg_query($conn, "BEGIN");
    

    // NOTA: No insertamos id_publicacion, se genera solo por ser SERIAL
    // Incluimos la descripción en el INSERT
    $sqlPub = "INSERT INTO publicacion (codigo_pub, descripcion, fecha) 
            VALUES ('$codigo', '$descripcion', CURRENT_DATE) RETURNING id_publicacion";
    
    $resPub = pg_query($conn, $sqlPub);
    
    if ($resPub) {
        $id_pub = pg_fetch_result($resPub, 0, 0);

        // Relación con Tipo
        pg_query($conn, "INSERT INTO publicacion_tipo (id_publicacion, id_tipo_publ) VALUES ($id_pub, $tipo_id)");

        // Relación con Creador (Persona o Grupo)
        if ($creador_tipo === 'persona') {
            $sqlRel = "INSERT INTO crea (persona_id, publicacion_id) VALUES (".intval($creador_id).", $id_pub)";
        } else {
            // Se usa el nombre del grupo para la tabla elabora (columna grupo_nombre)
            $sqlRel = "INSERT INTO elabora (grupo_nombre, publicacion_id) VALUES ('$creador_id', $id_pub)";
        }

        if (pg_query($conn, $sqlRel)) {
            pg_query($conn, "COMMIT");
            echo json_encode(["success" => true]);
        } else {
            pg_query($conn, "ROLLBACK");
            echo json_encode(["success" => false, "error" => pg_last_error($conn)]);
        }
    } else {
        pg_query($conn, "ROLLBACK");
        echo json_encode(["success" => false, "error" => pg_last_error($conn)]);
    }
    break;


case 'eliminar':
    $id = isset($_GET['id_publicacion']) ? intval($_GET['id_publicacion']) : 0;

    if ($id > 0) {
        pg_query($conn, "BEGIN"); // Iniciamos transacción

        try {
            // 1. Eliminamos de las tablas que dependen de la publicación
            // Esto es por si el ON DELETE CASCADE no está configurado en estas tablas
            pg_query($conn, "DELETE FROM publicacion_tipo WHERE id_publicacion = $id");
            pg_query($conn, "DELETE FROM crea WHERE publicacion_id = $id");
            pg_query($conn, "DELETE FROM elabora WHERE publicacion_id = $id");

            // 2. Ahora sí, eliminamos la publicación principal
            $res = pg_query($conn, "DELETE FROM publicacion WHERE id_publicacion = $id");

            if ($res && pg_affected_rows($res) > 0) {
                pg_query($conn, "COMMIT");
                echo json_encode(["success" => true, "msj" => "Publicación eliminada de todo el sistema"]);
            } else {
                throw new Exception("La publicación no existe o ya fue eliminada.");
            }
        } catch (Exception $e) {
            pg_query($conn, "ROLLBACK");
            echo json_encode(["success" => false, "error" => $e->getMessage()]);
        }
    } else {
        echo json_encode(["success" => false, "error" => "ID no válido"]);
    }
    break;

        
    // Acción extra para que el frontend llene los selects
    case 'auxiliares':
        $tipos = pg_fetch_all(pg_query($conn, "SELECT id_tipo_publ, nombre_tipo_publ FROM tipo_publ"));
        $grupos = pg_fetch_all(pg_query($conn, "SELECT nombre_grupo FROM grupo"));
        echo json_encode(["tipos" => $tipos, "grupos" => $grupos]);
        break;
}

pg_close($conn);