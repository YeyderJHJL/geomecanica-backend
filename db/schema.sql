-- ============================================================
--  SCHEMA COMPLETO — Base de datos Ventanas
--  Basado en el esquema real del proyecto
--  SQL Server 2016 o superior (requiere OPENJSON / JSON_VALUE)
--
--  CÓMO EJECUTAR:
--  1. Abre SQL Server Management Studio (SSMS)
--  2. Conecta a tu instancia (ej: localhost\SQLEXPRESS)
--  3. File → Open → File... → selecciona este archivo
--  4. Presiona F5 — crea BD, tablas, vistas y stored procedures
-- ============================================================

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'Ventanas')
    CREATE DATABASE Ventanas;
GO
USE Ventanas;
GO

-- ── 1. TABLAS DE DIMENSIÓN (lookup Bieniawski) ───────────────

IF OBJECT_ID('dim_agua',              'U') IS NULL CREATE TABLE dim_agua              (codigo char(1) NOT NULL PRIMARY KEY, descripcion nvarchar(30) NOT NULL, rating_76 tinyint NOT NULL, rating_89 tinyint NOT NULL);
IF OBJECT_ID('dim_resistencia',       'U') IS NULL CREATE TABLE dim_resistencia       (codigo_r varchar(2) NOT NULL PRIMARY KEY, mpa_descripcion varchar(20) NOT NULL, rating_89 tinyint NOT NULL, rating_76 tinyint NOT NULL);
IF OBJECT_ID('dim_rqd',               'U') IS NULL CREATE TABLE dim_rqd               (rqd_min_pct decimal(5,2) NOT NULL PRIMARY KEY, descripcion varchar(20) NOT NULL, rating_89 tinyint NOT NULL, rating_76 tinyint NOT NULL);
IF OBJECT_ID('dim_espaciamiento_89',  'U') IS NULL CREATE TABLE dim_espaciamiento_89  (espaciamiento_min_m decimal(6,4) NOT NULL PRIMARY KEY, descripcion varchar(20) NOT NULL, rating_89 tinyint NOT NULL);
IF OBJECT_ID('dim_espaciamiento_76',  'U') IS NULL CREATE TABLE dim_espaciamiento_76  (espaciamiento_min_m decimal(6,4) NOT NULL PRIMARY KEY, descripcion varchar(20) NOT NULL, rating_76 tinyint NOT NULL);
IF OBJECT_ID('dim_abertura',          'U') IS NULL CREATE TABLE dim_abertura          (abertura_min_mm decimal(10,7) NOT NULL PRIMARY KEY, nombre nvarchar(40) NOT NULL, descripcion_mm varchar(20) NOT NULL, rating_89 tinyint NOT NULL, rating_76 tinyint NOT NULL);
IF OBJECT_ID('dim_continuidad',       'U') IS NULL CREATE TABLE dim_continuidad       (continuidad_min_m decimal(5,1) NOT NULL PRIMARY KEY, descripcion varchar(20) NOT NULL, rating_89 tinyint NOT NULL, rating_76 tinyint NOT NULL);
IF OBJECT_ID('dim_meteorizacion',     'U') IS NULL CREATE TABLE dim_meteorizacion     (codigo char(1) NOT NULL PRIMARY KEY, rating_89 tinyint NOT NULL, rating_76 tinyint NOT NULL);
IF OBJECT_ID('dim_rugosidad',         'U') IS NULL CREATE TABLE dim_rugosidad         (codigo_isrm tinyint NOT NULL PRIMARY KEY, rating_89 tinyint NOT NULL, rating_76 tinyint NOT NULL);
IF OBJECT_ID('dim_relleno_tipo',      'U') IS NULL CREATE TABLE dim_relleno_tipo      (codigo varchar(4) NOT NULL PRIMARY KEY, categoria_relleno tinyint NOT NULL, descripcion nvarchar(40) NOT NULL);
IF OBJECT_ID('dim_relleno_espesor',   'U') IS NULL CREATE TABLE dim_relleno_espesor   (espesor_min_mm decimal(5,2) NOT NULL PRIMARY KEY, descripcion varchar(10) NOT NULL, categoria_espesor tinyint NOT NULL);
IF OBJECT_ID('dim_relleno_valor',     'U') IS NULL CREATE TABLE dim_relleno_valor     (categoria_relleno tinyint NOT NULL, categoria_espesor tinyint NOT NULL, descripcion nvarchar(40) NOT NULL, rating_89 tinyint NOT NULL, rating_76 tinyint NOT NULL, PRIMARY KEY (categoria_relleno, categoria_espesor));
IF OBJECT_ID('dim_extremos_visibles', 'U') IS NULL CREATE TABLE dim_extremos_visibles (codigo tinyint NOT NULL PRIMARY KEY, descripcion nvarchar(60) NOT NULL, nota nvarchar(120) NULL);
IF OBJECT_ID('dim_isrm',              'U') IS NULL CREATE TABLE dim_isrm              (ucs_min_mpa decimal(6,1) NOT NULL PRIMARY KEY, abreviatura varchar(2) NOT NULL, denominacion nvarchar(40) NOT NULL);
IF OBJECT_ID('dim_litologia',         'U') IS NULL CREATE TABLE dim_litologia         (litologia_id int IDENTITY(1,1) PRIMARY KEY, categoria varchar(20) NOT NULL, lito_1 varchar(20) NOT NULL, lito_2 varchar(20) NOT NULL, lito_3 varchar(20) NOT NULL, factor_k decimal(4,2) NOT NULL DEFAULT 1.0, nota nvarchar(120) NULL);
GO

-- ── 1b. POBLAR DIMENSIONES ───────────────────────────────────

-- dim_agua
IF NOT EXISTS (SELECT 1 FROM dim_agua WHERE codigo = 'C')
INSERT INTO dim_agua VALUES
    ('C', 'Completamente seco', 10, 15),
    ('H', 'Húmedo',             10, 10),
    ('M', 'Mojado',              7,  7),
    ('E', 'Goteando',            4,  4),
    ('F', 'Fluyendo',            0,  0);
GO

-- dim_resistencia
IF NOT EXISTS (SELECT 1 FROM dim_resistencia WHERE codigo_r = 'R6')
INSERT INTO dim_resistencia VALUES
    ('R6', '>250 MPa',    15, 15),
    ('R5', '100-250 MPa', 12, 12),
    ('R4', '50-100 MPa',   7,  7),
    ('R3', '25-50 MPa',    4,  4),
    ('R2', '5-25 MPa',     2,  2),
    ('R1', '1-5 MPa',      1,  1),
    ('R0', '<1 MPa',       0,  0);
GO

-- dim_rqd
IF NOT EXISTS (SELECT 1 FROM dim_rqd WHERE rqd_min_pct = 0)
INSERT INTO dim_rqd VALUES
    ( 0, '<25%',    3,  3),
    (25, '25-50%',  8,  8),
    (50, '50-75%', 13, 13),
    (75, '75-90%', 17, 17),
    (90, '90-100%',20, 20);
GO

-- dim_espaciamiento_89
IF NOT EXISTS (SELECT 1 FROM dim_espaciamiento_89 WHERE espaciamiento_min_m = 0)
INSERT INTO dim_espaciamiento_89 VALUES
    (0.0000, '<0.06 m',   5),
    (0.0600, '0.06-0.2 m',8),
    (0.2000, '0.2-0.6 m', 10),
    (0.6000, '0.6-2 m',   15),
    (2.0000, '>2 m',      20);
GO

-- dim_espaciamiento_76
IF NOT EXISTS (SELECT 1 FROM dim_espaciamiento_76 WHERE espaciamiento_min_m = 0)
INSERT INTO dim_espaciamiento_76 VALUES
    (0.0000, '<0.05 m',   5),
    (0.0500, '0.05-0.3 m',10),
    (0.3000, '0.3-1 m',   20),
    (1.0000, '1-3 m',     25),
    (3.0000, '>3 m',      30);
GO

-- dim_abertura
IF NOT EXISTS (SELECT 1 FROM dim_abertura WHERE abertura_min_mm = 0)
INSERT INTO dim_abertura VALUES
    (0.0000000, 'Masiva',        '0 mm',    6, 5),
    (0.0000001, 'Entre abierta', '<0.1 mm', 5, 4),
    (0.1000000, 'Abierta',       '0.1-1 mm',3, 3),
    (1.0000000, 'Muy abierta',   '1-5 mm',  1, 1),
    (5.0000000, 'Ext. abierta',  '>5 mm',   0, 0);
GO

-- dim_continuidad
IF NOT EXISTS (SELECT 1 FROM dim_continuidad WHERE continuidad_min_m = 0)
INSERT INTO dim_continuidad VALUES
    ( 0, '<1 m',   6, 5),
    ( 1, '1-3 m',  4, 4),
    ( 3, '3-10 m', 2, 3),
    (10, '10-20 m',1, 1),
    (20, '>20 m',  0, 0);
GO

-- dim_meteorizacion
IF NOT EXISTS (SELECT 1 FROM dim_meteorizacion WHERE codigo = 'f')
INSERT INTO dim_meteorizacion VALUES
    ('f', 6, 5), ('d', 5, 5), ('m', 3, 4),
    ('a', 3, 3), ('c', 2, 2), ('s', 1, 1);
GO

-- dim_rugosidad
IF NOT EXISTS (SELECT 1 FROM dim_rugosidad WHERE codigo_isrm = 1)
INSERT INTO dim_rugosidad VALUES
    (1,6,5),(2,5,4),(3,5,4),(4,3,2),(5,3,2),
    (6,1,0),(7,1,0),(8,0,0),(9,0,0);
GO

-- dim_relleno_tipo
IF NOT EXISTS (SELECT 1 FROM dim_relleno_tipo WHERE codigo = 'cwf')
INSERT INTO dim_relleno_tipo VALUES
    ('cwf',3,'Sin relleno / pared en contacto'),
    ('si', 1,'Relleno duro — inorgánico'),
    ('sf', 1,'Relleno duro — suave'),
    ('ep', 1,'Relleno duro — epidota'),
    ('ox', 1,'Relleno duro — óxidos'),
    ('g',  2,'Relleno blando — yeso'),
    ('cl', 2,'Relleno blando — arcilla'),
    ('ca', 2,'Relleno blando — calcita');
GO

-- dim_relleno_espesor
IF NOT EXISTS (SELECT 1 FROM dim_relleno_espesor WHERE espesor_min_mm = 0)
INSERT INTO dim_relleno_espesor VALUES
    (0.00, '<5 mm', 1),
    (5.00, '≥5 mm', 2);
GO

-- dim_relleno_valor (categoria_relleno x categoria_espesor)
IF NOT EXISTS (SELECT 1 FROM dim_relleno_valor WHERE categoria_relleno = 3 AND categoria_espesor = 1)
INSERT INTO dim_relleno_valor VALUES
    -- tipo 3 = sin relleno (cwf) — espesor irrelevante
    (3, 1, 'Sin relleno, espac <5',  6, 5),
    (3, 2, 'Sin relleno, espac ≥5',  6, 5),
    -- tipo 1 = duro
    (1, 1, 'Duro, espesor <5 mm',    4, 4),
    (1, 2, 'Duro, espesor ≥5 mm',    2, 3),
    -- tipo 2 = blando
    (2, 1, 'Blando, espesor <5 mm',  2, 2),
    (2, 2, 'Blando, espesor ≥5 mm',  0, 0);
GO

-- dim_extremos_visibles
IF NOT EXISTS (SELECT 1 FROM dim_extremos_visibles WHERE codigo = 0)
INSERT INTO dim_extremos_visibles VALUES
    (0,'No se ven',                        NULL),
    (1,'Solo vemos uno',                   NULL),
    (2,'Dos extremos visibles',            NULL),
    (3,'Terminación entre estructuras',    NULL);
GO

-- dim_isrm
IF NOT EXISTS (SELECT 1 FROM dim_isrm WHERE ucs_min_mpa = 0)
INSERT INTO dim_isrm VALUES
    (  0,   'R0', 'Suelo / muy blanda'),
    (  1.0, 'R1', 'Muy baja resistencia'),
    (  5.0, 'R2', 'Baja resistencia'),
    ( 25.0, 'R3', 'Resistencia media'),
    ( 50.0, 'R4', 'Alta resistencia'),
    (100.0, 'R5', 'Muy alta resistencia'),
    (250.0, 'R6', 'Resistencia extrema');
GO

-- dim_litologia (grupos litológicos del proyecto)
IF NOT EXISTS (SELECT 1 FROM dim_litologia WHERE lito_1 = 'MZB' AND lito_3 = 'MZB_EQ')
INSERT INTO dim_litologia (categoria, lito_1, lito_2, lito_3) VALUES
    ('INTRUSIVOS','MZB','MZB','MZB_EQ'), ('INTRUSIVOS','MZB','MZB','MZB_P'),
    ('INTRUSIVOS','MBF1','MBF','MBF1'),  ('INTRUSIVOS','MBF2','MBF','MBF2'),
    ('INTRUSIVOS','MBF2','MBF','MBF_P'), ('INTRUSIVOS','MZM','MZM','MZM_F'),
    ('INTRUSIVOS','MZM','MZM','MZM_M'),  ('INTRUSIVOS','MZH','MZH','MZH_1'),
    ('INTRUSIVOS','MZH','MZH','MZH_2'),  ('INTRUSIVOS','MZD','MZD','MZD'),
    ('INTRUSIVOS','MZQ','MZQ','MZQ'),    ('INTRUSIVOS','AN','LAM','LAM'),
    ('SEDIMENTARIOS','LMT','LMT','LMT_M'),('SEDIMENTARIOS','LMT','LMT','LMT_Mg'),
    ('SEDIMENTARIOS','LMT','LMT','LMT_S'),('SEDIMENTARIOS','LMT','LMT','LMT_C'),
    ('SEDIMENTARIOS','LMT','LMT','LMT_U'),('SEDIMENTARIOS','SHL','HFL','SHL_MA'),
    ('METAMORFICAS','LMT','GSK','Varios'),('METAMORFICAS','LMT','PSK','Varios'),
    ('METAMORFICAS','LMT','MSK','Varios'),('METAMORFICAS','LMT','ESK','Varios'),
    ('METAMORFICAS','LMT','MBC','Varios'),('METAMORFICAS','LMT','MBL','Varios'),
    ('METAMORFICAS','SHL','HFL','-'),     ('METAMORFICAS','SND','QZT','-'),
    ('BRECHAS','TBX','TBX','TBX'),       ('BRECHAS','HBX','HBX','HBX'),
    ('BRECHAS','MBX / varios','MBX','MBX'),
    ('ENDOSKARN','Intrusivo','EPG','-'),  ('ENDOSKARN','Intrusivo','EGT','-');
GO


-- ── 2. TABLAS PRINCIPALES ────────────────────────────────────

IF OBJECT_ID('ventana', 'U') IS NULL
CREATE TABLE ventana (
    ventana_id            int           IDENTITY(1,1) PRIMARY KEY,
    codigo                varchar(10)   NOT NULL,
    fecha_mapeo           date          NULL,
    mapeador              varchar(20)   NULL,
    campania              smallint      NULL,
    este_ini              decimal(12,2) NOT NULL DEFAULT 0,
    norte_ini             decimal(12,2) NOT NULL DEFAULT 0,
    cota_ini              decimal(10,2) NOT NULL DEFAULT 0,
    este_fin              decimal(12,2) NOT NULL DEFAULT 0,
    norte_fin             decimal(12,2) NOT NULL DEFAULT 0,
    cota_fin              decimal(10,2) NOT NULL DEFAULT 0,
    largo_m               float         NULL,   -- calculado al insertar
    altura_m              decimal(8,2)  NULL,
    dip_talud             decimal(5,2)  NOT NULL DEFAULT 0,
    alteracion_codigo     char(1)       NULL,
    intemperismo_codigo   char(1)       NULL,
    lito_1                varchar(20)   NULL,
    lito_2                varchar(20)   NULL,
    lito_3                varchar(20)   NULL,
    unidad_litologica     varchar(50)   NULL,
    sector                varchar(20)   NULL,
    fase                  tinyint       NULL,
    nivel                 float         NULL,
    sector_geotecnico     varchar(20)   NULL,
    creado_en             datetime2     NOT NULL DEFAULT SYSDATETIME(),
    modificado_en         datetime2     NULL
);
GO

IF OBJECT_ID('discontinuidad', 'U') IS NULL
CREATE TABLE discontinuidad (
    discontinuidad_id     int           IDENTITY(1,1) PRIMARY KEY,
    ventana_id            int           NOT NULL,
    familia_id            tinyint       NULL,
    orden_en_familia      tinyint       NULL,
    distancia_m           decimal(8,2)  NULL,
    tipo_estructura       varchar(4)    NOT NULL,
    dip                   decimal(5,2)  NOT NULL DEFAULT 0,
    dip_dir               decimal(6,2)  NOT NULL DEFAULT 0,
    abertura_mm           decimal(8,2)  NULL,
    espesor_mm            decimal(8,2)  NULL,
    continuidad_m         decimal(8,2)  NULL,
    espaciamiento_m       decimal(8,4)  NOT NULL DEFAULT 0,
    n_estructuras         decimal(5,1)  NULL,
    n_extremos_visibles   tinyint       NULL,
    terminacion           tinyint       NULL,
    relleno_1_codigo      varchar(4)    NULL,
    relleno_2_codigo      varchar(4)    NULL,
    jrc                   tinyint       NULL,
    rugosidad_codigo      tinyint       NULL,
    forma_estructura      varchar(4)    NULL,
    alteracion_codigo     char(1)       NULL,
    creado_en             datetime2     NOT NULL DEFAULT SYSDATETIME(),
    modificado_en         datetime2     NULL,
    CONSTRAINT fk_disc_ventana FOREIGN KEY (ventana_id) REFERENCES ventana(ventana_id)
);
GO

IF OBJECT_ID('ventana_rmr_input', 'U') IS NULL
CREATE TABLE ventana_rmr_input (
    ventana_id            int           NOT NULL PRIMARY KEY,
    agua_codigo           char(1)       NOT NULL DEFAULT 'C',
    resistencia_codigo    varchar(2)    NOT NULL DEFAULT 'R4',
    gsi_estructura        varchar(4)    NULL,
    gsi_superficie        varchar(4)    NULL,
    gsi_visual            tinyint       NULL,
    control_estructural   tinyint       NULL,
    efectos_voladura      tinyint       NULL,
    ucs_mpa               decimal(8,2)  NULL,
    is50_mpa              decimal(8,2)  NULL,
    comentario            nvarchar(MAX) NULL,
    creado_en             datetime2     NOT NULL DEFAULT SYSDATETIME(),
    modificado_en         datetime2     NULL,
    CONSTRAINT fk_rmri_ventana FOREIGN KEY (ventana_id) REFERENCES ventana(ventana_id)
);
GO

-- Tabla staging para importación Excel (columnas del Excel real del proyecto)
IF OBJECT_ID('ventanas_final', 'U') IS NULL
CREATE TABLE ventanas_final (
    id                          int            IDENTITY(1,1) PRIMARY KEY,
    celda                       nvarchar(50)   NOT NULL,
    este_from                   float          NOT NULL DEFAULT 0,
    norte_from                  float          NOT NULL DEFAULT 0,
    cota_from                   float          NOT NULL DEFAULT 0,
    este_to                     float          NOT NULL DEFAULT 0,
    norte_to                    float          NOT NULL DEFAULT 0,
    cota_to                     float          NOT NULL DEFAULT 0,
    dist_celda                  float          NULL,
    altura                      float          NULL,
    dip                         float          NULL,
    az_hole                     float          NULL,
    dip_talud                   float          NULL,
    dip_dir_talud               decimal(6,2)   NULL,
    intemperismo                nvarchar(50)   NULL,
    cond_agua_76                nvarchar(50)   NULL,
    cond_agua_valor_76          int            NULL,
    dureza_76                   nvarchar(10)   NULL,
    resistencia_est_valor_76    int            NULL,
    gsi_visual_76               int            NULL,
    control_estructural_76      int            NULL,
    efectos_voladura_76         int            NULL,
    rqd_valor_76                int            NULL,
    rqd_76                      float          NULL,
    freq_fractura_m_76          float          NULL,
    tam_bloques_m3_76           float          NULL,
    espaciamiento_prom_76       float          NULL,
    espaciamiento_valor_76      int            NULL,
    cond_discontinuidad_valor_76 float         NULL,
    rmr_76                      float          NULL,
    ucs_mpa                     float          NULL,
    is50_mpa                    float          NULL,
    cond_agua_89                nvarchar(50)   NULL,
    cond_agua_valor_89          int            NULL,
    dureza_89                   nvarchar(10)   NULL,
    resistencia_est_valor_89    float          NULL,
    gsi_visual_89               int            NULL,
    control_estructural_89      int            NULL,
    efecto_voladura_89          int            NULL,
    rqd_valor_89                float          NULL,
    rqd_89                      float          NULL,
    freq_fractura_m_89          float          NULL,
    tam_bloques_m3_89           float          NULL,
    espaciamiento_prom_89       float          NULL,
    espaciamiento_valor_89      float          NULL,
    cond_discontinuidad_valor_89 float         NULL,
    rmr_89                      float          NULL,
    fecha                       datetime2      NULL,
    comentario                  nvarchar(MAX)  NULL,
    dist_estructura             float          NULL,
    angulo_estruct_teta         float          NULL,
    angulo_estruct_alfa         float          NULL,
    estruct_x                   float          NULL,
    struct_y                    float          NULL,
    struct_z                    float          NULL,
    tipo_estructura             nvarchar(50)   NOT NULL DEFAULT '',
    dip_estructura              int            NOT NULL DEFAULT 0,
    dip_dir_estructura          decimal(6,2)   NOT NULL DEFAULT 0,
    num_estructuras             int            NULL,
    abertura_mm                 float          NOT NULL DEFAULT 0,
    espesor_mm                  decimal(8,2)   NOT NULL DEFAULT 0,
    continuidad_m               decimal(8,2)   NOT NULL DEFAULT 0,
    espaciamiento_m             decimal(8,4)   NULL,
    num_extremos_visibles       int            NULL,
    tipo_relleno_1              nvarchar(50)   NOT NULL DEFAULT '',
    tipo_relleno_2              nvarchar(MAX)  NOT NULL DEFAULT '',
    jrc                         int            NULL,
    rugosidad_estructuras       int            NOT NULL DEFAULT 0,
    forma_estructura            nvarchar(10)   NOT NULL DEFAULT '',
    alteracion                  nvarchar(10)   NOT NULL DEFAULT '',
    geotecnico                  nvarchar(50)   NULL,
    nivel                       float          NULL,
    lito_1                      nvarchar(50)   NULL,
    lito_2                      nvarchar(50)   NULL,
    lito_3                      nvarchar(50)   NULL,
    unidad_litologica           nvarchar(50)   NULL,
    sector_geotecnico           nvarchar(50)   NOT NULL DEFAULT '',
    campania                    smallint       NOT NULL DEFAULT 0
);
GO


-- ── 3. VISTAS ────────────────────────────────────────────────

-- Helper interno: JV y RQD por ventana a partir de discontinuidades
IF OBJECT_ID('vw_ventana_jv', 'V') IS NOT NULL DROP VIEW vw_ventana_jv;
GO
CREATE VIEW vw_ventana_jv AS
WITH espacios AS (
    SELECT
        ventana_id,
        familia_id,
        AVG(espaciamiento_m) AS prom_espac
    FROM discontinuidad
    WHERE espaciamiento_m > 0
    GROUP BY ventana_id, familia_id
),
jv_calc AS (
    SELECT
        ventana_id,
        SUM(1.0 / prom_espac)            AS jv,
        COUNT(DISTINCT familia_id)        AS n_familias,
        AVG(prom_espac)                   AS promedio_de_promedios
    FROM espacios
    WHERE prom_espac > 0
    GROUP BY ventana_id
)
SELECT
    v.ventana_id,
    ISNULL(j.jv, 0)                                            AS jv,
    ISNULL(j.n_familias, 0)                                    AS n_familias,
    j.promedio_de_promedios,
    CAST(ISNULL(115 - 3.3 * j.jv, 0) AS numeric(6,2))         AS rqd_pct
FROM ventana v
LEFT JOIN jv_calc j ON j.ventana_id = v.ventana_id;
GO

-- vw_ventana_geom — geometría del talud (dip_hole, az_hole, dip_dir_talud calculados)
IF OBJECT_ID('vw_ventana_geom', 'V') IS NOT NULL DROP VIEW vw_ventana_geom;
GO
CREATE VIEW vw_ventana_geom AS
SELECT
    ventana_id,
    -- dip_hole: ángulo vertical del sondaje (atan del desnivel / distancia horizontal)
    CASE
        WHEN SQRT(POWER(CAST(este_fin-este_ini AS float),2) + POWER(CAST(norte_fin-norte_ini AS float),2)) > 0
        THEN DEGREES(ATAN(
            ABS(CAST(cota_fin-cota_ini AS float)) /
            SQRT(POWER(CAST(este_fin-este_ini AS float),2) + POWER(CAST(norte_fin-norte_ini AS float),2))
        ))
        ELSE NULL
    END AS dip_hole,
    -- az_hole: azimut del sondaje en grados (ATN2 devuelve [-180,180] → normalizar a [0,360])
    CASE
        WHEN (este_fin - este_ini) = 0 AND (norte_fin - norte_ini) = 0 THEN NULL
        WHEN DEGREES(ATN2(CAST(este_fin-este_ini AS float), CAST(norte_fin-norte_ini AS float))) < 0
        THEN DEGREES(ATN2(CAST(este_fin-este_ini AS float), CAST(norte_fin-norte_ini AS float))) + 360.0
        ELSE DEGREES(ATN2(CAST(este_fin-este_ini AS float), CAST(norte_fin-norte_ini AS float)))
    END AS az_hole,
    -- dip_dir_talud (placeholder — requiere info adicional)
    CAST(NULL AS float) AS dip_dir_talud
FROM ventana;
GO

-- vw_litologia_match — clasificación litológica por ventana
IF OBJECT_ID('vw_litologia_match', 'V') IS NOT NULL DROP VIEW vw_litologia_match;
GO
CREATE VIEW vw_litologia_match AS
SELECT
    v.ventana_id,
    v.codigo,
    v.lito_1,
    v.lito_2,
    v.lito_3,
    dl.litologia_id,
    dl.categoria,
    dl.factor_k,
    dl.lito_3 AS lito_3_match
FROM ventana v
LEFT JOIN dim_litologia dl
    ON  dl.lito_1 = v.lito_1
    AND dl.lito_2 = v.lito_2
    AND dl.lito_3 = v.lito_3;
GO

-- vw_familia_aggregates — agrega espaciamiento por familia
IF OBJECT_ID('vw_familia_aggregates', 'V') IS NOT NULL DROP VIEW vw_familia_aggregates;
GO
CREATE VIEW vw_familia_aggregates AS
SELECT
    ventana_id,
    familia_id,
    CAST(AVG(espaciamiento_m)     AS decimal(8,4)) AS prom_espaciamiento_m,
    COUNT(*)                                        AS n_discontinuidades,
    CAST(SUM(n_estructuras)       AS decimal(8,1)) AS suma_n_estructuras
FROM discontinuidad
WHERE familia_id IS NOT NULL
GROUP BY ventana_id, familia_id;
GO

-- vw_discontinuidad_calc — cada fractura con sus ratings Bieniawski calculados
IF OBJECT_ID('vw_discontinuidad_calc', 'V') IS NOT NULL DROP VIEW vw_discontinuidad_calc;
GO
CREATE VIEW vw_discontinuidad_calc AS
SELECT
    d.discontinuidad_id,
    d.ventana_id,
    d.familia_id,
    d.orden_en_familia,
    d.distancia_m,
    d.tipo_estructura,
    d.dip,
    d.dip_dir,
    d.abertura_mm,
    d.espesor_mm,
    d.continuidad_m,
    d.espaciamiento_m,
    d.n_estructuras,
    d.n_extremos_visibles,
    d.terminacion,
    d.relleno_1_codigo,
    d.relleno_2_codigo,
    d.jrc,
    d.rugosidad_codigo,
    d.forma_estructura,
    d.alteracion_codigo,

    -- Alteración
    dm.rating_76  AS alteracion_76,
    dm.rating_89  AS alteracion_89,

    -- Relleno individual
    rv1.rating_76 AS relleno_1_76,
    rv1.rating_89 AS relleno_1_89,
    rv2.rating_76 AS relleno_2_76,
    rv2.rating_89 AS relleno_2_89,

    -- Relleno final = mínimo de los dos
    CASE
        WHEN rv1.rating_76 IS NOT NULL AND rv2.rating_76 IS NOT NULL
            THEN CASE WHEN rv1.rating_76 < rv2.rating_76 THEN rv1.rating_76 ELSE rv2.rating_76 END
        ELSE COALESCE(rv1.rating_76, rv2.rating_76)
    END AS relleno_76,
    CASE
        WHEN rv1.rating_89 IS NOT NULL AND rv2.rating_89 IS NOT NULL
            THEN CASE WHEN rv1.rating_89 < rv2.rating_89 THEN rv1.rating_89 ELSE rv2.rating_89 END
        ELSE COALESCE(rv1.rating_89, rv2.rating_89)
    END AS relleno_89,

    -- Continuidad
    dc.rating_76  AS continuidad_76,
    dc.rating_89  AS continuidad_89,

    -- Abertura
    da.rating_76  AS abertura_76,
    da.rating_89  AS abertura_89,

    -- Rugosidad
    dr.rating_76  AS rugosidad_76,
    dr.rating_89  AS rugosidad_89,

    -- Condición total RMR'76
    CAST(
        COALESCE(dm.rating_76,0) +
        CASE
            WHEN rv1.rating_76 IS NOT NULL AND rv2.rating_76 IS NOT NULL
                THEN CASE WHEN rv1.rating_76 < rv2.rating_76 THEN rv1.rating_76 ELSE rv2.rating_76 END
            ELSE COALESCE(rv1.rating_76,0)
        END +
        COALESCE(dc.rating_76,0) +
        COALESCE(da.rating_76,0) +
        COALESCE(dr.rating_76,0)
    AS int) AS valor_condisc_76,

    -- Condición total RMR'89
    CAST(
        COALESCE(dm.rating_89,0) +
        CASE
            WHEN rv1.rating_89 IS NOT NULL AND rv2.rating_89 IS NOT NULL
                THEN CASE WHEN rv1.rating_89 < rv2.rating_89 THEN rv1.rating_89 ELSE rv2.rating_89 END
            ELSE COALESCE(rv1.rating_89,0)
        END +
        COALESCE(dc.rating_89,0) +
        COALESCE(da.rating_89,0) +
        COALESCE(dr.rating_89,0)
    AS int) AS valor_condisc_89

FROM discontinuidad d
-- Alteración
LEFT JOIN dim_meteorizacion dm
    ON dm.codigo = d.alteracion_codigo
-- Relleno 1
LEFT JOIN dim_relleno_tipo   rt1
    ON rt1.codigo = d.relleno_1_codigo
LEFT JOIN dim_relleno_espesor re1
    ON re1.espesor_min_mm = (CASE WHEN ISNULL(d.espesor_mm,0) < 5 THEN 0.00 ELSE 5.00 END)
LEFT JOIN dim_relleno_valor   rv1
    ON rv1.categoria_relleno = rt1.categoria_relleno
   AND rv1.categoria_espesor = re1.categoria_espesor
-- Relleno 2
LEFT JOIN dim_relleno_tipo   rt2
    ON rt2.codigo = d.relleno_2_codigo
LEFT JOIN dim_relleno_espesor re2
    ON re2.espesor_min_mm = (CASE WHEN ISNULL(d.espesor_mm,0) < 5 THEN 0.00 ELSE 5.00 END)
LEFT JOIN dim_relleno_valor   rv2
    ON rv2.categoria_relleno = rt2.categoria_relleno
   AND rv2.categoria_espesor = re2.categoria_espesor
-- Continuidad
LEFT JOIN dim_continuidad dc
    ON dc.continuidad_min_m = (
        SELECT MAX(continuidad_min_m)
        FROM dim_continuidad
        WHERE continuidad_min_m <= ISNULL(d.continuidad_m, 0)
    )
-- Abertura
LEFT JOIN dim_abertura da
    ON da.abertura_min_mm = (
        SELECT MAX(abertura_min_mm)
        FROM dim_abertura
        WHERE abertura_min_mm <= ISNULL(d.abertura_mm, 0)
    )
-- Rugosidad
LEFT JOIN dim_rugosidad dr
    ON dr.codigo_isrm = d.rugosidad_codigo;
GO

-- vw_ventana_rmr — RMR76 y RMR89 por ventana (una fila por versión)
-- El frontend usa versión 76 y 89 separadas con la columna "version"
IF OBJECT_ID('vw_ventana_rmr', 'V') IS NOT NULL DROP VIEW vw_ventana_rmr;
GO
CREATE VIEW vw_ventana_rmr AS
WITH
-- Condición de discontinuidades ponderada por n_estructuras
cond_agg AS (
    SELECT
        ventana_id,
        CASE WHEN SUM(ISNULL(n_estructuras,1)) > 0
             THEN SUM(valor_condisc_76 * ISNULL(n_estructuras,1)) / SUM(ISNULL(n_estructuras,1))
             ELSE 0 END AS condisc_76,
        CASE WHEN SUM(ISNULL(n_estructuras,1)) > 0
             THEN SUM(valor_condisc_89 * ISNULL(n_estructuras,1)) / SUM(ISNULL(n_estructuras,1))
             ELSE 0 END AS condisc_89
    FROM vw_discontinuidad_calc
    GROUP BY ventana_id
),
-- Espaciamiento ponderado
espac_agg AS (
    SELECT
        ventana_id,
        CASE WHEN SUM(ISNULL(n_estructuras,1)) > 0
             THEN CAST(SUM(ISNULL(espaciamiento_m,0)*ISNULL(n_estructuras,1))/SUM(ISNULL(n_estructuras,1)) AS decimal(8,4))
             ELSE NULL END AS espac_pond
    FROM discontinuidad
    WHERE espaciamiento_m > 0
    GROUP BY ventana_id
)
-- RMR'76
SELECT
    v.ventana_id,
    v.codigo                 AS ventana_codigo,
    76                       AS version,
    r.agua_codigo,
    da76.rating_76           AS agua_valor,
    r.resistencia_codigo,
    dr76.rating_76           AS resistencia_valor,
    r.gsi_estructura,
    r.gsi_superficie,
    r.gsi_visual,
    r.control_estructural,
    r.efectos_voladura,
    CAST(ISNULL(115-3.3*jv.jv,0) AS numeric(6,2))               AS rqd_pct,
    CAST(COALESCE(rqd76.rating_76,3) AS numeric(4,0))            AS rqd_valor,
    CAST(ISNULL(jv.jv+1,0) AS numeric(8,4))                     AS frec_fract_x_m,
    CAST(jv.promedio_de_promedios AS decimal(8,4))               AS tamano_bloque_m3,
    ea.espac_pond                                                 AS espaciamiento_prom_pond,
    CAST(COALESCE(es76.rating_76,5) AS tinyint)                  AS espaciamiento_valor,
    CAST(ROUND(ISNULL(ca.condisc_76,0),2) AS decimal(6,2))       AS condisc_valor,
    CAST(
        COALESCE(da76.rating_76,0) + COALESCE(dr76.rating_76,0) +
        COALESCE(rqd76.rating_76,3) + COALESCE(es76.rating_76,5) +
        ROUND(ISNULL(ca.condisc_76,0),0)
    AS decimal(6,2))                                              AS rmr_total,
    r.ucs_mpa,
    r.is50_mpa
FROM ventana v
LEFT JOIN ventana_rmr_input r  ON r.ventana_id  = v.ventana_id
LEFT JOIN vw_ventana_jv   jv   ON jv.ventana_id = v.ventana_id
LEFT JOIN cond_agg        ca   ON ca.ventana_id = v.ventana_id
LEFT JOIN espac_agg       ea   ON ea.ventana_id = v.ventana_id
LEFT JOIN dim_agua        da76 ON da76.codigo   = r.agua_codigo
LEFT JOIN dim_resistencia dr76 ON dr76.codigo_r = r.resistencia_codigo
LEFT JOIN dim_rqd rqd76 ON rqd76.rqd_min_pct = (
    SELECT MAX(rqd_min_pct) FROM dim_rqd
    WHERE rqd_min_pct <= ISNULL(115-3.3*jv.jv,0))
LEFT JOIN dim_espaciamiento_76 es76 ON es76.espaciamiento_min_m = (
    SELECT MAX(espaciamiento_min_m) FROM dim_espaciamiento_76
    WHERE espaciamiento_min_m <= ISNULL(ea.espac_pond,0))

UNION ALL

-- RMR'89
SELECT
    v.ventana_id,
    v.codigo                 AS ventana_codigo,
    89                       AS version,
    r.agua_codigo,
    da89.rating_89           AS agua_valor,
    r.resistencia_codigo,
    dr89.rating_89           AS resistencia_valor,
    r.gsi_estructura,
    r.gsi_superficie,
    r.gsi_visual,
    r.control_estructural,
    r.efectos_voladura,
    CAST(ISNULL(115-3.3*jv.jv,0) AS numeric(6,2))               AS rqd_pct,
    CAST(COALESCE(rqd89.rating_89,3) AS numeric(4,0))            AS rqd_valor,
    CAST(ISNULL(jv.jv+1,0) AS numeric(8,4))                     AS frec_fract_x_m,
    CAST(jv.promedio_de_promedios AS decimal(8,4))               AS tamano_bloque_m3,
    ea.espac_pond                                                 AS espaciamiento_prom_pond,
    CAST(COALESCE(es89.rating_89,5) AS tinyint)                  AS espaciamiento_valor,
    CAST(ROUND(ISNULL(ca.condisc_89,0),2) AS decimal(6,2))       AS condisc_valor,
    CAST(
        COALESCE(da89.rating_89,0) + COALESCE(dr89.rating_89,0) +
        COALESCE(rqd89.rating_89,3) + COALESCE(es89.rating_89,5) +
        ROUND(ISNULL(ca.condisc_89,0),0)
    AS decimal(6,2))                                              AS rmr_total,
    r.ucs_mpa,
    r.is50_mpa
FROM ventana v
LEFT JOIN ventana_rmr_input r  ON r.ventana_id  = v.ventana_id
LEFT JOIN vw_ventana_jv   jv   ON jv.ventana_id = v.ventana_id
LEFT JOIN cond_agg        ca   ON ca.ventana_id = v.ventana_id
LEFT JOIN espac_agg       ea   ON ea.ventana_id = v.ventana_id
LEFT JOIN dim_agua        da89 ON da89.codigo   = r.agua_codigo
LEFT JOIN dim_resistencia dr89 ON dr89.codigo_r = r.resistencia_codigo
LEFT JOIN dim_rqd rqd89 ON rqd89.rqd_min_pct = (
    SELECT MAX(rqd_min_pct) FROM dim_rqd
    WHERE rqd_min_pct <= ISNULL(115-3.3*jv.jv,0))
LEFT JOIN dim_espaciamiento_89 es89 ON es89.espaciamiento_min_m = (
    SELECT MAX(espaciamiento_min_m) FROM dim_espaciamiento_89
    WHERE espaciamiento_min_m <= ISNULL(ea.espac_pond,0));
GO

-- vw_bd — vista completa (una fila por discontinuidad), columnas con nombres del Excel original
IF OBJECT_ID('vw_bd', 'V') IS NOT NULL DROP VIEW vw_bd;
GO
CREATE VIEW vw_bd AS
SELECT
    v.ventana_id,
    d.discontinuidad_id                AS id,
    v.codigo                           AS celda,
    v.mapeador,
    v.este_ini                         AS este_from,
    v.norte_ini                        AS norte_from,
    v.cota_ini                         AS cota_from,
    v.este_fin                         AS este_to,
    v.norte_fin                        AS norte_to,
    v.cota_fin                         AS cota_to,
    v.largo_m                          AS dist_celda,
    v.altura_m                         AS altura,
    v.dip_talud,
    g.dip_dir_talud,
    g.dip_hole                         AS dip,
    g.az_hole,
    v.intemperismo_codigo              AS intemperismo,
    v.fecha_mapeo                      AS fecha,
    v.campania,
    v.sector_geotecnico                AS geotecnico,
    v.lito_1,
    v.lito_2,
    v.lito_3,
    v.unidad_litologica,
    lm.factor_k,
    lm.categoria                       AS categoria_litologica,
    v.sector,
    CAST(v.nivel AS int)               AS nivel,
    v.sector_geotecnico,
    -- RMR'76
    r76.agua_codigo                    AS condicion_agua_76,
    r76.agua_valor                     AS condicion_agua_valor_76,
    r76.resistencia_codigo             AS dureza_76,
    r76.resistencia_valor              AS resistencia_estimada_valor_76,
    r76.gsi_visual                     AS gsi_visual_76,
    r76.control_estructural            AS control_estructural_76,
    r76.efectos_voladura               AS efectos_voladura_76,
    r76.rqd_valor                      AS rqd_valor_76,
    r76.rqd_pct                        AS rqd_76,
    r76.frec_fract_x_m                 AS frec_fract_x_m_76,
    r76.tamano_bloque_m3               AS tamano_bloques_m3_76,
    r76.espaciamiento_prom_pond        AS espaciamiento_prom_76,
    r76.espaciamiento_valor            AS espaciamiento_valor_76,
    r76.condisc_valor                  AS condicion_disc_valor_76,
    r76.rmr_total                      AS rmr_76,
    ri.ucs_mpa,
    ri.is50_mpa,
    -- RMR'89
    r89.agua_codigo                    AS condicion_agua_89,
    r89.agua_valor                     AS condicion_agua_valor_89,
    r89.resistencia_codigo             AS dureza_89,
    r89.resistencia_valor              AS resistencia_estimada_valor_89,
    r89.gsi_visual                     AS gsi_visual_89,
    r89.control_estructural            AS control_estructural_89,
    r89.efectos_voladura               AS efectos_voladura_89,
    r89.rqd_valor                      AS rqd_valor_89,
    r89.rqd_pct                        AS rqd_89,
    r89.frec_fract_x_m                 AS frec_fract_x_m_89,
    r89.tamano_bloque_m3               AS tamano_bloques_m3_89,
    r89.espaciamiento_prom_pond        AS espaciamiento_prom_89,
    r89.espaciamiento_valor            AS espaciamiento_valor_89,
    r89.condisc_valor                  AS condicion_disc_valor_89,
    r89.rmr_total                      AS rmr_89,
    -- Discontinuidad
    d.distancia_m                      AS dist_estructura,
    d.tipo_estructura,
    d.dip                              AS dip_estructura,
    d.dip_dir                          AS dip_dir_estructura,
    d.n_estructuras                    AS num_estructuras,
    d.abertura_mm,
    d.espesor_mm,
    d.continuidad_m,
    d.espaciamiento_m,
    d.n_extremos_visibles              AS num_extremos_visibles,
    ev.descripcion                     AS num_extremos_visibles_desc,
    d.relleno_1_codigo                 AS tipo_relleno_1,
    d.relleno_2_codigo                 AS tipo_relleno_2,
    d.jrc,
    d.rugosidad_codigo                 AS rugosidad_estructuras,
    d.forma_estructura,
    d.alteracion_codigo                AS alteracion,
    d.familia_id                       AS familia,
    d.orden_en_familia
FROM ventana v
INNER JOIN discontinuidad            d   ON d.ventana_id  = v.ventana_id
LEFT  JOIN ventana_rmr_input         ri  ON ri.ventana_id = v.ventana_id
LEFT  JOIN vw_ventana_rmr            r76 ON r76.ventana_id = v.ventana_id AND r76.version = 76
LEFT  JOIN vw_ventana_rmr            r89 ON r89.ventana_id = v.ventana_id AND r89.version = 89
LEFT  JOIN vw_ventana_geom           g   ON g.ventana_id  = v.ventana_id
LEFT  JOIN vw_litologia_match        lm  ON lm.ventana_id = v.ventana_id
LEFT  JOIN dim_extremos_visibles     ev  ON ev.codigo     = d.n_extremos_visibles;
GO


-- ── 4. STORED PROCEDURES ─────────────────────────────────────

-- sp_insertar_ventana_completa
IF OBJECT_ID('dbo.sp_insertar_ventana_completa', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_insertar_ventana_completa;
GO
CREATE PROCEDURE dbo.sp_insertar_ventana_completa
    @datos            NVARCHAR(MAX),
    @auto_clusterizar INT = 0,
    @ventana_id_out   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Calcular largo_m desde las coordenadas en el JSON
        DECLARE @este_ini  float = TRY_CAST(JSON_VALUE(@datos,'$.este_ini')  AS float);
        DECLARE @norte_ini float = TRY_CAST(JSON_VALUE(@datos,'$.norte_ini') AS float);
        DECLARE @cota_ini  float = TRY_CAST(JSON_VALUE(@datos,'$.cota_ini')  AS float);
        DECLARE @este_fin  float = TRY_CAST(JSON_VALUE(@datos,'$.este_fin')  AS float);
        DECLARE @norte_fin float = TRY_CAST(JSON_VALUE(@datos,'$.norte_fin') AS float);
        DECLARE @cota_fin  float = TRY_CAST(JSON_VALUE(@datos,'$.cota_fin')  AS float);
        DECLARE @largo_m   float = NULL;
        IF @este_ini IS NOT NULL AND @este_fin IS NOT NULL
            SET @largo_m = SQRT(
                POWER(@este_fin-@este_ini,2) +
                POWER(@norte_fin-@norte_ini,2) +
                POWER(@cota_fin-@cota_ini,2));

        -- Insertar ventana
        INSERT INTO ventana (
            codigo, fecha_mapeo, mapeador, campania, fase,
            este_ini, norte_ini, cota_ini,
            este_fin, norte_fin, cota_fin,
            largo_m, altura_m, dip_talud,
            alteracion_codigo, intemperismo_codigo,
            lito_1, lito_2, lito_3, unidad_litologica,
            sector, nivel, sector_geotecnico
        ) VALUES (
            LEFT(ISNULL(JSON_VALUE(@datos,'$.codigo'),''),10),
            TRY_CAST(JSON_VALUE(@datos,'$.fecha_mapeo')   AS date),
            LEFT(ISNULL(JSON_VALUE(@datos,'$.mapeador'),''),20),
            TRY_CAST(JSON_VALUE(@datos,'$.campania')      AS smallint),
            TRY_CAST(JSON_VALUE(@datos,'$.fase')          AS tinyint),
            ISNULL(TRY_CAST(JSON_VALUE(@datos,'$.este_ini')  AS decimal(12,2)),0),
            ISNULL(TRY_CAST(JSON_VALUE(@datos,'$.norte_ini') AS decimal(12,2)),0),
            ISNULL(TRY_CAST(JSON_VALUE(@datos,'$.cota_ini')  AS decimal(10,2)),0),
            ISNULL(TRY_CAST(JSON_VALUE(@datos,'$.este_fin')  AS decimal(12,2)),0),
            ISNULL(TRY_CAST(JSON_VALUE(@datos,'$.norte_fin') AS decimal(12,2)),0),
            ISNULL(TRY_CAST(JSON_VALUE(@datos,'$.cota_fin')  AS decimal(10,2)),0),
            @largo_m,
            TRY_CAST(JSON_VALUE(@datos,'$.altura_m')     AS decimal(8,2)),
            ISNULL(TRY_CAST(JSON_VALUE(@datos,'$.dip_talud') AS decimal(5,2)),0),
            LEFT(JSON_VALUE(@datos,'$.alteracion_codigo'),1),
            LEFT(JSON_VALUE(@datos,'$.intemperismo_codigo'),1),
            LEFT(JSON_VALUE(@datos,'$.lito_1'),20),
            LEFT(JSON_VALUE(@datos,'$.lito_2'),20),
            LEFT(JSON_VALUE(@datos,'$.lito_3'),20),
            LEFT(JSON_VALUE(@datos,'$.unidad_litologica'),50),
            LEFT(JSON_VALUE(@datos,'$.sector'),20),
            TRY_CAST(JSON_VALUE(@datos,'$.nivel')        AS float),
            LEFT(JSON_VALUE(@datos,'$.sector_geotecnico'),20)
        );
        SET @ventana_id_out = SCOPE_IDENTITY();

        -- Insertar inputs RMR (validamos que agua y resistencia existan en dim)
        DECLARE @agua_cod  char(1)   = JSON_VALUE(@datos,'$.rmr.agua_codigo');
        DECLARE @res_cod   varchar(2)= JSON_VALUE(@datos,'$.rmr.resistencia_codigo');
        IF NOT EXISTS (SELECT 1 FROM dim_agua        WHERE codigo   = @agua_cod) SET @agua_cod = 'C';
        IF NOT EXISTS (SELECT 1 FROM dim_resistencia WHERE codigo_r = @res_cod)  SET @res_cod  = 'R4';

        INSERT INTO ventana_rmr_input (
            ventana_id, agua_codigo, resistencia_codigo,
            gsi_estructura, gsi_superficie, gsi_visual,
            control_estructural, efectos_voladura,
            ucs_mpa, is50_mpa, comentario
        ) VALUES (
            @ventana_id_out,
            @agua_cod,
            @res_cod,
            JSON_VALUE(@datos,'$.rmr.gsi_estructura'),
            JSON_VALUE(@datos,'$.rmr.gsi_superficie'),
            TRY_CAST(JSON_VALUE(@datos,'$.rmr.gsi_visual')          AS tinyint),
            TRY_CAST(JSON_VALUE(@datos,'$.rmr.control_estructural') AS tinyint),
            TRY_CAST(JSON_VALUE(@datos,'$.rmr.efectos_voladura')    AS tinyint),
            TRY_CAST(JSON_VALUE(@datos,'$.rmr.ucs_mpa')             AS decimal(8,2)),
            TRY_CAST(JSON_VALUE(@datos,'$.rmr.is50_mpa')            AS decimal(8,2)),
            JSON_VALUE(@datos,'$.rmr.comentario')
        );

        -- Insertar discontinuidades
        INSERT INTO discontinuidad (
            ventana_id, familia_id, distancia_m, tipo_estructura,
            dip, dip_dir, abertura_mm, espesor_mm,
            continuidad_m, espaciamiento_m,
            n_estructuras, n_extremos_visibles, terminacion,
            relleno_1_codigo, relleno_2_codigo,
            jrc, rugosidad_codigo, forma_estructura, alteracion_codigo
        )
        SELECT
            @ventana_id_out,
            TRY_CAST(d.familia_id          AS tinyint),
            TRY_CAST(d.distancia_m         AS decimal(8,2)),
            ISNULL(LEFT(d.tipo_estructura,4),'JN'),
            ISNULL(TRY_CAST(d.dip          AS decimal(5,2)),0),
            ISNULL(TRY_CAST(d.dip_dir      AS decimal(6,2)),0),
            TRY_CAST(d.abertura_mm         AS decimal(8,2)),
            TRY_CAST(d.espesor_mm          AS decimal(8,2)),
            TRY_CAST(d.continuidad_m       AS decimal(8,2)),
            ISNULL(TRY_CAST(d.espaciamiento_m AS decimal(8,4)),0),
            TRY_CAST(d.n_estructuras       AS decimal(5,1)),
            TRY_CAST(d.n_extremos_visibles AS tinyint),
            TRY_CAST(d.terminacion         AS tinyint),
            LEFT(d.relleno_1_codigo,4),
            LEFT(d.relleno_2_codigo,4),
            TRY_CAST(d.jrc                 AS tinyint),
            TRY_CAST(d.rugosidad_codigo    AS tinyint),
            LEFT(d.forma_estructura,4),
            LEFT(d.alteracion_codigo,1)
        FROM OPENJSON(@datos,'$.discontinuidades')
        WITH (
            familia_id            nvarchar(10) '$.familia_id',
            distancia_m           nvarchar(30) '$.distancia_m',
            tipo_estructura       nvarchar(10) '$.tipo_estructura',
            dip                   nvarchar(10) '$.dip',
            dip_dir               nvarchar(10) '$.dip_dir',
            abertura_mm           nvarchar(30) '$.abertura_mm',
            espesor_mm            nvarchar(30) '$.espesor_mm',
            continuidad_m         nvarchar(30) '$.continuidad_m',
            espaciamiento_m       nvarchar(30) '$.espaciamiento_m',
            n_estructuras         nvarchar(10) '$.n_estructuras',
            n_extremos_visibles   nvarchar(10) '$.n_extremos_visibles',
            terminacion           nvarchar(10) '$.terminacion',
            relleno_1_codigo      nvarchar(10) '$.relleno_1_codigo',
            relleno_2_codigo      nvarchar(10) '$.relleno_2_codigo',
            jrc                   nvarchar(10) '$.jrc',
            rugosidad_codigo      nvarchar(10) '$.rugosidad_codigo',
            forma_estructura      nvarchar(10) '$.forma_estructura',
            alteracion_codigo     nvarchar(10) '$.alteracion_codigo'
        ) AS d;

        -- Si se pidió clustering automático, se llama al SP correspondiente
        IF @auto_clusterizar = 1 AND OBJECT_ID('dbo.sp_asignar_familias_clustering','P') IS NOT NULL
            EXEC dbo.sp_asignar_familias_clustering @ventana_id = @ventana_id_out;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- sp_asignar_familias_clustering — placeholder (k-means en Python externo)
-- Este SP será invocado cuando @auto_clusterizar=1 en sp_insertar_ventana_completa
IF OBJECT_ID('dbo.sp_asignar_familias_clustering', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_asignar_familias_clustering;
GO
CREATE PROCEDURE dbo.sp_asignar_familias_clustering
    @ventana_id INT = NULL   -- NULL = procesa todas las ventanas
AS
BEGIN
    SET NOCOUNT ON;
    -- Placeholder: el clustering real se implementa externamente (Python k-means)
    -- Este SP existe para que el EXEC no falle
    PRINT 'sp_asignar_familias_clustering: pendiente de implementación de k-means';
END;
GO


-- ── 5. VERIFICACIÓN FINAL ────────────────────────────────────
PRINT '=== Schema Ventanas creado correctamente ===';
SELECT 'TABLA'  AS tipo, TABLE_NAME AS nombre FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME;
SELECT 'VISTA'  AS tipo, TABLE_NAME AS nombre FROM INFORMATION_SCHEMA.VIEWS ORDER BY TABLE_NAME;
SELECT 'STORED PROC' AS tipo, ROUTINE_NAME AS nombre FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='PROCEDURE' ORDER BY ROUTINE_NAME;
GO
