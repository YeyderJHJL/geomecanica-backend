"""
Validaciones y lógica de consulta para ventanas.
"""

import math

from app.database import get_connection
from app.rmr.calculos import _num, _int, calcular_largo_celda


# ─────────────────────────────────────────────────────────────────────────────
# VALIDACIÓN DE INGRESO
# ─────────────────────────────────────────────────────────────────────────────

def validar_ventana(data):
    """
    Valida header + rows + rmr.
    Devuelve lista de dicts {"campo": ..., "mensaje": ...}.
    Lista vacía = sin errores.
    """
    errores = []
    hdr    = data.get("header", {})
    rows   = data.get("rows", [])
    rmr_in = data.get("rmr", {})

    largo = calcular_largo_celda(
        hdr.get("iniX") or hdr.get("este_ini"),
        hdr.get("iniY") or hdr.get("norte_ini"),
        hdr.get("iniC") or hdr.get("cota_ini"),
        hdr.get("finX") or hdr.get("este_fin"),
        hdr.get("finY") or hdr.get("norte_fin"),
        hdr.get("finC") or hdr.get("cota_fin"),
    )

    for idx, r in enumerate(rows, start=1):
        prefix = f"Fila {idx}"

        dist = _num(r.get("dist") or r.get("distancia_m"))
        if dist is not None and largo is not None and dist > largo:
            errores.append({
                "campo":   f"rows[{idx}].distancia_m",
                "mensaje": (
                    f"{prefix}: distancia_m ({dist:.2f} m) supera el largo de celda "
                    f"({largo:.2f} m)."
                ),
            })

        dip = _int(r.get("dip"))
        if dip is not None and not (0 <= dip <= 90):
            errores.append({
                "campo":   f"rows[{idx}].dip",
                "mensaje": f"{prefix}: dip debe estar entre 0 y 90 (valor: {dip}).",
            })

        dip_dir = _int(r.get("dipdir") or r.get("dip_dir"))
        if dip_dir is not None and not (0 <= dip_dir <= 360):
            errores.append({
                "campo":   f"rows[{idx}].dip_dir",
                "mensaje": f"{prefix}: dip_dir debe estar entre 0 y 360 (valor: {dip_dir}).",
            })

        jrc = _int(r.get("jrc"))
        if jrc is not None and not (0 <= jrc <= 20):
            errores.append({
                "campo":   f"rows[{idx}].jrc",
                "mensaje": f"{prefix}: jrc debe estar entre 0 y 20 (valor: {jrc}).",
            })

        rug = _int(r.get("rug") or r.get("rugosidad_codigo"))
        if rug is not None and not (1 <= rug <= 9):
            errores.append({
                "campo":   f"rows[{idx}].rugosidad_codigo",
                "mensaje": f"{prefix}: rugosidad debe estar entre 1 y 9 (valor: {rug}).",
            })

        espac = _num(r.get("espac") or r.get("espaciamiento_m"))
        if espac is not None and espac <= 0:
            errores.append({
                "campo":   f"rows[{idx}].espaciamiento_m",
                "mensaje": f"{prefix}: espaciamiento_m debe ser mayor que 0 (valor: {espac}).",
            })

        r1 = (r.get("r1") or r.get("relleno_1_codigo") or "").strip()
        r2 = (r.get("r2") or r.get("relleno_2_codigo") or "").strip()
        if r2 and not r1:
            errores.append({
                "campo":   f"rows[{idx}].relleno_1_codigo",
                "mensaje": f"{prefix}: relleno_2 requiere que relleno_1 esté definido.",
            })

    ucs = _num(rmr_in.get("ucs_mpa"))
    if ucs is not None and ucs <= 0:
        errores.append({
            "campo":   "rmr.ucs_mpa",
            "mensaje": f"ucs_mpa debe ser mayor que 0 (valor: {ucs}).",
        })

    return errores


# ─────────────────────────────────────────────────────────────────────────────
# LISTADO PAGINADO
# ─────────────────────────────────────────────────────────────────────────────

def listar_ventanas(sector, campania, rmr_min, rmr_max, page, per_page):
    """
    Lista paginada de ventanas desde vw_bd + vw_ventana_rmr con filtros dinámicos.
    Devuelve {data, total, page, pages}.
    """
    offset = (page - 1) * per_page

    where_clauses = []
    params        = []

    if sector:
        where_clauses.append("b.sector = ?")
        params.append(sector)
    if campania is not None:
        where_clauses.append("b.campania = ?")
        params.append(int(campania))
    if rmr_min is not None:
        where_clauses.append("r.rmr89 >= ?")
        params.append(float(rmr_min))
    if rmr_max is not None:
        where_clauses.append("r.rmr89 <= ?")
        params.append(float(rmr_max))

    where_sql = f"WHERE {' AND '.join(where_clauses)}" if where_clauses else ""

    # COUNT usa DISTINCT ventana_id para no contar discontinuidades
    count_sql = f"""
        SELECT COUNT(*) FROM (
            SELECT DISTINCT b.ventana_id
            FROM vw_bd AS b
            LEFT JOIN vw_ventana_rmr AS r ON r.ventana_id = b.ventana_id
            {where_sql}
        ) AS cnt
    """

    # Datos paginados: cada ventana una sola fila con su RMR
    data_sql = f"""
        SELECT * FROM (
            SELECT DISTINCT
                b.ventana_id,
                b.codigo,
                b.fecha_mapeo,
                b.mapeador,
                b.sector,
                b.campania,
                r.rmr76,
                r.rmr89
            FROM vw_bd AS b
            LEFT JOIN vw_ventana_rmr AS r ON r.ventana_id = b.ventana_id
            {where_sql}
        ) AS t
        ORDER BY fecha_mapeo DESC, ventana_id DESC
        OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
    """

    conn = get_connection()
    try:
        cur = conn.cursor()

        cur.execute(count_sql, params)
        total = cur.fetchone()[0]

        cur.execute(data_sql, params + [offset, per_page])
        cols = [d[0] for d in cur.description]
        rows = [dict(zip(cols, row)) for row in cur.fetchall()]
    finally:
        conn.close()

    return {
        "data":  rows,
        "total": total,
        "page":  page,
        "pages": math.ceil(total / per_page) if total > 0 else 0,
    }


# ─────────────────────────────────────────────────────────────────────────────
# DETALLE DE VENTANA
# ─────────────────────────────────────────────────────────────────────────────

def obtener_detalle_ventana(ventana_id):
    """
    Devuelve la ventana completa con sus discontinuidades calculadas.
    Consulta la tabla ventana para la cabecera y vw_discontinuidad_calc
    para las discontinuidades. Devuelve None si no existe.
    """
    conn = get_connection()
    try:
        cur = conn.cursor()

        cur.execute(
            """
            SELECT
                v.*,
                ri.agua_codigo, ri.ucs_mpa, ri.is50_mpa, ri.resistencia_codigo,
                ri.gsi_estructura, ri.gsi_superficie, ri.gsi_visual,
                ri.control_estructural, ri.efectos_voladura, ri.comentario,
                r.rmr76, r.rmr89
            FROM ventana v
            LEFT JOIN ventana_rmr_input ri ON ri.ventana_id = v.ventana_id
            LEFT JOIN vw_ventana_rmr    r  ON r.ventana_id  = v.ventana_id
            WHERE v.ventana_id = ?
            """,
            ventana_id,
        )
        row = cur.fetchone()
        if not row:
            return None
        cols   = [d[0] for d in cur.description]
        cabeza = dict(zip(cols, row))

        cur.execute(
            """
            SELECT *
            FROM   vw_discontinuidad_calc
            WHERE  ventana_id = ?
            ORDER  BY familia_id, distancia_m
            """,
            ventana_id,
        )
        cols_d           = [d[0] for d in cur.description]
        discontinuidades = [dict(zip(cols_d, r)) for r in cur.fetchall()]
    finally:
        conn.close()

    return {**cabeza, "discontinuidades": discontinuidades}
