"""
Queries de agregación sobre vw_ventana_rmr para el dashboard.
"""

from app.database import get_connection

# Orden fijo de clases — siempre las 5, aunque alguna tenga cantidad 0
_CLASES_CALIDAD = [
    ("Muy buena", "81-100"),
    ("Buena",     "61-80"),
    ("Regular",   "41-60"),
    ("Mala",      "21-40"),
    ("Muy mala",  "0-20"),
]

_CASE_RMR89 = """
    CASE
        WHEN rmr89 BETWEEN 81 AND 100 THEN 'Muy buena'
        WHEN rmr89 BETWEEN 61 AND 80  THEN 'Buena'
        WHEN rmr89 BETWEEN 41 AND 60  THEN 'Regular'
        WHEN rmr89 BETWEEN 21 AND 40  THEN 'Mala'
        ELSE                               'Muy mala'
    END
"""


def obtener_stats_dashboard(sector=None, campania=None):
    """
    Devuelve estadísticas agregadas de RMR89/76 para el dashboard.

    Respuesta:
        total_ventanas      — COUNT DISTINCT ventana_id
        rmr89_promedio      — AVG global RMR89
        rmr76_promedio      — AVG global RMR76
        por_campania        — [{campania, rmr76_prom, rmr89_prom}]
        distribucion_calidad— [{clase, rango, cantidad}] siempre 5 clases
        por_sector          — [{sector, total}]
    """
    where_clauses = []
    params        = []

    if sector:
        where_clauses.append("sector = ?")
        params.append(sector)
    if campania is not None:
        where_clauses.append("campania = ?")
        params.append(int(campania))

    where_sql = f"WHERE {' AND '.join(where_clauses)}" if where_clauses else ""

    conn = get_connection()
    try:
        cur = conn.cursor()

        # ── Totales globales ─────────────────────────────────────────────────
        cur.execute(
            f"""
            SELECT
                COUNT(DISTINCT ventana_id) AS total_ventanas,
                AVG(CAST(rmr89 AS FLOAT))  AS rmr89_promedio,
                AVG(CAST(rmr76 AS FLOAT))  AS rmr76_promedio
            FROM vw_ventana_rmr
            {where_sql}
            """,
            params,
        )
        row   = cur.fetchone()
        total_ventanas = row[0] or 0
        rmr89_promedio = round(row[1], 2) if row[1] is not None else None
        rmr76_promedio = round(row[2], 2) if row[2] is not None else None

        # ── Por campaña ──────────────────────────────────────────────────────
        cur.execute(
            f"""
            SELECT
                campania,
                AVG(CAST(rmr76 AS FLOAT)) AS rmr76_prom,
                AVG(CAST(rmr89 AS FLOAT)) AS rmr89_prom
            FROM vw_ventana_rmr
            {where_sql}
            GROUP BY campania
            ORDER BY campania DESC
            """,
            params,
        )
        por_campania = [
            {
                "campania":   r[0],
                "rmr76_prom": round(r[1], 2) if r[1] is not None else None,
                "rmr89_prom": round(r[2], 2) if r[2] is not None else None,
            }
            for r in cur.fetchall()
        ]

        # ── Distribución de calidad (RMR89, siempre 5 clases) ───────────────
        cur.execute(
            f"""
            SELECT {_CASE_RMR89} AS clase, COUNT(*) AS cantidad
            FROM   vw_ventana_rmr
            {where_sql}
            GROUP  BY {_CASE_RMR89}
            """,
            params,
        )
        conteos_db = {r[0]: r[1] for r in cur.fetchall()}

        distribucion_calidad = [
            {
                "clase":    clase,
                "rango":    rango,
                "cantidad": conteos_db.get(clase, 0),
            }
            for clase, rango in _CLASES_CALIDAD
        ]

        # ── Por sector ───────────────────────────────────────────────────────
        cur.execute(
            f"""
            SELECT sector, COUNT(DISTINCT ventana_id) AS total
            FROM   vw_ventana_rmr
            {where_sql}
            GROUP  BY sector
            ORDER  BY total DESC
            """,
            params,
        )
        por_sector = [
            {"sector": r[0], "total": r[1]}
            for r in cur.fetchall()
        ]

    finally:
        conn.close()

    return {
        "total_ventanas":       total_ventanas,
        "rmr89_promedio":       rmr89_promedio,
        "rmr76_promedio":       rmr76_promedio,
        "por_campania":         por_campania,
        "distribucion_calidad": distribucion_calidad,
        "por_sector":           por_sector,
    }
