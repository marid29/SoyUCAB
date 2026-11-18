<?php
// Desactivar la visualización de errores para evitar que se envíen como HTML
error_reporting(E_ALL);
ini_set('display_errors', 0);

header('Content-Type: application/json; charset=utf-8');

$accion = $_REQUEST['accion'] ?? '';

function conectar() {
    $conn = @pg_connect("
        host=localhost
        port=5432
        dbname=bdentrega2
        user=postgres
        password=a
    ");
    return $conn;
}

function responderError($mensaje) {
    echo json_encode([
        'success' => false,
        'error' => $mensaje
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

if ($accion === 'crear') {
    $conn = conectar();
    
    if (!$conn) {
        responderError('No se pudo conectar a la base de datos.');
    }

    $organizador_tipo = $_POST['organizador_tipo'] ?? '';
    $organizador_nombre = $_POST['organizador_nombre'] ?? '';

    // Validar que el organizador esté presente
    if (empty($organizador_tipo) || empty($organizador_nombre)) {
        responderError('Debe especificar el tipo de organizador y su nombre');
    }

    // El trigger validará que el organizador exista, así que solo insertamos directamente
    $result = pg_query_params($conn,
        "INSERT INTO evento(
            nombre_evento, lugar_evento, descripcion,
            fecha_inicio, fecha_fin, hora_inicio, hora_fin,
            estado, ciclo_vida, tipo, organizador_tipo, organizador_nombre
        ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)",
        [
            $_POST['nombre'] ?? '',
            $_POST['lugar'] ?? '',
            $_POST['descripcion'] ?? '',
            $_POST['inicio'] ?: null,
            $_POST['fin'] ?: null,
            $_POST['hora_inicio'] ?: null,
            $_POST['hora_fin'] ?: null,
            $_POST['estado'] ?? '',
            $_POST['ciclo'] ?? '',
            $_POST['tipo'] ?? '',
            $organizador_tipo,
            $organizador_nombre
        ]
    );

    if (!$result) {
        $error = pg_last_error($conn);
        pg_close($conn);
        responderError('Error al crear evento: ' . $error);
    }

    pg_close($conn);
    echo json_encode(['success' => true, 'message' => 'Evento creado exitosamente']);
    exit;
}

if ($accion === 'listar') {
    try {
        $conn = conectar();
        
        if (!$conn) {
            responderError('No se pudo conectar a la base de datos.');
        }
        
        $res = pg_query($conn, "SELECT * FROM evento ORDER BY id_evento");
        
        if (!$res) {
            $error = pg_last_error($conn);
            pg_close($conn);
            responderError('Error al ejecutar la consulta: ' . $error);
        }
        
        $eventos = [];
        while ($row = pg_fetch_assoc($res)) {
            // El nombre del organizador ya está en la tabla, solo asegurarnos de que se incluya
            $row['organizador_nombre'] = $row['organizador_nombre'] ?? null;
            $eventos[] = $row;
        }
        
        pg_close($conn);
        
        echo json_encode([
            'success' => true,
            'eventos' => $eventos
        ], JSON_UNESCAPED_UNICODE);
        exit;
    } catch (Exception $e) {
        if (isset($conn) && $conn) {
            @pg_close($conn);
        }
        responderError('Error al listar eventos: ' . $e->getMessage());
    }
}

if ($accion === 'obtener') {
    $conn = conectar();
    
    if (!$conn) {
        responderError('No se pudo conectar a la base de datos.');
    }
    
    $id = $_GET['id'] ?? '';
    
    if (empty($id)) {
        responderError('ID de evento no proporcionado');
    }
    
    $res = pg_query_params($conn, "SELECT * FROM evento WHERE id_evento = $1", [$id]);
    
    if (!$res) {
        responderError('Error al ejecutar la consulta: ' . pg_last_error($conn));
    }
    
    $evento = pg_fetch_assoc($res);
    
    if (!$evento) {
        responderError('Evento no encontrado');
    }
    
    // El nombre del organizador ya está en la tabla, solo asegurarnos de que se incluya
    $evento['organizador_nombre'] = $evento['organizador_nombre'] ?? null;
    
    pg_close($conn);
    
    echo json_encode([
        'success' => true,
        'evento' => $evento
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

if ($accion === 'actualizar') {
    $conn = conectar();
    
    if (!$conn) {
        responderError('No se pudo conectar a la base de datos.');
    }
    
    $id = $_POST['id'] ?? '';
    
    if (empty($id)) {
        responderError('ID de evento no proporcionado');
    }

    $organizador_tipo = $_POST['organizador_tipo'] ?? '';
    $organizador_nombre = $_POST['organizador_nombre'] ?? '';

    if (empty($organizador_tipo) || empty($organizador_nombre)) {
        responderError('Debe especificar el tipo de organizador y su nombre');
    }

    // El trigger validará que el organizador exista, así que solo actualizamos directamente
    $res = pg_query_params($conn,
        "UPDATE evento SET 
            nombre_evento = $1,
            lugar_evento = $2,
            descripcion = $3,
            fecha_inicio = $4,
            fecha_fin = $5,
            hora_inicio = $6,
            hora_fin = $7,
            estado = $8,
            ciclo_vida = $9,
            tipo = $10,
            organizador_tipo = $11,
            organizador_nombre = $12
        WHERE id_evento = $13",
        [
            $_POST['nombre'] ?? '',
            $_POST['lugar'] ?? '',
            $_POST['descripcion'] ?? '',
            $_POST['inicio'] ?: null,
            $_POST['fin'] ?: null,
            $_POST['hora_inicio'] ?: null,
            $_POST['hora_fin'] ?: null,
            $_POST['estado'] ?? '',
            $_POST['ciclo'] ?? '',
            $_POST['tipo'] ?? '',
            $organizador_tipo,
            $organizador_nombre,
            $id
        ]
    );
    
    if (!$res) {
        responderError('Error al actualizar evento: ' . pg_last_error($conn));
    }
    
    pg_close($conn);
    
    echo json_encode(['success' => true, 'message' => 'Evento actualizado exitosamente']);
    exit;
}

if ($accion === 'eliminar') {
    $conn = conectar();
    
    if (!$conn) {
        responderError('No se pudo conectar a la base de datos.');
    }
    
    $id = $_POST['id'] ?? '';
    
    if (empty($id)) {
        responderError('ID de evento no proporcionado');
    }
    
    $res = pg_query_params($conn, "DELETE FROM evento WHERE id_evento = $1", [$id]);
    
    if (!$res) {
        responderError('Error al eliminar evento: ' . pg_last_error($conn));
    }
    
    if (pg_affected_rows($res) === 0) {
        responderError('No se encontró el evento para eliminar');
    }
    
    pg_close($conn);
    
    echo json_encode(['success' => true, 'message' => 'Evento eliminado exitosamente']);
    exit;
}

if ($accion === 'porFecha') {
    $conn = conectar();
    
    if (!$conn) {
        responderError('No se pudo conectar a la base de datos.');
    }
    
    // Obtener todos los eventos agrupados por fecha
    // Usamos DISTINCT ON para agrupar por fecha_inicio y luego ordenamos
    $res = pg_query($conn, 
        "SELECT DISTINCT fecha_inicio 
         FROM evento 
         WHERE fecha_inicio IS NOT NULL 
         ORDER BY fecha_inicio"
    );
    
    if (!$res) {
        $error = pg_last_error($conn);
        pg_close($conn);
        responderError('Error al ejecutar la consulta: ' . $error);
    }
    
    $fechas = [];
    while ($row = pg_fetch_assoc($res)) {
        $fechas[] = $row['fecha_inicio'];
    }
    
    // Para cada fecha, obtener los eventos con nombres de organizadores
    $eventosPorFecha = [];
    foreach ($fechas as $fecha) {
        $resEventos = pg_query_params($conn, 
            "SELECT e.*
             FROM evento e
             WHERE e.fecha_inicio = $1 
             ORDER BY e.hora_inicio",
            [$fecha]
        );
        
        if ($resEventos) {
            $eventos = [];
            while ($row = pg_fetch_assoc($resEventos)) {
                // El nombre del organizador ya está en la tabla, solo asegurarnos de que se incluya
                $row['organizador_nombre'] = $row['organizador_nombre'] ?? null;
                $eventos[] = $row;
            }
            if (count($eventos) > 0) {
                $eventosPorFecha[] = [
                    'fecha' => $fecha,
                    'eventos' => $eventos
                ];
            }
        }
    }
    
    pg_close($conn);
    
    echo json_encode([
        'success' => true,
        'eventosPorFecha' => $eventosPorFecha
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

responderError('Acción no válida');
?>
