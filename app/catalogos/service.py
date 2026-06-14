"""
Catálogos (tablas dim_*) leídos desde BBDD_Geoteknia.

Se exponen como un único dict para que el frontend cargue toda la
configuración del sistema en una sola petición. Resultado cacheado en
memoria (las tablas dim_* son estáticas durante la ejecución).
"""

from app.database import get_connection

# Cache en memoria — las tablas dim_* no cambian en tiempo de ejecución.
_cache = None

# Definición declarativa: (clave_salida, tabla, [columnas], orden_sql_opcional)
# Las columnas se devuelven con el mismo nombre que la columna SQL.
_CATALOGOS = [
    ("agua",                "dim_agua",                ["codigo", "descripcion", "rating_76", "rating_89"],                       "codigo"),
    ("resistencia",         "dim_resistencia",         ["codigo_r", "mpa_descripcion", "rating_89", "rating_76"],                 None),
    ("rqd",                 "dim_rqd",                 ["rqd_min_pct", "descripcion", "rating_89", "rating_76"],                  "rqd_min_pct DESC"),
    ("espaciamiento_76",    "dim_espaciamiento_76",    ["espaciamiento_min_m", "descripcion", "rating_76"],                       "espaciamiento_min_m DESC"),
    ("espaciamiento_89",    "dim_espaciamiento_89",    ["espaciamiento_min_m", "descripcion", "rating_89"],                       "espaciamiento_min_m DESC"),
    ("abertura",            "dim_abertura",            ["abertura_min_mm", "nombre", "descripcion_mm", "rating_89", "rating_76"], "abertura_min_mm"),
    ("continuidad",         "dim_continuidad",         ["continuidad_min_m", "descripcion", "rating_89", "rating_76"],            "continuidad_min_m"),
    ("meteorizacion",       "dim_meteorizacion",       ["codigo", "descripcion", "rating_89", "rating_76"],                       None),
    ("rugosidad",           "dim_rugosidad",           ["codigo_isrm", "rating_89", "rating_76"],                                 "codigo_isrm"),
    ("relleno_tipo",        "dim_relleno_tipo",        ["codigo", "categoria_relleno", "descripcion"],                            None),
    ("relleno_espesor",     "dim_relleno_espesor",     ["espesor_min_mm", "descripcion", "categoria_espesor"],                    "espesor_min_mm"),
    ("relleno_valor",       "dim_relleno_valor",       ["categoria_relleno", "categoria_espesor", "descripcion", "rating_89", "rating_76"], None),
    ("extremos_visibles",   "dim_extremos_visibles",   ["codigo", "descripcion", "nota"],                                         "codigo"),
    ("isrm",                "dim_isrm",                ["ucs_min_mpa", "abreviatura", "denominacion"],                            "ucs_min_mpa"),
    ("litologia",           "dim_litologia",           ["litologia_id", "categoria", "lito_1", "lito_2", "lito_3", "factor_k", "nota"], "lito_1"),
    ("tipo_estructura",     "dim_tipo_estructura",     ["codigo", "descripcion", "simbolo", "orden"],                             "orden"),
    ("forma_estructura",    "dim_forma_estructura",    ["codigo", "descripcion", "orden"],                                        "orden"),
    ("gsi_estructura",      "dim_gsi_estructura",      ["codigo", "descripcion_en", "descripcion_es", "orden"],                   "orden"),
    ("gsi_superficie",      "dim_gsi_superficie",      ["codigo", "descripcion_en", "descripcion_es", "orden"],                   "orden"),
    ("terminacion",         "dim_terminacion",         ["codigo", "descripcion", "nota"],                                         "codigo"),
    ("control_estructural", "dim_control_estructural", ["codigo", "nombre", "descripcion"],                                       "codigo"),
    ("efectos_voladura",    "dim_efectos_voladura",    ["codigo", "nombre", "descripcion"],                                       "codigo"),
]


def _fetch(cur, tabla, columnas, orden):
    cols_sql = ", ".join(columnas)
    sql = f"SELECT {cols_sql} FROM {tabla}"
    if orden:
        sql += f" ORDER BY {orden}"
    cur.execute(sql)
    filas = cur.fetchall()
    return [dict(zip(columnas, fila)) for fila in filas]


def obtener_catalogos(force=False):
    """Devuelve todos los catálogos dim_* como un dict. Cacheado en memoria."""
    global _cache
    if _cache is not None and not force:
        return _cache

    resultado = {}
    conn = get_connection()
    try:
        cur = conn.cursor()
        for clave, tabla, columnas, orden in _CATALOGOS:
            resultado[clave] = _fetch(cur, tabla, columnas, orden)
    finally:
        conn.close()

    _cache = resultado
    return resultado
