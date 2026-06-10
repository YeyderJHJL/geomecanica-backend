"""
Queries de agregación para el dashboard.
vw_ventana_rmr tiene columna 'version' (76/89) y 'rmr_total'.
campania y sector vienen de la tabla ventana.
"""

from app.database import get_connection

_CLASES_CALIDAD = [
    ("MUY_BUENA", "81-100"),
    ("BUENA",     "61-80"),
    ("REGULAR",   "41-60"),
    ("MALA",      "21-40"),
    ("MUY_MALA",  "0-20"),
]

_CASE_RMR89 = """
    CASE
        WHEN rmr89 BETWEEN 81 AND 100 THEN 'MUY_BUENA'
        WHEN rmr89 BETWEEN 61 AND 80  THEN 'BUENA'
        WHEN rmr89 BETWEEN 41 AND 60  THEN 'REGULAR'
        WHEN rmr89 BETWEEN 21 AND 40  THEN 'MALA'
        ELSE                               'MUY_MALA'
    END
"""


def obtener_stats_dashboard(sector=None, campania=None):
    """
    Devuelve estadísticas agregadas de RMR89/76 para el dashboard.
    Usa vw_ventana_rmr (version=76/89, rmr_total) + join a ventana para
    campania y sector.
    """
    where_clauses = []
    params        = []

    if sector:
        where_clauses.append("v.sector = ?")
        params.append(sector)
    if campania is not None:
        where_clauses.append("v.campania = ?")
        params.append(int(campania))

    where_sql = f"WHERE {' AND '.join(where_clauses)}" if where_clauses else ""

    # CTE base: una fila por ventana con rmr76 y rmr89 como columnas
    base_cte = f"""
        WITH base AS (
            SELECT
                v.ventana_id,
                v.sector,
                v.campania,
                MAX(CASE WHEN r.version = 76 THEN CAST(r.rmr_total AS float) END) AS rmr76,
                MAX(CASE WHEN r.version = 89 THEN CAST(r.rmr_total AS float) END) AS rmr89
            FROM ventana v
            LEFT JOIN vw_ventana_rmr r ON r.ventana_id = v.ventana_id
            {where_sql}
            GROUP BY v.ventana_id, v.sector, v.campania
        )
    """

    conn = get_connection()
    try:
        cur = conn.cursor()

        # ── Totales globales ─────────────────────────────────────────────────
        cur.execute(
            f"""
            {base_cte}
            SELECT
                COUNT(DISTINCT ventana_id) AS total_ventanas,
                AVG(rmr89)                 AS rmr89_promedio,
                AVG(rmr76)                 AS rmr76_promedio
            FROM base
            """,
            params,
        )
        row            = cur.fetchone()
        total_ventanas = row[0] or 0
        rmr89_promedio = round(row[1], 2) if row[1] is not None else None
        rmr76_promedio = round(row[2], 2) if row[2] is not None else None

        # ── Por campaña ──────────────────────────────────────────────────────
        cur.execute(
            f"""
            {base_cte}
            SELECT
                campania,
                AVG(rmr76) AS rmr76_prom,
                AVG(rmr89) AS rmr89_prom
            FROM base
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
            {base_cte}
            SELECT
                CASE
                    WHEN rmr89 BETWEEN 81 AND 100 THEN 'MUY_BUENA'
                    WHEN rmr89 BETWEEN 61 AND 80  THEN 'BUENA'
                    WHEN rmr89 BETWEEN 41 AND 60  THEN 'REGULAR'
                    WHEN rmr89 BETWEEN 21 AND 40  THEN 'MALA'
                    ELSE 'MUY_MALA'
                END AS clase,
                COUNT(*) AS cantidad
            FROM base
            WHERE rmr89 IS NOT NULL
            GROUP BY
                CASE
                    WHEN rmr89 BETWEEN 81 AND 100 THEN 'MUY_BUENA'
                    WHEN rmr89 BETWEEN 61 AND 80  THEN 'BUENA'
                    WHEN rmr89 BETWEEN 41 AND 60  THEN 'REGULAR'
                    WHEN rmr89 BETWEEN 21 AND 40  THEN 'MALA'
                    ELSE 'MUY_MALA'
                END
            """,
            params,
        )
        conteos_db = {r[0]: r[1] for r in cur.fetchall()}
        distribucion_calidad = [
            {"clase": clase, "rango": rango, "cantidad": conteos_db.get(clase, 0)}
            for clase, rango in _CLASES_CALIDAD
        ]

        # ── Por sector ───────────────────────────────────────────────────────
        cur.execute(
            f"""
            {base_cte}
            SELECT sector, COUNT(DISTINCT ventana_id) AS total
            FROM base
            GROUP BY sector
            ORDER BY total DESC
            """,
            params,
        )
        por_sector = [{"sector": r[0], "total": r[1]} for r in cur.fetchall()]

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
