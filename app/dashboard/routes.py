from flask import Blueprint, request, jsonify

from app.dashboard.service import obtener_stats_dashboard

bp = Blueprint("dashboard", __name__)


@bp.route("/dashboard", methods=["GET"])
def api_dashboard():
    """Estadísticas agregadas de RMR para gráficos del dashboard."""
    sector   = request.args.get("sector", "").strip() or None
    campania = request.args.get("campania", "").strip() or None

    try:
        datos = obtener_stats_dashboard(sector=sector, campania=campania)
        return jsonify(datos)
    except Exception as e:
        return jsonify({"error": str(e), "tipo": type(e).__name__}), 500
