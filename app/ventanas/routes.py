from flask import Blueprint, request, jsonify

from app.database import get_connection
from app.rmr.calculos import generar_json_objetivo
from app.ventanas.service import validar_ventana, listar_ventanas, obtener_detalle_ventana

bp = Blueprint("ventanas", __name__)


@bp.route("/generar_json", methods=["POST"])
def api_generar_json():
    try:
        data      = request.get_json(force=True)
        resultado = generar_json_objetivo(data)
        return jsonify(resultado)
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@bp.route("/insertar_ventana", methods=["POST"])
def api_insertar_ventana():
    try:
        data             = request.get_json(force=True)
        auto_clusterizar = int(data.get("auto_clusterizar", 0))

        errores = validar_ventana(data)
        if errores:
            return jsonify({"ok": False, "errores": errores}), 422

        import json as _json
        resultado    = generar_json_objetivo(data)
        json_para_sp = _json.dumps(resultado, ensure_ascii=False)

        conn = get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute(
                """
                DECLARE @id INT;
                EXEC dbo.sp_insertar_ventana_completa
                    @datos            = ?,
                    @auto_clusterizar = ?,
                    @ventana_id_out   = @id OUTPUT;
                SELECT @id AS ventana_id;
                """,
                json_para_sp,
                auto_clusterizar,
            )
            row        = cursor.fetchone()
            ventana_id = int(row[0]) if row and row[0] is not None else None
            conn.commit()
        finally:
            conn.close()

        return jsonify({
            "ok":           True,
            "ventana_id":   ventana_id,
            "codigo":       resultado.get("codigo"),
            "json_enviado": resultado,      # incluye rmr._calc para el frontend
        })

    except KeyError as e:
        return jsonify({
            "ok":    False,
            "error": f"Variable de entorno faltante: {e}. Revisa tu archivo .env",
        }), 500
    except Exception as e:
        return jsonify({
            "ok":    False,
            "error": str(e),
            "tipo":  type(e).__name__,
        }), 500


@bp.route("/sectores", methods=["GET"])
def api_sectores():
    """Lista los sectores únicos registrados en la BD."""
    try:
        conn = get_connection()
        try:
            cur = conn.cursor()
            cur.execute(
                "SELECT DISTINCT sector FROM ventana WHERE sector IS NOT NULL ORDER BY sector"
            )
            sectores = [r[0] for r in cur.fetchall()]
        finally:
            conn.close()
        return jsonify(sectores)
    except Exception:
        return jsonify([])


@bp.route("/proyectos", methods=["GET"])
def api_proyectos():
    """Lista de proyectos disponibles."""
    try:
        conn = get_connection()
        try:
            cur = conn.cursor()
            # Si la tabla tiene columna proyecto la usamos; si no, devolvemos fallback
            cur.execute(
                "SELECT DISTINCT proyecto FROM ventana "
                "WHERE proyecto IS NOT NULL AND proyecto <> '' ORDER BY proyecto"
            )
            proyectos = [r[0] for r in cur.fetchall()]
        finally:
            conn.close()
        return jsonify(proyectos if proyectos else ["Proyecto A", "Proyecto B"])
    except Exception:
        return jsonify(["Proyecto A", "Proyecto B"])


@bp.route("/campanias", methods=["GET"])
def api_campanias():
    """Campañas únicas desde la BD (campania = año numérico en tabla ventana)."""
    try:
        conn = get_connection()
        try:
            cur = conn.cursor()
            cur.execute(
                "SELECT DISTINCT CAST(campania AS NVARCHAR(10)) "
                "FROM ventana WHERE campania IS NOT NULL ORDER BY 1 DESC"
            )
            campanias = [r[0] for r in cur.fetchall()]
        finally:
            conn.close()
        if not campanias:
            import datetime
            yr = datetime.datetime.now().year
            campanias = [str(y) for y in range(yr, yr - 5, -1)]
        return jsonify(campanias)
    except Exception:
        import datetime
        yr = datetime.datetime.now().year
        return jsonify([str(y) for y in range(yr, yr - 5, -1)])


@bp.route("/ventanas", methods=["GET"])
def api_listar_ventanas():
    """Lista paginada: ?sector=&campania=&rmr_min=&rmr_max=&page=&per_page="""
    try:
        page     = max(1, int(request.args.get("page", 1)))
        per_page = min(100, max(1, int(request.args.get("per_page", 20))))

        sector  = request.args.get("sector",  "").strip() or None
        campania_raw = request.args.get("campania", "").strip()
        campania = int(campania_raw) if campania_raw else None

        rmr_min_raw = request.args.get("rmr_min", "").strip()
        rmr_max_raw = request.args.get("rmr_max", "").strip()
        rmr_min = float(rmr_min_raw) if rmr_min_raw else None
        rmr_max = float(rmr_max_raw) if rmr_max_raw else None

        resultado = listar_ventanas(
            sector=sector,
            campania=campania,
            rmr_min=rmr_min,
            rmr_max=rmr_max,
            page=page,
            per_page=per_page,
        )
        return jsonify(resultado)

    except ValueError as e:
        return jsonify({"error": f"Parámetro inválido: {e}"}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@bp.route("/ventanas/<int:ventana_id>", methods=["GET"])
def api_detalle_ventana(ventana_id):
    """Detalle de ventana con discontinuidades calculadas."""
    try:
        resultado = obtener_detalle_ventana(ventana_id)
        if resultado is None:
            return jsonify({"error": "Ventana no encontrada"}), 404
        return jsonify(resultado)
    except Exception as e:
        return jsonify({"error": str(e)}), 500
