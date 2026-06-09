"""
Importación masiva de Excel hacia ventanas_final.
Procesa fila por fila; los errores no detienen el proceso.
"""

import pandas as pd

from app.database import get_connection


def importar_excel(file_stream):
    """
    Lee un archivo Excel e inserta las filas en ventanas_final.
    Devuelve {insertados, errores, detalle_errores}.
    """
    try:
        df = pd.read_excel(file_stream, engine="openpyxl")
    except Exception as e:
        raise ValueError(f"No se pudo leer el archivo Excel: {e}")

    if df.empty:
        return {"insertados": 0, "errores": 0, "detalle_errores": []}

    # Normalizar nombres de columna al formato de la tabla
    df.columns = [
        str(c).strip().lower().replace(" ", "_").replace("-", "_")
        for c in df.columns
    ]

    df = df.dropna(how="all").reset_index(drop=True)

    cols         = list(df.columns)
    placeholders = ", ".join(["?"] * len(cols))
    cols_sql     = ", ".join(f"[{c}]" for c in cols)
    insert_sql   = f"INSERT INTO ventanas_final ({cols_sql}) VALUES ({placeholders})"

    insertados     = 0
    detalle_errores = []

    conn = get_connection()
    try:
        cursor = conn.cursor()
        for idx, row in df.iterrows():
            # Convierte enteros almacenados como float (ej. 1.0 → 1)
            vals = []
            for v in row.values:
                if pd.isna(v):
                    vals.append(None)
                elif isinstance(v, float) and v == int(v):
                    vals.append(int(v))
                else:
                    vals.append(v)

            try:
                cursor.execute(insert_sql, vals)
                insertados += 1
            except Exception as e:
                detalle_errores.append({
                    "fila_excel": int(idx) + 2,   # +2: cabecera en fila 1
                    "error":      str(e),
                })

        conn.commit()
    finally:
        conn.close()

    return {
        "insertados":      insertados,
        "errores":         len(detalle_errores),
        "detalle_errores": detalle_errores[:200],  # cap para no saturar respuesta
    }
