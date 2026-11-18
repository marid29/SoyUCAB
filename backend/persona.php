<?php
// Desactivar la visualización de errores para evitar que se envíen como HTML
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

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
    try {
        $conn = conectar();
        
        if (!$conn) {
            responderError('No se pudo conectar a la base de datos.');
        }

        // Iniciar transacción
        @pg_query($conn, "BEGIN");

        $ocupacion = $_POST['ocupacion'] ?? null;
        
        // Mapear ocupación del frontend a la ocupación en la base de datos
        // IMPORTANTE: El trigger espera 'administrativo' y 'obrero', no 'personal_administrativo' ni 'personal_obrero'
        $ocupacionDB = null;
        $tablaSubtipo = null;
        $tipoEstudiante = $_POST['tipo_estudiante'] ?? null;
        $tipoProfesor = $_POST['tipo_profesor'] ?? null;
        
        if ($ocupacion) {
            switch (strtolower($ocupacion)) {
                case 'estudiante':
                    $ocupacionDB = 'estudiante';
                    $tablaSubtipo = 'estudiante';
                    // Validar que tipo_estudiante esté presente
                    if (empty($tipoEstudiante)) {
                        @pg_query($conn, "ROLLBACK");
                        pg_close($conn);
                        responderError('Error: Debe especificar el tipo de estudiante (pregrado, postgrado o extensión)');
                    }
                    break;
                case 'profesor':
                    $ocupacionDB = 'profesor';
                    $tablaSubtipo = 'profesor';
                    // Validar que tipo_profesor esté presente
                    if (empty($tipoProfesor)) {
                        @pg_query($conn, "ROLLBACK");
                        pg_close($conn);
                        responderError('Error: Debe especificar el tipo de profesor (activo o jubilado)');
                    }
                    break;
                case 'administrativo':
                    $ocupacionDB = 'administrativo'; // El trigger espera 'administrativo', no 'personal_administrativo'
                    $tablaSubtipo = 'personal_administrativo';
                    break;
                case 'obrero':
                    $ocupacionDB = 'obrero'; // El trigger espera 'obrero', no 'personal_obrero'
                    $tablaSubtipo = 'personal_obrero';
                    break;
            }
        }

        // Mapear nombre de ubicación a ID
        // IMPORTANTE: En la tabla PERSONA se guarda ubicacion_id (INT), no el nombre del país
        // La tabla ubicacion_geografica tiene columnas: ciudad, pais
        // Si hay múltiples ciudades para un país, tomamos el primer ID encontrado
        $ubicacionNombre = trim($_POST['ubicacion'] ?? '');
        $ubicacionId = null;
        
        if (!empty($ubicacionNombre)) {
            // Limpiar el nombre (quitar espacios extra)
            $ubicacionNombre = trim($ubicacionNombre);
            
            // Verificar primero que la tabla existe y tiene datos
            $resCheck = @pg_query($conn, "SELECT COUNT(*) as total FROM ubicacion_geografica");
            $totalFilas = 0;
            if ($resCheck) {
                $rowCheck = pg_fetch_assoc($resCheck);
                $totalFilas = $rowCheck['total'] ?? 0;
            }
            
            // Buscar por la columna 'pais' específicamente (case-insensitive)
            // Si hay múltiples ciudades para el mismo país, tomamos la primera
            $resUbicacion = @pg_query_params($conn,
                "SELECT id FROM ubicacion_geografica WHERE pais ILIKE $1 LIMIT 1",
                [$ubicacionNombre]
            );
            
            $errorConsulta = pg_last_error($conn);
            
            if ($resUbicacion !== false && pg_num_rows($resUbicacion) > 0) {
                $rowUbicacion = pg_fetch_assoc($resUbicacion);
                $ubicacionId = $rowUbicacion['id'] ?? null;
            } else {
                // Si no se encuentra con ILIKE, intentar búsqueda exacta
                $resUbicacion2 = @pg_query_params($conn,
                    "SELECT id FROM ubicacion_geografica WHERE pais = $1 LIMIT 1",
                    [$ubicacionNombre]
                );
                
                if ($resUbicacion2 !== false && pg_num_rows($resUbicacion2) > 0) {
                    $rowUbicacion = pg_fetch_assoc($resUbicacion2);
                    $ubicacionId = $rowUbicacion['id'] ?? null;
                } else {
                    // Debug: ver qué hay en la tabla para ayudar a identificar el problema
                    $resDebug = @pg_query($conn, "SELECT id, ciudad, pais FROM ubicacion_geografica LIMIT 10");
                    $debugInfo = 'No se encontró la ubicación "' . $ubicacionNombre . '". ';
                    $debugInfo .= 'Total de filas en la tabla: ' . $totalFilas . '. ';
                    
                    if ($errorConsulta) {
                        $debugInfo .= 'Error en consulta: ' . $errorConsulta . '. ';
                    }
                    
                    if ($resDebug !== false && pg_num_rows($resDebug) > 0) {
                        $debugInfo .= 'Ubicaciones disponibles en la BD: ';
                        while ($row = pg_fetch_assoc($resDebug)) {
                            $id = $row['id'] ?? 'sin id';
                            $ciudad = $row['ciudad'] ?? 'sin ciudad';
                            $pais = $row['pais'] ?? 'sin pais';
                            $debugInfo .= "[id=$id, ciudad=$ciudad, pais=$pais]; ";
                        }
                    } else {
                        $errorDebug = pg_last_error($conn);
                        $debugInfo .= 'No se pudieron obtener las ubicaciones. ';
                        if ($errorDebug) {
                            $debugInfo .= 'Error al consultar: ' . $errorDebug;
                        }
                    }
                    
                    @pg_query($conn, "ROLLBACK");
                    pg_close($conn);
                    responderError($debugInfo);
                }
            }
        }

        // IMPORTANTE: El trigger AFTER INSERT se ejecuta después del INSERT en PERSONA
        // Necesitamos deshabilitar temporalmente el trigger, insertar todo, y luego habilitarlo
        // O usar un procedimiento almacenado que maneje todo
        
        // Deshabilitar el trigger temporalmente
        @pg_query($conn, "ALTER TABLE persona DISABLE TRIGGER tg_validar_subtipo_persona");
        
        // Primero insertar en la tabla persona y obtener el ID
        $insertPersona = @pg_query_params($conn,
            "INSERT INTO persona(correo, nombres, apellidos, fecha_de_nacimiento, sexo, ocupacion, celular, ubicacion_id) 
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id",
            [
                $_POST['correo'] ?? '',
                $_POST['nombres'] ?? '',
                $_POST['apellidos'] ?? '',
                $_POST['fecha'] ?: null,
                $_POST['sexo'] ?: null,
                $ocupacionDB ?: null,
                $_POST['celular'] ?: null,
                $ubicacionId ?: null
            ]
        );

        if (!$insertPersona) {
            @pg_query($conn, "ALTER TABLE persona ENABLE TRIGGER tg_validar_subtipo_persona");
            @pg_query($conn, "ROLLBACK");
            $error = pg_last_error($conn);
            pg_close($conn);
            responderError('Error al insertar en tabla persona: ' . $error . '. Datos recibidos: correo=' . ($_POST['correo'] ?? 'vacío') . ', ocupacion=' . ($ocupacionDB ?? 'vacío') . ', ubicacion_id=' . ($ubicacionId ?? 'null'));
        }

        $personaRow = pg_fetch_assoc($insertPersona);
        $personaId = $personaRow['id'] ?? null;

        if (!$personaId) {
            @pg_query($conn, "ALTER TABLE persona ENABLE TRIGGER tg_validar_subtipo_persona");
            @pg_query($conn, "ROLLBACK");
            pg_close($conn);
            responderError('Error: No se pudo obtener el ID de la persona creada. Resultado del INSERT: ' . json_encode($personaRow));
        }

        // Ahora, si hay una tabla subtipo correspondiente, insertar en esa tabla
        if ($tablaSubtipo && $personaId) {
            $insertSubtipo = false;
            
            switch ($tablaSubtipo) {
                case 'estudiante':
                    // ESTUDIANTE requiere tipo_estudiante
                    if (empty($tipoEstudiante)) {
                        @pg_query($conn, "ALTER TABLE persona ENABLE TRIGGER tg_validar_subtipo_persona");
                        @pg_query($conn, "ROLLBACK");
                        pg_close($conn);
                        responderError('Error: tipo_estudiante es requerido para estudiantes');
                    }
                    $query = "INSERT INTO estudiante (persona_id, tipo_estudiante) VALUES ($1, $2)";
                    $insertSubtipo = @pg_query_params($conn, $query, [$personaId, $tipoEstudiante]);
                    break;
                case 'profesor':
                    // PROFESOR requiere tipo_profesor
                    if (empty($tipoProfesor)) {
                        @pg_query($conn, "ALTER TABLE persona ENABLE TRIGGER tg_validar_subtipo_persona");
                        @pg_query($conn, "ROLLBACK");
                        pg_close($conn);
                        responderError('Error: tipo_profesor es requerido para profesores');
                    }
                    $query = "INSERT INTO profesor (persona_id, tipo_profesor) VALUES ($1, $2)";
                    $insertSubtipo = @pg_query_params($conn, $query, [$personaId, $tipoProfesor]);
                    break;
                case 'personal_administrativo':
                    // PERSONAL_ADMINISTRATIVO solo requiere persona_id
                    $query = "INSERT INTO personal_administrativo (persona_id) VALUES ($1)";
                    $insertSubtipo = @pg_query_params($conn, $query, [$personaId]);
                    break;
                case 'personal_obrero':
                    // PERSONAL_OBRERO solo requiere persona_id
                    $query = "INSERT INTO personal_obrero (persona_id) VALUES ($1)";
                    $insertSubtipo = @pg_query_params($conn, $query, [$personaId]);
                    break;
            }
            
            if (!$insertSubtipo) {
                @pg_query($conn, "ALTER TABLE persona ENABLE TRIGGER tg_validar_subtipo_persona");
                @pg_query($conn, "ROLLBACK");
                $errorSubtipo = pg_last_error($conn);
                pg_close($conn);
                $detalleError = 'Error al crear registro en tabla ' . $tablaSubtipo . ': ' . $errorSubtipo;
                if ($tablaSubtipo === 'estudiante') {
                    $detalleError .= '. tipo_estudiante=' . ($tipoEstudiante ?? 'null') . ', persona_id=' . $personaId;
                } elseif ($tablaSubtipo === 'profesor') {
                    $detalleError .= '. tipo_profesor=' . ($tipoProfesor ?? 'null') . ', persona_id=' . $personaId;
                } else {
                    $detalleError .= '. persona_id=' . $personaId;
                }
                responderError($detalleError);
            }
        }
        
        // Habilitar el trigger de nuevo
        @pg_query($conn, "ALTER TABLE persona ENABLE TRIGGER tg_validar_subtipo_persona");

        // Confirmar transacción
        @pg_query($conn, "COMMIT");
        pg_close($conn);
        
        echo json_encode(['success' => true, 'message' => 'Persona creada exitosamente'], JSON_UNESCAPED_UNICODE);
        exit;
    } catch (Exception $e) {
        if (isset($conn) && $conn) {
            @pg_query($conn, "ROLLBACK");
            @pg_close($conn);
        }
        responderError('Error al crear persona: ' . $e->getMessage());
    }
}

if ($accion === 'listar') {
    try {
        $conn = conectar();
        
        if (!$conn) {
            responderError('No se pudo conectar a la base de datos.');
        }
        
        $res = @pg_query($conn, "SELECT * FROM persona ORDER BY id");
        
        if (!$res) {
            $error = pg_last_error($conn);
            pg_close($conn);
            responderError('Error al ejecutar la consulta: ' . $error);
        }
        
        $personas = [];
        while ($row = pg_fetch_assoc($res)) {
            // Obtener el nombre de la ubicación si existe ubicacion_id
            if (!empty($row['ubicacion_id'])) {
                $resUbicacion = @pg_query_params($conn, 
                    "SELECT * FROM ubicacion_geografica WHERE id = $1 LIMIT 1", 
                    [$row['ubicacion_id']]
                );
                
                if ($resUbicacion && pg_num_rows($resUbicacion) > 0) {
                    $ubicacion = pg_fetch_assoc($resUbicacion);
                    if ($ubicacion) {
                        // Intentar obtener el nombre de diferentes columnas posibles
                        $row['ubicacion_nombre'] = $ubicacion['pais'] ?? 
                                                   $ubicacion['nombre_pais'] ?? 
                                                   $ubicacion['pais_nombre'] ?? 
                                                   $ubicacion['nombre_ubicacion'] ?? 
                                                   $ubicacion['nombre'] ?? 
                                                   $ubicacion['ciudad'] ?? 
                                                   $ubicacion['descripcion'] ?? 
                                                   null;
                    }
                }
            }
            $personas[] = $row;
        }
        
        pg_close($conn);
        
        echo json_encode([
            'success' => true,
            'personas' => $personas
        ], JSON_UNESCAPED_UNICODE);
        exit;
    } catch (Exception $e) {
        if (isset($conn) && $conn) {
            @pg_close($conn);
        }
        responderError('Error al listar personas: ' . $e->getMessage());
    }
}

if ($accion === 'obtener') {
    try {
        $conn = conectar();
        
        if (!$conn) {
            responderError('No se pudo conectar a la base de datos.');
        }
        
        $id = $_GET['id'] ?? '';
        
        if (empty($id)) {
            pg_close($conn);
            responderError('ID de persona no proporcionado');
        }
        
        $res = @pg_query_params($conn, "SELECT * FROM persona WHERE id = $1", [$id]);
        
        if (!$res) {
            $error = pg_last_error($conn);
            pg_close($conn);
            responderError('Error al ejecutar la consulta: ' . $error);
        }
        
        $persona = pg_fetch_assoc($res);
        
        if (!$persona) {
            pg_close($conn);
            responderError('Persona no encontrada');
        }
        
        // Obtener el nombre de la ubicación si existe ubicacion_id
        if (!empty($persona['ubicacion_id'])) {
            $resUbicacion = @pg_query_params($conn, 
                "SELECT * FROM ubicacion_geografica WHERE id = $1 LIMIT 1", 
                [$persona['ubicacion_id']]
            );
            
            if ($resUbicacion && pg_num_rows($resUbicacion) > 0) {
                $ubicacion = pg_fetch_assoc($resUbicacion);
                if ($ubicacion) {
                    // Intentar obtener el nombre de diferentes columnas posibles
                    $persona['ubicacion_nombre'] = $ubicacion['pais'] ?? 
                                                     $ubicacion['nombre_pais'] ?? 
                                                     $ubicacion['pais_nombre'] ?? 
                                                     $ubicacion['nombre_ubicacion'] ?? 
                                                     $ubicacion['nombre'] ?? 
                                                     $ubicacion['ciudad'] ?? 
                                                     $ubicacion['descripcion'] ?? 
                                                     null;
                }
            }
        }
        
        // Obtener tipo_estudiante o tipo_profesor según la ocupación
        if ($persona['ocupacion'] === 'estudiante') {
            $resEstudiante = @pg_query_params($conn,
                "SELECT tipo_estudiante FROM estudiante WHERE persona_id = $1 LIMIT 1",
                [$persona['id']]
            );
            if ($resEstudiante && pg_num_rows($resEstudiante) > 0) {
                $estudiante = pg_fetch_assoc($resEstudiante);
                $persona['tipo_estudiante'] = $estudiante['tipo_estudiante'] ?? null;
            }
        } elseif ($persona['ocupacion'] === 'profesor') {
            $resProfesor = @pg_query_params($conn,
                "SELECT tipo_profesor FROM profesor WHERE persona_id = $1 LIMIT 1",
                [$persona['id']]
            );
            if ($resProfesor && pg_num_rows($resProfesor) > 0) {
                $profesor = pg_fetch_assoc($resProfesor);
                $persona['tipo_profesor'] = $profesor['tipo_profesor'] ?? null;
            }
        }
        
        pg_close($conn);
        
        echo json_encode([
            'success' => true,
            'persona' => $persona
        ], JSON_UNESCAPED_UNICODE);
        exit;
    } catch (Exception $e) {
        if (isset($conn) && $conn) {
            @pg_close($conn);
        }
        responderError('Error al obtener persona: ' . $e->getMessage());
    }
}

if ($accion === 'actualizar') {
    try {
        $conn = conectar();
        
        if (!$conn) {
            responderError('No se pudo conectar a la base de datos.');
        }
        
        $id = $_POST['id'] ?? '';
        $correo = $_POST['correo'] ?? '';
        $nombres = $_POST['nombres'] ?? '';
        $apellidos = $_POST['apellidos'] ?? '';
        $fecha = $_POST['fecha'] ?: null;
        $sexo = $_POST['sexo'] ?: null;
        $ocupacion = $_POST['ocupacion'] ?: null;
        $celular = $_POST['celular'] ?: null;
        $ubicacionNombre = $_POST['ubicacion'] ?? null;
        
        if (empty($id)) {
            pg_close($conn);
            responderError('ID de persona no proporcionado');
        }
        
        // Mapear nombre de ubicación a ID
        $ubicacionId = null;
        if ($ubicacionNombre) {
            $resUbicacion = @pg_query_params($conn,
                "SELECT id FROM ubicacion_geografica WHERE 
                 pais ILIKE $1 OR nombre_pais ILIKE $1 OR pais_nombre ILIKE $1 OR 
                 nombre_ubicacion ILIKE $1 OR nombre ILIKE $1 OR ciudad ILIKE $1 OR descripcion ILIKE $1 
                 LIMIT 1",
                ['%' . $ubicacionNombre . '%']
            );
            
            if ($resUbicacion && pg_num_rows($resUbicacion) > 0) {
                $rowUbicacion = pg_fetch_assoc($resUbicacion);
                $ubicacionId = $rowUbicacion['id'] ?? null;
            } else {
                // Si no se encuentra con LIKE, intentar búsqueda exacta
                $resUbicacion2 = @pg_query_params($conn,
                    "SELECT id FROM ubicacion_geografica WHERE 
                     pais = $1 OR nombre_pais = $1 OR pais_nombre = $1 OR 
                     nombre_ubicacion = $1 OR nombre = $1 OR ciudad = $1 OR descripcion = $1 
                     LIMIT 1",
                    [$ubicacionNombre]
                );
                if ($resUbicacion2 && pg_num_rows($resUbicacion2) > 0) {
                    $rowUbicacion = pg_fetch_assoc($resUbicacion2);
                    $ubicacionId = $rowUbicacion['id'] ?? null;
                }
            }
        }
        
        $res = @pg_query_params($conn,
            "UPDATE persona SET 
                correo = $1,
                nombres = $2,
                apellidos = $3,
                fecha_de_nacimiento = $4,
                sexo = $5,
                ocupacion = $6,
                celular = $7,
                ubicacion_id = $8
            WHERE id = $9",
            [$correo, $nombres, $apellidos, $fecha, $sexo, $ocupacion, $celular, $ubicacionId, $id]
        );
        
        if (!$res) {
            $error = pg_last_error($conn);
            pg_close($conn);
            responderError('Error al actualizar persona: ' . $error);
        }
        
        pg_close($conn);
        
        echo json_encode(['success' => true, 'message' => 'Persona actualizada exitosamente'], JSON_UNESCAPED_UNICODE);
        exit;
    } catch (Exception $e) {
        if (isset($conn) && $conn) {
            @pg_close($conn);
        }
        responderError('Error al actualizar persona: ' . $e->getMessage());
    }
}

if ($accion === 'eliminar') {
    try {
        $conn = conectar();
        
        if (!$conn) {
            responderError('No se pudo conectar a la base de datos.');
        }
        
        $id = $_POST['id'] ?? '';
        
        if (empty($id)) {
            pg_close($conn);
            responderError('ID de persona no proporcionado');
        }
        
        // Iniciar transacción
        @pg_query($conn, "BEGIN");
        
        // Primero, obtener la información de la persona para saber su ocupación
        $resPersona = @pg_query_params($conn, "SELECT ocupacion FROM persona WHERE id = $1", [$id]);
        
        if (!$resPersona || pg_num_rows($resPersona) === 0) {
            @pg_query($conn, "ROLLBACK");
            pg_close($conn);
            responderError('No se encontró la persona con ID ' . $id);
        }
        
        $persona = pg_fetch_assoc($resPersona);
        $ocupacion = $persona['ocupacion'] ?? null;
        
        // Eliminar primero el registro de la tabla subtipo correspondiente
        if ($ocupacion) {
            $tablaSubtipo = null;
            switch (strtolower($ocupacion)) {
                case 'estudiante':
                    $tablaSubtipo = 'estudiante';
                    break;
                case 'profesor':
                    $tablaSubtipo = 'profesor';
                    break;
                case 'egresado':
                    $tablaSubtipo = 'egresado';
                    break;
                case 'administrativo':
                    $tablaSubtipo = 'personal_administrativo';
                    break;
                case 'obrero':
                    $tablaSubtipo = 'personal_obrero';
                    break;
            }
            
            if ($tablaSubtipo) {
                // Eliminar el registro de la tabla subtipo
                $resDeleteSubtipo = @pg_query_params($conn, 
                    "DELETE FROM $tablaSubtipo WHERE persona_id = $1", 
                    [$id]
                );
                
                if (!$resDeleteSubtipo) {
                    @pg_query($conn, "ROLLBACK");
                    $errorSubtipo = pg_last_error($conn);
                    pg_close($conn);
                    responderError('Error al eliminar registro de tabla ' . $tablaSubtipo . ': ' . $errorSubtipo);
                }
            }
        }
        
        // Ahora eliminar la persona
        $res = @pg_query_params($conn, "DELETE FROM persona WHERE id = $1", [$id]);
        
        if (!$res) {
            @pg_query($conn, "ROLLBACK");
            $error = pg_last_error($conn);
            pg_close($conn);
            responderError('Error al eliminar persona: ' . $error);
        }
        
        if (pg_affected_rows($res) === 0) {
            @pg_query($conn, "ROLLBACK");
            pg_close($conn);
            responderError('No se encontró la persona para eliminar');
        }
        
        // Confirmar transacción
        @pg_query($conn, "COMMIT");
        pg_close($conn);
        
        echo json_encode(['success' => true, 'message' => 'Persona eliminada exitosamente'], JSON_UNESCAPED_UNICODE);
        exit;
    } catch (Exception $e) {
        if (isset($conn) && $conn) {
            @pg_query($conn, "ROLLBACK");
            @pg_close($conn);
        }
        responderError('Error al eliminar persona: ' . $e->getMessage());
    }
}

if ($accion === 'buscar') {
    $conn = conectar();
    
    if (!$conn) {
        responderError('No se pudo conectar a la base de datos.');
    }
    
    $nombre = $_GET['nombre'] ?? '';
    $ocupacion = $_GET['ocupacion'] ?? '';
    
    // Query simple sin JOIN - obtendremos la ubicación por separado si es necesario
    $query = "SELECT p.* FROM persona p WHERE 1=1";
    $params = [];
    $paramCount = 1;
    
    if (!empty($nombre)) {
        $query .= " AND (p.nombres ILIKE $" . $paramCount . " OR p.apellidos ILIKE $" . $paramCount . ")";
        $params[] = '%' . $nombre . '%';
        $paramCount++;
    }
    
    if (!empty($ocupacion)) {
        $query .= " AND p.ocupacion ILIKE $" . $paramCount;
        $params[] = '%' . $ocupacion . '%';
        $paramCount++;
    }
    
    $query .= " ORDER BY p.nombres, p.apellidos";
    
    $res = pg_query_params($conn, $query, $params);
    
    if (!$res) {
        // Si el JOIN falla, intentar sin JOIN
        $querySimple = "SELECT p.* FROM persona p WHERE 1=1";
        $paramsSimple = [];
        $paramCountSimple = 1;
        
        if (!empty($nombre)) {
            $querySimple .= " AND (p.nombres ILIKE $" . $paramCountSimple . " OR p.apellidos ILIKE $" . $paramCountSimple . ")";
            $paramsSimple[] = '%' . $nombre . '%';
            $paramCountSimple++;
        }
        
        if (!empty($ocupacion)) {
            $querySimple .= " AND p.ocupacion ILIKE $" . $paramCountSimple;
            $paramsSimple[] = '%' . $ocupacion . '%';
            $paramCountSimple++;
        }
        
        $querySimple .= " ORDER BY p.nombres, p.apellidos";
        $res = pg_query_params($conn, $querySimple, $paramsSimple);
        
        if (!$res) {
            $error = pg_last_error($conn);
            pg_close($conn);
            responderError('Error al ejecutar la consulta: ' . $error);
        }
    }
    
    $personas = [];
    while ($row = pg_fetch_assoc($res)) {
        // Obtener el país de la ubicación
        if (!empty($row['ubicacion_id'])) {
            $resUbicacion = @pg_query_params($conn, 
                "SELECT * FROM ubicacion_geografica WHERE id = $1", 
                [$row['ubicacion_id']]
            );
            
            if ($resUbicacion) {
                $ubicacion = pg_fetch_assoc($resUbicacion);
                if ($ubicacion) {
                    // Intentar obtener el país de diferentes columnas posibles
                    $row['ubicacion_nombre'] = $ubicacion['pais'] ?? 
                                               $ubicacion['nombre_pais'] ?? 
                                               $ubicacion['pais_nombre'] ?? 
                                               $ubicacion['nombre_ubicacion'] ?? 
                                               $ubicacion['nombre'] ?? 
                                               $ubicacion['ciudad'] ?? 
                                               $ubicacion['descripcion'] ?? 
                                               null;
                }
            }
        }
        $personas[] = $row;
    }
    
    pg_close($conn);
    
    echo json_encode([
        'success' => true,
        'personas' => $personas
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

if ($accion === 'perfil') {
    $conn = conectar();
    
    if (!$conn) {
        responderError('No se pudo conectar a la base de datos.');
    }
    
    $id = $_GET['id'] ?? '';
    
    if (empty($id)) {
        pg_close($conn);
        responderError('ID de persona no proporcionado');
    }
    
    // Obtener datos de la persona - primero intentamos sin JOIN para evitar errores
    $res = pg_query_params($conn, 
        "SELECT * FROM persona WHERE id = $1", 
        [$id]
    );
    
    if (!$res) {
        $error = pg_last_error($conn);
        pg_close($conn);
        responderError('Error al ejecutar la consulta: ' . $error);
    }
    
    $persona = pg_fetch_assoc($res);
    
    if (!$persona) {
        pg_close($conn);
        responderError('Persona no encontrada');
    }
    
    // Intentar obtener el país de la ubicación si existe ubicacion_id
    $ubicacion_nombre = null;
    if (!empty($persona['ubicacion_id'])) {
        $resUbicacion = @pg_query_params($conn, 
            "SELECT * FROM ubicacion_geografica WHERE id = $1", 
            [$persona['ubicacion_id']]
        );
        
        if ($resUbicacion) {
            $ubicacion = pg_fetch_assoc($resUbicacion);
            if ($ubicacion) {
                // Intentar obtener el país de diferentes columnas posibles
                $ubicacion_nombre = $ubicacion['pais'] ?? 
                                   $ubicacion['nombre_pais'] ?? 
                                   $ubicacion['pais_nombre'] ?? 
                                   $ubicacion['nombre_ubicacion'] ?? 
                                   $ubicacion['nombre'] ?? 
                                   $ubicacion['ciudad'] ?? 
                                   $ubicacion['descripcion'] ?? 
                                   null;
            }
        }
    }
    
    $persona['ubicacion_nombre'] = $ubicacion_nombre;
    
    // Obtener publicaciones de la persona con JOIN a tipo_publ
    // Tabla crea relaciona persona_id con publicacion_id
    // Tabla publicacion tiene Id_Publicacion, Codigo_Pub, fecha, y probablemente Id_tipo_publ
    // Tabla tipo_publ tiene Id_tipo_publ y Nombre_tipo_publ
    $publicaciones = [];
    
    // Intentar primero con nombres de columnas en mayúsculas (como en los INSERTs)
    $resPublicaciones = @pg_query_params($conn, 
        "SELECT p.Id_Publicacion, p.Codigo_Pub, p.fecha, p.Id_tipo_publ,
                tp.Nombre_tipo_publ, c.persona_id, c.publicacion_id
         FROM crea c
         INNER JOIN publicacion p ON c.publicacion_id = p.Id_Publicacion
         LEFT JOIN tipo_publ tp ON p.Id_tipo_publ = tp.Id_tipo_publ
         WHERE c.persona_id = $1 
         ORDER BY p.fecha DESC",
        [$id]
    );
    
    if ($resPublicaciones && pg_num_rows($resPublicaciones) > 0) {
        while ($row = pg_fetch_assoc($resPublicaciones)) {
            $publicaciones[] = $row;
        }
    } else {
        // Si falla, intentar con nombres de columnas en minúsculas
        $resPublicaciones2 = @pg_query($conn, 
            "SELECT p.id_publicacion, p.codigo_pub, p.fecha, p.id_tipo_publ,
                    tp.nombre_tipo_publ, c.persona_id, c.publicacion_id
             FROM crea c
             INNER JOIN publicacion p ON c.publicacion_id = p.id_publicacion
             LEFT JOIN tipo_publ tp ON p.id_tipo_publ = tp.id_tipo_publ
             WHERE c.persona_id = " . intval($id) . " 
             ORDER BY p.fecha DESC"
        );
        
        if ($resPublicaciones2 && pg_num_rows($resPublicaciones2) > 0) {
            while ($row = pg_fetch_assoc($resPublicaciones2)) {
                $publicaciones[] = $row;
            }
        } else {
            // Último intento: consulta simple sin JOIN a tipo_publ
            $resPublicaciones3 = @pg_query($conn, 
                "SELECT p.*, c.persona_id, c.publicacion_id
                 FROM crea c
                 INNER JOIN publicacion p ON c.publicacion_id = p.Id_Publicacion
                 WHERE c.persona_id = " . intval($id) . " 
                 ORDER BY p.fecha DESC"
            );
            
            if ($resPublicaciones3 && pg_num_rows($resPublicaciones3) > 0) {
                while ($row = pg_fetch_assoc($resPublicaciones3)) {
                    // Intentar obtener el tipo por separado
                    if (!empty($row['Id_tipo_publ'])) {
                        $resTipo = @pg_query($conn, 
                            "SELECT Nombre_tipo_publ FROM tipo_publ WHERE Id_tipo_publ = " . intval($row['Id_tipo_publ'])
                        );
                        if ($resTipo && pg_num_rows($resTipo) > 0) {
                            $tipoRow = pg_fetch_assoc($resTipo);
                            $row['Nombre_tipo_publ'] = $tipoRow['Nombre_tipo_publ'];
                        }
                    }
                    $publicaciones[] = $row;
                }
            }
        }
    }
    
    pg_close($conn);
    
    echo json_encode([
        'success' => true,
        'persona' => $persona,
        'publicaciones' => $publicaciones
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

responderError('Acción no válida');
?>
