from flask import Blueprint, jsonify

from app.catalogos.service import obtener_catalogos

catalogos_bp = Blueprint("catalogos", __name__)


@catalogos_bp.route("/catalogos", methods=["GET"])
def get_catalogos():
    try:
        return jsonify(obtener_catalogos())
    except Exception as e:
        return jsonify({"error": str(e), "tipo": type(e).__name__}), 500
