DROP TABLE IF EXISTS persona CASCADE;
DROP TABLE IF EXISTS estudiante CASCADE;
DROP TABLE IF EXISTS profesor CASCADE;
DROP TABLE IF EXISTS tutoria CASCADE;
DROP TABLE IF EXISTS egresado CASCADE;
DROP TABLE IF EXISTS personal_administrativo CASCADE;
DROP TABLE IF EXISTS personal_obrero CASCADE;
DROP TABLE IF EXISTS ubicacion_geografica CASCADE;
DROP TABLE IF EXISTS idioma CASCADE;
DROP TABLE IF EXISTS persona_idioma CASCADE;
DROP TABLE IF EXISTS interes_profesional CASCADE;
DROP TABLE IF EXISTS persona_interes_profesional CASCADE;
DROP TABLE IF EXISTS habilidades_tecnicas CASCADE;
DROP TABLE IF EXISTS persona_habilidades_tecnicas CASCADE;
DROP TABLE IF EXISTS relacion CASCADE;
DROP TABLE IF EXISTS nombre_relacion CASCADE;
DROP TABLE IF EXISTS relacion_nombre_relacion CASCADE;
DROP TABLE IF EXISTS grupo CASCADE;
DROP TABLE IF EXISTS evento CASCADE;
DROP TABLE IF EXISTS categoria CASCADE;
DROP TABLE IF EXISTS servicio_ucab CASCADE;
DROP TABLE IF EXISTS tipo_serv CASCADE;
DROP TABLE IF EXISTS org_asociada CASCADE;
DROP TABLE IF EXISTS publicacion CASCADE;
DROP TABLE IF EXISTS tipo_publ CASCADE;
DROP TABLE IF EXISTS dependencia_ucab CASCADE;
DROP TABLE IF EXISTS participa_grupo CASCADE;
DROP TABLE IF EXISTS persona_pertenece_dependencia CASCADE;
DROP TABLE IF EXISTS valoracion_publicacion CASCADE;
DROP TABLE IF EXISTS asiste_evento CASCADE;
DROP TABLE IF EXISTS administra_persona_servicio CASCADE;
DROP TABLE IF EXISTS evento_publicaciones CASCADE;

-- TABLAS PARA ENTIDAD PERSONA

CREATE TABLE UBICACION_GEOGRAFICA (
	id SERIAL PRIMARY KEY, -- SERIAL es para incrementar el valor del id
	ciudad VARCHAR(50),
	pais VARCHAR(50)
);

CREATE TABLE IDIOMA (
	id SERIAL PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL
);

CREATE TABLE PERSONA (
	id SERIAL PRIMARY KEY,
	correo VARCHAR(30) UNIQUE NOT NULL,
	nombres VARCHAR(30) NOT NULL,
	apellidos VARCHAR(30) NOT NULL,
	fecha_de_nacimiento DATE,
	sexo CHAR(1) CHECK (sexo IN ('F', 'M')),
	ocupacion VARCHAR(30),
	celular VARCHAR(15) CHECK (celular ~ '^\+[0-9]{10,15}$'), -- entre 10 y 15 dígitos, cada uno entre 0 y 9, con el +
	ubicacion_id INT REFERENCES UBICACION_GEOGRAFICA(id)
);

CREATE TABLE PERSONA_IDIOMA (
	persona_id INT REFERENCES PERSONA(id),
  	idioma_id INT REFERENCES IDIOMA(id),
  	PRIMARY KEY (persona_id, idioma_id)
);

CREATE TABLE ESTUDIANTE (
    persona_id INT PRIMARY KEY REFERENCES PERSONA(id),
    tipo_estudiante VARCHAR(20) NOT NULL CHECK (tipo_estudiante IN ('pregrado', 'postgrado', 'extension'))
);

CREATE TABLE PROFESOR (
    persona_id INT PRIMARY KEY REFERENCES PERSONA(id),
	tipo_profesor VARCHAR(20) NOT NULL CHECK (tipo_profesor IN ('activo', 'jubilado'))
);

CREATE TABLE TUTORIA (
    profesor_id INT REFERENCES PROFESOR(persona_id),
    estudiante_id INT REFERENCES ESTUDIANTE(persona_id),
    PRIMARY KEY (profesor_id, estudiante_id)
);

CREATE TABLE EGRESADO (
    persona_id INT PRIMARY KEY REFERENCES PERSONA(id)
);

CREATE TABLE PERSONAL_ADMINISTRATIVO (
    persona_id INT PRIMARY KEY REFERENCES PERSONA(id)
);

CREATE TABLE PERSONAL_OBRERO (
    persona_id INT PRIMARY KEY REFERENCES PERSONA(id)
);

CREATE TABLE INTERES_PROFESIONAL (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE PERSONA_INTERES_PROFESIONAL (
    persona_id INT REFERENCES PERSONA(id),
    interes_id INT REFERENCES INTERES_PROFESIONAL(id),
    PRIMARY KEY (persona_id, interes_id)
);

CREATE TABLE HABILIDADES_TECNICAS (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE PERSONA_HABILIDADES_TECNICAS (
    persona_id INT REFERENCES PERSONA(id),
    habilidad_id INT REFERENCES HABILIDADES_TECNICAS(id),
    PRIMARY KEY (persona_id, habilidad_id)
);

-- TABLAS PARA ENTIDAD RELACION

CREATE TABLE RELACION(
	id SERIAL PRIMARY KEY,
	estado VARCHAR(10) NOT NULL CHECK (estado IN ('pendiente', 'aceptada', 'rechazada')),
	persona1_id INT NOT NULL REFERENCES PERSONA(id),
	persona2_id INT NOT NULL REFERENCES PERSONA(id)
);

CREATE TABLE NOMBRE_RELACION ( -- por ser multivaluado
	id SERIAL PRIMARY KEY,
	nombre VARCHAR(20) NOT NULL
);

CREATE TABLE RELACION_NOMBRE_RELACION( -- unir la tabla relacion con la tabla del nombre
	relacion_id INT REFERENCES RELACION(id),
  	nombre_relacion_id INT REFERENCES NOMBRE_RELACION(id),
  	PRIMARY KEY (relacion_id, nombre_relacion_id)
);

--TABLAS PARA ENTIDAD GRUPO

CREATE TABLE GRUPO (
	nombre VARCHAR(30) PRIMARY KEY,
	descripcion TEXT,
	fecha_creacion DATE NOT NULL,
	estado VARCHAR(10) NOT NULL CHECK (estado IN ('publico', 'privado', 'secreto')),
	nombre_creador VARCHAR(30) NOT NULL,
	nombre_administrador VARCHAR(30) NOT NULL,

	-- para contar miembros de grupo
	cantidad_miembros INT DEFAULT 0
);

-- TABLAS PARA ENTIDAD EVENTO
 
CREATE TABLE EVENTO (
    id_evento SERIAL PRIMARY KEY,
    nombre_evento VARCHAR(100) NOT NULL,
    lugar_evento VARCHAR(100) NOT NULL,
    descripcion VARCHAR(200) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    estado VARCHAR(30) NOT NULL CHECK (estado IN ('publico','privado','secreto')),
    ciclo_vida VARCHAR(30) NOT NULL CHECK (ciclo_vida IN ('borrador','publicado','en curso','finalizado','archivado')),
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('presencial','virtual')),

    -- Cambio, para tener todos los organizadores que hay y no solo persona y grupo:
    organizador_tipo VARCHAR(20) NOT NULL CHECK (organizador_tipo IN ('Persona','Grupo','Dependencia','Organizacion')),
    organizador_nombre VARCHAR(100) NOT NULL
);

-- Atributo_Categoria
CREATE TABLE CATEGORIA (
	Id_categoria SERIAL PRIMARY KEY,
    Nombre_Categoria varchar(50) NOT NULL
); 

-- TABLAS PARA ENTIDAD SERVICIO_UCAB

CREATE TABLE SERVICIO_UCAB (
	Id_Servicio SERIAL PRIMARY KEY,
    Nombre_Servicio varchar (30) NOT NULL,
    Horario time NOT NULL,
    Celular varchar (11) NOT NULL
);

-- Atributo_Tipo_Servicio
CREATE TABLE TIPO_SERV (
	Id_tipo_serv SERIAL PRIMARY KEY,
    Nombre_tipo_serv varchar (30) NOT NULL
);

-- TABLAS PARA ENTIDAD ORGANIZACION_ASOCIADA

CREATE TABLE ORG_ASOCIADA (
	Id_Org_Asociada SERIAL PRIMARY KEY,
    Nombre_Org varchar(40) NOT NULL, 
    Sect_Act varchar (40) NOT NULL, 
    Num_Contact varchar (11) NOT NULL
);

-- Dependencia_UCAB
CREATE TABLE DEPENDENCIA_UCAB (
	id SERIAL PRIMARY KEY,
    nombre varchar(100) NOT NULL, 
	tipo VARCHAR(50) NOT NULL 
        CHECK (tipo IN ('Facultad', 'Escuela', 'Centro de investigacion', 'Agrupacion estudiantil', 'Coordinacion','Secretariado'))
);

-- TABLAS PARA ENTIDAD PUBLICACION
 
CREATE TABLE PUBLICACION (
	Id_Publicacion SERIAL PRIMARY KEY,
    Codigo_Pub varchar (50) NOT NULL,
	fecha DATE NOT NULL
);

-- Atributo Tipo_Publ
CREATE TABLE TIPO_PUBL (
	Id_tipo_publ SERIAL PRIMARY KEY, 
    Nombre_tipo_publ varchar (30) NOT NULL
);


DROP TABLE IF EXISTS crea CASCADE;
DROP TABLE IF EXISTS elabora CASCADE;
DROP TABLE IF EXISTS evento_categoria CASCADE;
DROP TABLE IF EXISTS servicio_tipo CASCADE;
DROP TABLE IF EXISTS publicacion_tipo CASCADE;

-- INTERRELACION PERSONA CREA PUBLICACION
CREATE TABLE CREA (
    persona_id INT NOT NULL REFERENCES PERSONA(id),
    publicacion_id INT NOT NULL REFERENCES PUBLICACION(Id_Publicacion),
    PRIMARY KEY (persona_id, publicacion_id)
);

-- INTERRELACION GRUPO ELABORA PUBLICACION
CREATE TABLE ELABORA (
    publicacion_id INT NOT NULL REFERENCES PUBLICACION(Id_Publicacion),
    grupo_nombre VARCHAR(30) NOT NULL REFERENCES GRUPO(nombre),
    PRIMARY KEY (publicacion_id, grupo_nombre)
);

-- INTERRELACIONES PARA EVENTO
CREATE TABLE EVENTO_CATEGORIA (
	Id_evento INT NOT NULL,
    Id_categoria INT NOT NULL, 
    PRIMARY KEY (Id_categoria, Id_evento),
    CONSTRAINT fk_ec_evento FOREIGN key (Id_evento) REFERENCES EVENTO(Id_evento)
        ON DELETE CASCADE, 
    CONSTRAINT fk_ec_categoria FOREIGN KEY (Id_categoria) REFERENCES CATEGORIA(Id_categoria)
        ON DELETE RESTRICT
); 

-- INTERRELACIONES PARA SERVICIO_UCAB
CREATE TABLE SERVICIO_TIPO (
	Id_Servicio INT NOT NULL,
    Id_tipo_serv INT NOT NULL,
    PRIMARY KEY (Id_Servicio, Id_tipo_serv),
    CONSTRAINT fk_ec_servicio FOREIGN KEY (Id_Servicio) REFERENCES SERVICIO_UCAB(Id_Servicio)
        ON DELETE CASCADE,
    CONSTRAINT fk_ec_tipo_serv FOREIGN KEY (Id_tipo_serv) REFERENCES TIPO_SERV(Id_tipo_serv)
        ON DELETE RESTRICT
);

-- INTERRELACIONES PARA PUBLICACION
CREATE TABLE PUBLICACION_TIPO (
	Id_Publicacion INT NOT NULL,
    Id_tipo_publ INT NOT NULL, 
    PRIMARY KEY (Id_Publicacion, Id_tipo_publ), 
    CONSTRAINT fk_ec_publicacion FOREIGN KEY (Id_Publicacion) REFERENCES PUBLICACION(Id_Publicacion)
        ON DELETE CASCADE, 
    CONSTRAINT fk_ec_tipo_publ FOREIGN KEY (Id_tipo_publ) REFERENCES TIPO_PUBL(Id_tipo_publ)
        ON DELETE RESTRICT
); 


-- ADICIONAL -----------------------------

-- Check de evento

ALTER TABLE EVENTO
ADD CONSTRAINT chk_fecha_hora_inicio_fin
CHECK (
    (Fecha_Inicio + Hora_Inicio) < (Fecha_Fin + Hora_fin)
);

-- -----------------------------------------------------

-- M:N: Participa (Persona en Grupo)
CREATE TABLE Participa_Grupo (
    id_persona INT,
    nombre_grupo VARCHAR(30) NOT NULL,
	es_invitacion BOOLEAN DEFAULT false,
    PRIMARY KEY (id_persona, nombre_grupo),
    FOREIGN KEY (id_persona) REFERENCES Persona (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (nombre_grupo) REFERENCES Grupo (nombre) ON DELETE CASCADE ON UPDATE CASCADE
);


-- M:N: pertenece (Persona a Dependencia UCAB)
CREATE TABLE Persona_pertenece_Dependencia (
    id_persona INT REFERENCES PERSONA(id) ON DELETE CASCADE ON UPDATE CASCADE,
    id_dependencia INT NOT NULL REFERENCES Dependencia_UCAB(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    PRIMARY KEY (id_persona, id_dependencia)
);

-- ---------------------------------------------

-- TABLA PARA LA VALORACIÓN DE PUBLICACIONES
CREATE TABLE VALORACION_PUBLICACION (
    id_publicacion INT REFERENCES PUBLICACION(Id_Publicacion) ON DELETE CASCADE,
    id_persona INT REFERENCES PERSONA(id) ON DELETE CASCADE,
    valoracion INT NOT NULL CHECK (valoracion BETWEEN 1 AND 5), -- Puntuación de 1 a 5
    fecha_valoracion TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (id_publicacion, id_persona) -- Una persona solo valora una vez cada publicación
);

-------------------------------------------------

-- Asiste (Persona a Evento)
CREATE TABLE ASISTE_EVENTO (
    id_persona INT REFERENCES PERSONA(id) ON DELETE CASCADE,
    id_evento INT UNIQUE REFERENCES EVENTO(Id_evento) ON DELETE CASCADE,
    PRIMARY KEY (id_persona, id_evento) -- Una persona solo se inscribe una vez a cada evento
);


DROP TABLE IF EXISTS crea CASCADE;
DROP TABLE IF EXISTS elabora CASCADE;
DROP TABLE IF EXISTS evento_categoria CASCADE;
DROP TABLE IF EXISTS servicio_tipo CASCADE;
DROP TABLE IF EXISTS publicacion_tipo CASCADE;

-- INTERRELACION PERSONA CREA PUBLICACION
CREATE TABLE CREA (
    persona_id INT NOT NULL REFERENCES PERSONA(id),
    publicacion_id INT NOT NULL REFERENCES PUBLICACION(Id_Publicacion),
    PRIMARY KEY (persona_id, publicacion_id)
);

-- INTERRELACION GRUPO ELABORA PUBLICACION
CREATE TABLE ELABORA (
    publicacion_id INT NOT NULL REFERENCES PUBLICACION(Id_Publicacion),
    grupo_nombre VARCHAR(30) NOT NULL REFERENCES GRUPO(nombre),
    PRIMARY KEY (publicacion_id, grupo_nombre)
);

-- INTERRELACIONES PARA EVENTO
CREATE TABLE EVENTO_CATEGORIA (
	Id_evento INT NOT NULL,
    Id_categoria INT NOT NULL, 
    PRIMARY KEY (Id_categoria, Id_evento),
    CONSTRAINT fk_ec_evento FOREIGN key (Id_evento) REFERENCES EVENTO(Id_evento)
        ON DELETE CASCADE, 
    CONSTRAINT fk_ec_categoria FOREIGN KEY (Id_categoria) REFERENCES CATEGORIA(Id_categoria)
        ON DELETE RESTRICT
); 

-- INTERRELACIONES PARA SERVICIO_UCAB
CREATE TABLE SERVICIO_TIPO (
	Id_Servicio INT NOT NULL,
    Id_tipo_serv INT NOT NULL,
    PRIMARY KEY (Id_Servicio, Id_tipo_serv),
    CONSTRAINT fk_ec_servicio FOREIGN KEY (Id_Servicio) REFERENCES SERVICIO_UCAB(Id_Servicio)
        ON DELETE CASCADE,
    CONSTRAINT fk_ec_tipo_serv FOREIGN KEY (Id_tipo_serv) REFERENCES TIPO_SERV(Id_tipo_serv)
        ON DELETE RESTRICT
);

-- INTERRELACIONES PARA PUBLICACION
CREATE TABLE PUBLICACION_TIPO (
	Id_Publicacion INT NOT NULL,
    Id_tipo_publ INT NOT NULL, 
    PRIMARY KEY (Id_Publicacion, Id_tipo_publ), 
    CONSTRAINT fk_ec_publicacion FOREIGN KEY (Id_Publicacion) REFERENCES PUBLICACION(Id_Publicacion)
        ON DELETE CASCADE, 
    CONSTRAINT fk_ec_tipo_publ FOREIGN KEY (Id_tipo_publ) REFERENCES TIPO_PUBL(Id_tipo_publ)
        ON DELETE RESTRICT
); 

-- SERVICIO------------------------------------

-- M:N: Administra (Persona a Servicio)
CREATE TABLE Administra_persona_servicio (
    id_persona INT NOT NULL UNIQUE, 
    id_servicio INT NOT NULL UNIQUE,
    PRIMARY KEY (id_persona, id_servicio),
    FOREIGN KEY (id_persona) REFERENCES Persona (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_servicio) REFERENCES Servicio_UCAB (Id_Servicio) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ------------------------------

-- columna extra para conteo de publicaciones en evento
ALTER TABLE EVENTO
ADD COLUMN cant_publicaciones INT NOT NULL DEFAULT 0;

-- TABLA NUEVA: INTERRELACIÓN (o 1:N) ENTRE EVENTO Y PUBLICACION
CREATE TABLE EVENTO_PUBLICACIONES (
    -- La FK a EVENTO es INT (usando 'id_evento' como nombre de columna)
    id_evento INT UNIQUE NOT NULL REFERENCES EVENTO(Id_evento) ON DELETE CASCADE ON UPDATE CASCADE, 
    -- La FK a PUBLICACION es VARCHAR(50)
    id_publicacion INT REFERENCES PUBLICACION(Id_Publicacion) ON DELETE CASCADE ON UPDATE CASCADE,
    
    PRIMARY KEY (id_evento, id_publicacion)
);


-- FUNCIONES DE PERSONA

-- obtener edad
CREATE OR REPLACE FUNCTION obtener_edad_persona(pid INT)
RETURNS INT AS $$
DECLARE
    nacimiento DATE;
BEGIN
    SELECT fecha_de_nacimiento::DATE INTO nacimiento
    FROM persona WHERE id = pid;

    IF nacimiento IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN DATE_PART('year', AGE(NOW(), nacimiento));
END;
$$ LANGUAGE plpgsql;

-- FUNCIONES DE RELACION

-- saber si una relacion esta activa
CREATE OR REPLACE FUNCTION relacion_activa(rid INT)
RETURNS BOOLEAN AS $$
DECLARE
    est VARCHAR;
BEGIN
    SELECT estado INTO est FROM relacion WHERE id = rid;

    RETURN est = 'aceptada';
END;
$$ LANGUAGE plpgsql;

-- FUNCIONES DE GRUPO

-- obtener el estado del grupo
CREATE OR REPLACE FUNCTION estado_grupo(pnombre VARCHAR)
RETURNS VARCHAR AS $$
DECLARE
    est VARCHAR;
BEGIN
    SELECT estado INTO est
    FROM grupo
    WHERE nombre = pnombre;

    RETURN est;  -- devuelve: 'publico', 'privado' o 'secreto'
END;
$$ LANGUAGE plpgsql;

-- FUNCIONES DE EVENTO

-- obtener el estado de un evento
CREATE OR REPLACE FUNCTION estado_evento(eid INT)
RETURNS VARCHAR AS $$
DECLARE
    f_inicio DATE;
    f_fin DATE;
BEGIN
    SELECT fecha_inicio, fecha_fin
    INTO f_inicio, f_fin
    FROM evento
    WHERE id = eid;

    IF f_inicio IS NULL OR f_fin IS NULL THEN
        RETURN 'evento no válido';
    END IF;

    IF NOW()::DATE < f_inicio THEN
        RETURN 'pendiente';
    ELSIF NOW()::DATE BETWEEN f_inicio AND f_fin THEN
        RETURN 'en curso';
    ELSE
        RETURN 'finalizado';
    END IF;
END;
$$ LANGUAGE plpgsql;


-- -- FUNCIONES ADICIONALES-------------------------------
CREATE OR REPLACE FUNCTION listar_servicios_y_organizadores ()
RETURNS TABLE (
    id_servicio INT,
    nombre_servicio VARCHAR(30),
    persona_administradora TEXT,
    dependencias_administradoras TEXT
) 
LANGUAGE SQL AS $$ 
SELECT 
    S.Id_Servicio,
    S.Nombre_Servicio,
    -- Concatena el nombre y apellido del administrador
    P.nombres || ' ' || P.apellidos AS persona_administradora,
    -- Concatena todas las dependencias a las que pertenece el administrador
    STRING_AGG(DU.nombre || ' (' || DU.tipo || ')', ', ' ORDER BY DU.nombre) AS dependencias_administradoras
FROM 
    SERVICIO_UCAB S
JOIN 
    -- 1. Enlazar el Servicio con la Persona que lo administra (relación 1:1 forzada por UNIQUE)
    Administra_persona_servicio APS ON S.Id_Servicio = APS.id_servicio
JOIN 
    -- 2. Obtener los nombres y apellidos del administrador
    PERSONA P ON APS.id_persona = P.id
LEFT JOIN 
    -- 3. Enlazar la Persona con sus Dependencias (M:N) 
    Persona_pertenece_Dependencia PPD ON P.id = PPD.id_persona
LEFT JOIN 
    -- 4. Obtener los nombres y tipos de las Dependencias [cite: 72]
    DEPENDENCIA_UCAB DU ON PPD.id_dependencia = DU.id
GROUP BY
    S.Id_Servicio, S.Nombre_Servicio, P.nombres, P.apellidos
ORDER BY 
    S.Nombre_Servicio;
$$;

-- Ejemplo de llamada:
-- SELECT * FROM listar_servicios_admin_dependencias();

-- ---------------------------------

-- invitacion para unirse a grupo secreto
CREATE OR REPLACE FUNCTION unirse_a_grupo_por_invitacion(
    p_persona_id INT,
    p_grupo_nombre VARCHAR
)
RETURNS VOID AS $$
BEGIN
    -- invitación (TRUE).
    -- Esto permite la inserción en grupos secret
    INSERT INTO Participa_Grupo (id_persona, nombre_grupo, es_invitacion)
    VALUES (p_persona_id, p_grupo_nombre, TRUE)
    ON CONFLICT (id_persona, nombre_grupo) DO NOTHING; -- Evita error si ya es miembro
    
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------

-- -----------------------------------------------------
-- FUNCIONES ADICIONALES-------------------------------

-- Funcion para contar total de puntaciones dadas por usuario
CREATE OR REPLACE FUNCTION contar_reacciones_publicacion(
    p_publicacion_id INT
)
RETURNS INT AS $$
DECLARE
    v_total_reacciones INT;
BEGIN
    -- Contar cuántos registros de valoración existen para la publicación dada
    SELECT COUNT(*) INTO v_total_reacciones
    FROM VALORACION_PUBLICACION
    WHERE id_publicacion = p_publicacion_id;

    RETURN v_total_reacciones;
END;
$$ LANGUAGE plpgsql;
-- ejemplo: SELECT contar_reacciones_publicacion(101);


-- Funcion para calcular tiempo restante para evento
CREATE OR REPLACE FUNCTION calcular_tiempo_restante_evento(
    p_evento_id INT
)
RETURNS TEXT AS $$
DECLARE
    v_tiempo_inicio TIMESTAMP;
    v_interval INTERVAL;
    v_dias INT;
    v_horas INT;
    v_minutos INT;
BEGIN
    -- 1. Obtener la hora de inicio combinada
    SELECT (Fecha_Inicio + Hora_Inicio) INTO v_tiempo_inicio
    FROM EVENTO
    WHERE Id_evento = p_evento_id;

    IF NOT FOUND THEN
        RETURN 'Evento no encontrado.';
    END IF;

    -- 2. Calcular el intervalo restante (si es positivo)
    v_interval := v_tiempo_inicio - NOW();

    -- Si el evento ya inició o finalizó
    IF v_interval < INTERVAL '0 seconds' THEN
        RETURN 'El evento ha comenzado o ya ha finalizado.';
    END IF;

    -- 3. Extraer y formatear componentes de tiempo
    v_dias := EXTRACT(DAY FROM v_interval);
    v_horas := EXTRACT(HOUR FROM v_interval);
    v_minutos := EXTRACT(MINUTE FROM v_interval);

    RETURN v_dias || ' días, ' || v_horas || ' horas, ' || v_minutos || ' minutos.';
END;
$$ LANGUAGE plpgsql;
-- SELECT calcular_tiempo_restante_evento(201);



-- verificar si una persona es administrador de un grupo
CREATE OR REPLACE FUNCTION es_administrador_grupo(
    p_persona_id INT,
    p_grupo_nombre VARCHAR(30)
)
RETURNS BOOLEAN AS $$
DECLARE
    v_administrador_nombre VARCHAR(30);
    v_persona_nombre VARCHAR(30);
BEGIN
    -- Obtener el nombre del administrador registrado en el grupo
    SELECT nombre_administrador INTO v_administrador_nombre
    FROM GRUPO
    WHERE nombre = p_grupo_nombre;

    IF NOT FOUND THEN
        RETURN FALSE; -- El grupo no existe
    END IF;

    -- Obtener el nombre de la persona (PERSONA.nombres) dado su ID (p_persona_id)
    SELECT nombres INTO v_persona_nombre
    FROM PERSONA
    WHERE id = p_persona_id;

    IF NOT FOUND THEN
        RETURN FALSE; -- La persona no existe
    END IF;

    -- 3. Comparar si el nombre del administrador del grupo coincide con el nombre de la persona
    RETURN v_administrador_nombre = v_persona_nombre;
END;
$$ LANGUAGE plpgsql;

-- Ejemplo de uso:
-- SELECT es_administrador_grupo(1, 'Club de Lectura');

-- PROCEDIMIENTOS DE PERSONA

-- registrar persona
CREATE OR REPLACE PROCEDURE registrar_persona(
    p_correo VARCHAR,
    p_nombres VARCHAR,
    p_apellidos VARCHAR,
    p_fecha DATE,
    p_sexo CHAR,
    p_ocupacion VARCHAR,
    p_celular VARCHAR,
    p_ubicacion INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO persona(
        correo, nombres, apellidos, fecha_de_nacimiento,
        sexo, ocupacion, celular, ubicacion_id
    )
    VALUES (
        p_correo, p_nombres, p_apellidos, p_fecha,
        p_sexo, p_ocupacion, p_celular, p_ubicacion
    );
END;
$$;

-- PROCEDIMIENTOS DE RELACION

-- crear relacion
CREATE OR REPLACE PROCEDURE crear_relacion(
    p_estado VARCHAR,
    p_persona1 INT,
    p_persona2 INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO relacion(estado, persona1_id, persona2_id)
    VALUES (p_estado, p_persona1, p_persona2);
END;
$$;

-- PROCEDIMIENTOS DE GRUPO

-- crear grupo
CREATE OR REPLACE PROCEDURE crear_grupo(
    p_nombre VARCHAR,
    p_descripcion TEXT,
    p_estado VARCHAR,
    p_creador VARCHAR,
    p_admin VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO grupo(
        nombre, descripcion, fecha_creacion,
        estado, nombre_creador, nombre_administrador
    )
    VALUES (
        p_nombre, p_descripcion, NOW(),
        p_estado, p_creador, p_admin
    );
END;
$$;

-- PROCEDIMIENTOS DE EVENTO

-- registrar evento
CREATE OR REPLACE PROCEDURE registrar_evento(
    p_id_evento        VARCHAR,
    p_nombre_evento    VARCHAR,
    p_lugar_evento     VARCHAR,
    p_descripcion      TEXT,
    p_fecha_inicio     DATE,
    p_fecha_fin        DATE,
    p_hora_inicio      TIME,
    p_hora_fin         TIME,
    p_estado           VARCHAR,
    p_ciclo_vida       VARCHAR,
    p_tipo             VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO evento(
        id_evento,
        nombre_evento,
        lugar_evento,
        descripcion,
        fecha_inicio,
        fecha_fin,
        hora_inicio,
        hora_fin,
        estado,
        ciclo_vida,
        tipo
    )
    VALUES (
        p_id_evento,
        p_nombre_evento,
        p_lugar_evento,
        p_descripcion,
        p_fecha_inicio,
        p_fecha_fin,
        p_hora_inicio,
        p_hora_fin,
        p_estado,
        p_ciclo_vida,
        p_tipo
    );
END;
$$;



-- ----------------------------------------------
-- PROCEDURIMIENTOS ADICIONALES

-- Registrar valoración de publicación
CREATE OR REPLACE PROCEDURE registrar_valoracion_publicacion(
    p_publicacion_id INT,
    p_persona_id INT,
    p_valoracion INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Insertar o actualizar la valoración. Si ya existe, actualiza la valoración
    INSERT INTO VALORACION_PUBLICACION (id_publicacion, id_persona, valoracion)
    VALUES (p_publicacion_id, p_persona_id, p_valoracion)
    ON CONFLICT (id_publicacion, id_persona) DO UPDATE
    SET valoracion = EXCLUDED.valoracion,
        fecha_valoracion = NOW();
    
    RAISE NOTICE 'Valoración % registrada/actualizada por persona % para publicación %.', p_valoracion, p_persona_id, p_publicacion_id;
END;
$$;
-- Ejemplo de llamada: CALL registrar_valoracion_publicacion(101, 201, 5);



-- Unirse a grupo
CREATE OR REPLACE PROCEDURE unirse_a_grupo(
    p_persona_id INT,
    p_grupo_nombre VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_grupo VARCHAR(10);
BEGIN
    -- Verificar el estado del grupo
    SELECT estado INTO v_estado_grupo
    FROM GRUPO
    WHERE nombre = p_grupo_nombre;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El grupo % no existe.', p_grupo_nombre;
    END IF;
    -- Validar regla de grupo secreto
    IF v_estado_grupo = 'secreto' THEN
        RAISE EXCEPTION 'No se puede unir directamente a un grupo secreto (%). Debe usar la función de invitación para estos grupos.', p_grupo_nombre;

    ELSE
        -- Para grupos 'publico' o 'privado', la unión es directa y es_invitacion es FALSE
        INSERT INTO Participa_Grupo (id_persona, nombre_grupo, es_invitacion)
        VALUES (p_persona_id, p_grupo_nombre, FALSE)
        ON CONFLICT (id_persona, nombre_grupo) DO NOTHING; -- No hace nada si ya es miembro

        RAISE NOTICE 'Persona % unida al grupo %.', p_persona_id, p_grupo_nombre;
    END IF;
END;
$$;
-- Ejemplo de llamada: CALL unirse_a_grupo(202, 'Club de Lectura');


-- Unirse a evento
CREATE OR REPLACE PROCEDURE unirse_a_evento(
    p_persona_id INT,
    p_evento_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ciclo_vida_evento VARCHAR(30);
    v_fecha_fin DATE;
BEGIN
    -- Verificar el estado y ciclo de vida del evento
    SELECT ciclo_Vida, Fecha_Fin INTO v_ciclo_vida_evento, v_fecha_fin
    FROM EVENTO
    WHERE Id_evento = p_evento_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El evento con ID % no existe.', p_evento_id;
    END IF;

    -- Validar que la inscripción sea posible
    IF v_ciclo_vida_evento IN ('finalizado', 'archivado') OR v_fecha_fin < CURRENT_DATE THEN
        RAISE EXCEPTION 'No se puede unir al evento. El evento ha finalizado o está archivado.';
    END IF;

    -- 3. Insertar la participación
    INSERT INTO PARTICIPA_EVENTO (id_persona, id_evento)
    VALUES (p_persona_id, p_evento_id)
    ON CONFLICT (id_persona, id_evento) DO NOTHING; -- Ignorar si ya está inscrito

    RAISE NOTICE 'Persona % inscrita al evento %.', p_persona_id, p_evento_id;
END;
$$;

-- Ejemplo de llamada: CALL unirse_a_evento(203, 301);


-- Automatizar el Administrador al creador del grupo // es casi el mismo flujo que el de arriba, el detalle sera que en este el credor se asignara por defecto como admin mientras que el primero no es obligatorio
CREATE OR REPLACE PROCEDURE crear_grupo(
    p_nombre VARCHAR,
    p_descripcion TEXT,
    p_estado VARCHAR,
    p_creador VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO grupo(nombre,descripcion,fecha_creacion,estado,nombre_creador,nombre_administrador)
    VALUES (p_nombre,p_descripcion,NOW(),p_estado,p_creador,p_creador);
END;
$$;

-- TRIGGERS DE PERSONA

-- validar que persona tenga un subtipo coherente
CREATE OR REPLACE FUNCTION validar_subtipo_persona()
RETURNS TRIGGER AS $$
BEGIN
    -- Si es estudiante, debe existir en ESTUDIANTE
    IF NEW.ocupacion = 'estudiante' THEN
        IF NOT EXISTS (SELECT 1 FROM estudiante WHERE persona_id = NEW.id) THEN
            RAISE EXCEPTION 'La persona % debe estar registrada en la tabla ESTUDIANTE', NEW.id;
        END IF;
    END IF;

    -- Si es profesor, debe existir en PROFESOR
    IF NEW.ocupacion = 'profesor' THEN
        IF NOT EXISTS (SELECT 1 FROM profesor WHERE persona_id = NEW.id) THEN
            RAISE EXCEPTION 'La persona % debe estar registrada en la tabla PROFESOR', NEW.id;
        END IF;
    END IF;

    -- Si es egresado, debe existir en EGRESADO
    IF NEW.ocupacion = 'egresado' THEN
        IF NOT EXISTS (SELECT 1 FROM egresado WHERE persona_id = NEW.id) THEN
            RAISE EXCEPTION 'La persona % debe estar registrada en la tabla EGRESADO', NEW.id;
        END IF;
    END IF;

    -- Si es administrativo
    IF NEW.ocupacion = 'administrativo' THEN
        IF NOT EXISTS (SELECT 1 FROM personal_administrativo WHERE persona_id = NEW.id) THEN
            RAISE EXCEPTION 'La persona % debe estar registrada en la tabla PERSONAL_ADMINISTRATIVO', NEW.id;
        END IF;
    END IF;

    -- Si es obrero
    IF NEW.ocupacion = 'obrero' THEN
        IF NOT EXISTS (SELECT 1 FROM personal_obrero WHERE persona_id = NEW.id) THEN
            RAISE EXCEPTION 'La persona % debe estar registrada en la tabla PERSONAL_OBRERO', NEW.id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_validar_subtipo_persona
AFTER INSERT OR UPDATE ON persona
FOR EACH ROW
EXECUTE FUNCTION validar_subtipo_persona();

-- TRIGGERS DE RELACION

-- asegurar que cada relacion tenga al menos un nombre asociado
-- TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION validar_nombre_relacion()
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar si la relación recién creada tiene al menos un nombre
    IF NOT EXISTS (
        SELECT 1
        FROM relacion_nombre_relacion
        WHERE relacion_id = NEW.id
    ) THEN
        RAISE EXCEPTION 'La relación % debe tener al menos un nombre asociado', NEW.id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER
CREATE TRIGGER tg_validar_nombre_relacion
AFTER INSERT ON relacion
FOR EACH ROW
EXECUTE FUNCTION validar_nombre_relacion();

-- TRIGGERS DE GRUPO

-- la fecha de creacion no puede ser superior a la fecha actual
-- TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION validar_fecha_grupo()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.fecha_creacion > NOW()::DATE THEN
        RAISE EXCEPTION 'La fecha de creación del grupo no puede ser futura';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



-- ------------------------------------------------------------------------

-- funcion para trigger grupo invitation secreto
CREATE OR REPLACE FUNCTION check_unirse_grupo_secreto()
RETURNS TRIGGER AS $$
DECLARE
    group_status VARCHAR(10);
BEGIN
    SELECT estado INTO group_status
    FROM GRUPO
    WHERE nombre = NEW.nombre_grupo;

    -- Si el grupo es 'secreto' y la inserción NO fue por invitación (asumiendo columna es_invitacion)
    IF group_status = 'secreto' AND NEW.es_invitacion IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'No se permite unirse directamente a un grupo secreto. Se requiere una invitación.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--trigger invitacion para grupo secret------------
CREATE TRIGGER invitacion_para_grupo_secreto
BEFORE INSERT ON Participa_Grupo
FOR EACH ROW
EXECUTE FUNCTION check_unirse_grupo_secreto();

-- --------------------------------------------------------


-- Funcion miembros grupo minimo 2
CREATE OR REPLACE FUNCTION miembros_minimo()
RETURNS TRIGGER AS $$
DECLARE
    member_count INT;
BEGIN
    -- Contar los miembros del grupo del que se intentó eliminar a la persona
    SELECT COUNT(*) INTO member_count
    FROM Participa_Grupo
    WHERE nombre_grupo = OLD.nombre_grupo[cite: 82];

    -- La regla es que debe tener AL MENOS dos personas participantes.
    IF member_count < 2 THEN
        RAISE EXCEPTION 'El grupo "%" debe tener al menos dos miembros. La eliminación fue revertida.', OLD.nombre_grupo[cite: 82];
    END IF;

    RETURN OLD; -- Retorna OLD para la operación de DELETE
END;
$$ LANGUAGE plpgsql;

-- trigger miembros grupo minimo 2
CREATE TRIGGER check_min_members_on_delete
AFTER DELETE ON Participa_Grupo
FOR EACH ROW
EXECUTE FUNCTION miembros_minimo();

-- -------------------------------

-- Funcion eliminar evento vencido
CREATE OR REPLACE FUNCTION eliminar_evento()
RETURNS TRIGGER AS $$
BEGIN
    IF  NEW.Fecha_Fin <= CURRENT_DATE THEN
        DELETE FROM EVENTO WHERE Id_evento = NEW.Id_evento;
        RETURN NULL; 
    END IF;
    -- Si no cumple la condición de eliminación, permite la actualización normal
    RETURN NEW; 
END;
$$ LANGUAGE plpgsql;

--trigger eliminar evento vencido
CREATE TRIGGER check_eliminar_eventos_vencidos
BEFORE UPDATE ON EVENTO
FOR EACH ROW
EXECUTE FUNCTION eliminar_evento();

-- ----------------------------------------------------------


-- funcion para actualizar cantidad miembros grupo
CREATE OR REPLACE FUNCTION actualizar_grupo_MiembrosCantidad()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE GRUPO
        SET cantidad_miembros = cantidad_miembros + 1
        WHERE nombre = NEW.nombre_grupo[cite: 82];
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE GRUPO
        SET cantidad_miembros = cantidad_miembros - 1
        WHERE nombre = OLD.nombre_grupo[cite: 82];
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- trigger actualizar cantidad miembros grupo---

-- Trigger para cuando un miembro se une
CREATE TRIGGER incrementar_miembro_grupo
AFTER INSERT ON Participa_Grupo
FOR EACH ROW
EXECUTE FUNCTION actualizar_grupo_MiembrosCantidad();

-- Trigger para cuando un miembro abandona
CREATE TRIGGER decrementar_miembro_grupo
AFTER DELETE ON Participa_Grupo
FOR EACH ROW
EXECUTE FUNCTION actualizar_grupo_MiembrosCantidad();

-----------------------------------
--


-- TRIGGER
CREATE TRIGGER tg_validar_fecha_grupo
BEFORE INSERT ON grupo
FOR EACH ROW
EXECUTE FUNCTION validar_fecha_grupo();

-- TRIGGERS DE EVENTO

-- validar el organizador de un Evento
CREATE OR REPLACE FUNCTION validar_organizador_evento()
RETURNS trigger AS $$
BEGIN
    CASE NEW.organizador_tipo
        WHEN 'Persona' THEN
            IF NOT EXISTS (SELECT 1 FROM persona WHERE nombres = NEW.organizador_nombre) THEN
                RAISE EXCEPTION 'El organizador Persona no existe.';
            END IF;
        WHEN 'Grupo' THEN
            IF NOT EXISTS (SELECT 1 FROM grupo WHERE nombre = NEW.organizador_nombre) THEN
                RAISE EXCEPTION 'El organizador Grupo no existe.';
            END IF;
        WHEN 'Dependencia' THEN
            IF NOT EXISTS (SELECT 1 FROM dependencia_ucab WHERE nombre = NEW.organizador_nombre) THEN
                RAISE EXCEPTION 'La dependencia no existe.';
            END IF;
        WHEN 'Organizacion' THEN
            IF NOT EXISTS (SELECT 1 FROM organizacion_asociada WHERE Nombre_Org = NEW.organizador_nombre) THEN
                RAISE EXCEPTION 'La organización asociada no existe.';
            END IF;
        ELSE
            RAISE EXCEPTION 'Tipo de organizador inválido.';
    END CASE;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_organizador_evento
BEFORE INSERT OR UPDATE ON evento
FOR EACH ROW
EXECUTE FUNCTION validar_organizador_evento();

-- ------------------------------------------------------

CREATE OR REPLACE FUNCTION actualizar_conteo_publicaciones()
RETURNS TRIGGER 
AS $$
BEGIN 
    -- INSERCIÓN: Se aumenta el conteo en el Evento del nuevo registro (NEW)
    IF TG_OP = 'INSERT' THEN 
        UPDATE EVENTO 
        SET cant_publicaciones = cant_publicaciones + 1
        WHERE id = NEW.id_evento; 
        RETURN NEW; 
    
    -- ELIMINACIÓN: Se disminuye el conteo en el Evento del registro eliminado (OLD)
    ELSEIF TG_OP = 'DELETE' THEN 
        UPDATE EVENTO 
        SET cant_publicaciones = cant_publicaciones - 1
        WHERE id = OLD.id_evento; 
        RETURN OLD; 
        
    -- ACTUALIZACIÓN: Maneja el cambio de evento asociado
    ELSEIF TG_OP = 'UPDATE' THEN 
        -- 1. Descuenta del Evento antiguo (OLD)
        UPDATE EVENTO 
        SET cant_publicaciones = cant_publicaciones - 1
        WHERE id = OLD.id_evento; 
        
        -- 2. Suma al Evento nuevo (NEW)
        UPDATE EVENTO 
        SET cant_publicaciones = cant_publicaciones + 1
        WHERE id = NEW.id_evento; 
        RETURN NEW; 
        
    END IF; 
END;
$$ LANGUAGE plpgsql;

-- El TRIGGER se mantiene igual y funcionará con la función corregida
CREATE TRIGGER trg_actualizar_conteo_publicaciones
AFTER INSERT OR DELETE OR UPDATE OF id_evento ON EVENTO_PUBLICACIONES
FOR EACH ROW
EXECUTE FUNCTION actualizar_conteo_publicaciones();

-- Trigger para actualizar conteo publicaciones

-- TRIGGERS DE RELACION

-- asegurar que cada relacion tenga al menos un nombre asociado
-- TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION validar_nombre_relacion()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM relacion_nombre_relacion
        WHERE relacion_id = NEW.id
    ) THEN
        RAISE EXCEPTION 'Error: La relación (ID %) debe tener al menos un nombre asociado antes de finalizar la transacción.', NEW.id;
    END IF;

    RETURN NULL; 
END;
$$ LANGUAGE plpgsql;

-- TRIGGER
DROP TRIGGER IF EXISTS tg_validar_nombre_relacion ON relacion;

CREATE CONSTRAINT TRIGGER tg_validar_nombre_relacion
AFTER INSERT ON relacion
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION validar_nombre_relacion();


------------------------------------------------------------

DELETE FROM relacion_nombre_relacion;
DELETE FROM relacion;
DELETE FROM nombre_relacion;
DELETE FROM tutoria;
DELETE FROM estudiante;
DELETE FROM profesor;
DELETE FROM egresado;
DELETE FROM personal_administrativo;
DELETE FROM personal_obrero;
DELETE FROM categoria;
DELETE FROM tipo_serv;
DELETE FROM tipo_publ;
DELETE FROM crea;
DELETE FROM elabora;
DELETE FROM grupo;
DELETE FROM org_asociada;
DELETE FROM servicio_ucab;
DELETE FROM evento;
DELETE FROM publicacion;
DELETE FROM persona_idioma;
DELETE FROM persona_interes_profesional;
DELETE FROM persona_habilidades_tecnicas;
DELETE FROM persona;
DELETE FROM habilidades_tecnicas;
DELETE FROM interes_profesional;
DELETE FROM idioma;
DELETE FROM ubicacion_geografica;
DELETE FROM dependencia_ucab;

--obtener los nombres de todas las secuencias reales usadas por cada tabla
SELECT pg_get_serial_sequence('persona','id');
SELECT pg_get_serial_sequence('relacion','id');
SELECT pg_get_serial_sequence('nombre_relacion','id');
SELECT pg_get_serial_sequence('ubicacion_geografica','id');
SELECT pg_get_serial_sequence('idioma','id');
SELECT pg_get_serial_sequence('interes_profesional','id');
SELECT pg_get_serial_sequence('habilidades_tecnicas','id');
SELECT pg_get_serial_sequence('dependencia_ucab', 'id');

--reiniciar las secuencias, para que el id sea 1
ALTER SEQUENCE persona_id_seq RESTART WITH 1;
ALTER SEQUENCE relacion_id_seq RESTART WITH 1;
ALTER SEQUENCE nombre_relacion_id_seq RESTART WITH 1;
ALTER SEQUENCE ubicacion_geografica_id_seq RESTART WITH 1;
ALTER SEQUENCE idioma_id_seq RESTART WITH 1;
ALTER SEQUENCE interes_profesional_id_seq RESTART WITH 1;
ALTER SEQUENCE habilidades_tecnicas_id_seq RESTART WITH 1;
ALTER SEQUENCE dependencia_ucab_id_seq RESTART WITH 1;

-- ENTIDADES Y ATRIBUTOS ADICIONALES

INSERT INTO UBICACION_GEOGRAFICA (ciudad, pais) VALUES
('Caracas', 'Venezuela'),
('Buenos Aires', 'Argentina'),
('Madrid', 'España'),
('Roma', 'Italia'),
('Miami', 'Estados Unidos');

INSERT INTO IDIOMA (nombre) VALUES
('Español'), ('Inglés'), ('Francés');

INSERT INTO INTERES_PROFESIONAL (nombre) VALUES
('Programación'), ('Robótica'), ('Marketing');

INSERT INTO HABILIDADES_TECNICAS (nombre) VALUES
('Java'), ('Python'), ('SQL');

INSERT INTO PERSONA (correo, nombres, apellidos, fecha_de_nacimiento, sexo, ocupacion, celular, ubicacion_id) VALUES
('ana@gmail.com', 'Ana', 'Pérez', '2000-04-10', 'F', 'Estudiante', '+584121234567', 1),
('juan@gmail.com', 'Juan', 'Gómez', '1999-02-15', 'M', 'Estudiante', '+584124567890', 1),
('maria@gmail.com', 'María', 'Sánchez', '1980-06-05', 'F', 'Profesor', '+584146661122', 2),
('carlos@gmail.com', 'Carlos', 'Torres', '1985-03-21', 'M', 'Egresado', '+584123334455', 3),
('laura@gmail.com', 'Laura', 'Martínez', '1990-11-12', 'F', 'Administrativo', '+584127778899', 4),
('pedro@gmail.com', 'Pedro', 'Rojas', '1998-09-09', 'M', 'Obrero', '+584126661100', 5);

INSERT INTO ESTUDIANTE VALUES (1, 'pregrado'), (2, 'pregrado');
INSERT INTO PROFESOR VALUES (3, 'activo');
INSERT INTO EGRESADO VALUES (4);
INSERT INTO PERSONAL_ADMINISTRATIVO VALUES (5);
INSERT INTO PERSONAL_OBRERO VALUES (6);

INSERT INTO PERSONA_IDIOMA VALUES
(1,1), (1,2), --id de persona , id de idioma
(2,1),
(3,1), (3,2);

INSERT INTO PERSONA_INTERES_PROFESIONAL VALUES
(1,1), (1,2), --id de persona , id de interes
(2,1),
(3,3);

INSERT INTO PERSONA_HABILIDADES_TECNICAS VALUES
(1,2), (1,3), --id de persona , id de habilidad
(3,1), (3,3);

INSERT INTO TUTORIA VALUES
(3,1), --id de profesor , id de estudiante
(3,2);

INSERT INTO CATEGORIA (id_categoria, nombre_categoria) VALUES 
(1, 'Académico'),
(2, 'Deportivo'),
(3, 'Cultural'),
(4, 'Social');

INSERT INTO TIPO_SERV (Id_tipo_serv, Nombre_tipo_serv) VALUES
(1, 'Alimentación'),
(2, 'Papelería');

INSERT INTO TIPO_PUBL (Id_tipo_publ, Nombre_tipo_publ) VALUES
(1, 'Texto'),
(2, 'Imagen');

INSERT INTO GRUPO (nombre, descripcion, fecha_creacion, estado, nombre_creador, nombre_administrador) VALUES
('ProgramacionUCAB','Grupo de programadores','2024-01-10','publico','Ana','Ana'),
('RoboticaUCAB','Robótica y electrónica','2024-02-15','privado','Juan','Juan');

INSERT INTO SERVICIO_UCAB VALUES
(1,'Cafetín Central','08:00','04125556666'),
(2,'Papelería UCAB','08:00','04124443333');

INSERT INTO EVENTO VALUES
(1,'Feria de Proyectos','Caracas','Evento anual de innovación','2026-07-10','2026-07-12','09:00','15:00','publico','publicado','presencial', 'Persona', 'María');

INSERT INTO PUBLICACION (Id_Publicacion, Codigo_Pub, fecha) VALUES
(1, 'COD001', CURRENT_DATE),
(2, 'COD002', CURRENT_DATE),
(3, 'COD003', CURRENT_DATE),
(4, 'COD004', CURRENT_DATE);

INSERT INTO RELACION (estado, persona1_id, persona2_id) VALUES
('aceptada', 1, 2);

INSERT INTO NOMBRE_RELACION (nombre) VALUES
('amigos'), ('colegas');

INSERT INTO RELACION_NOMBRE_RELACION VALUES
(1,1), (1,2); --id de la relacion entre dos personas , id del nombre de la relacion entre ellas (ya que es multivaluado, puede que tengan mas de una)

-- INTERRELACIONES

--persona crea publicacion
INSERT INTO CREA (persona_id, publicacion_id) VALUES
(1, 1),
(1, 2),
(2, 3);

--grupo crea publicacion
INSERT INTO ELABORA (publicacion_id, grupo_nombre) VALUES
(1, 'ProgramacionUCAB'),
(2, 'ProgramacionUCAB'),
(3, 'ProgramacionUCAB'),
(4, 'RoboticaUCAB');

INSERT INTO DEPENDENCIA_UCAB (nombre, tipo) VALUES
('Facultad de Ingeniería', 'Facultad'),
('Facultad de Ciencias Económicas y Sociales', 'Facultad'),
('Escuela de Ingeniería Informática', 'Escuela'),
('Escuela de Administración y Contaduría', 'Escuela'),
('Centro de Investigación y Desarrollo', 'Centro de investigacion'),
('Agrupación Estudiantil Pastoral Universitaria', 'Agrupacion estudiantil'),
('Coordinación de Extensión Social', 'Coordinacion'),
('Coordinación de Deportes', 'Coordinacion'),
('Secretariado de Comunicación', 'Secretariado'),
('Secretariado de Asuntos Estudiantiles', 'Secretariado');

-------------------------------------------------

INSERT INTO PUBLICACION_TIPO (id_publicacion, id_tipo_publ) VALUES (1, 1);
INSERT INTO PUBLICACION_TIPO (id_publicacion, id_tipo_publ) VALUES (1, 2);
INSERT INTO PUBLICACION_TIPO (id_publicacion, id_tipo_publ) VALUES (2, 1);
INSERT INTO PUBLICACION_TIPO (id_publicacion, id_tipo_publ) VALUES (2, 2);

SELECT setval(pg_get_serial_sequence('publicacion', 'id_publicacion'), (SELECT MAX(id_publicacion) FROM publicacion));

ALTER TABLE publicacion
ADD COLUMN descripcion TEXT;