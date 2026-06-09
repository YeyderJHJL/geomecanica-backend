from flask import Blueprint, request, jsonify

from app.importacion.service import importar_excel

bp = Blueprint("importacion", __name__)


@bp.route("/importar_excel", methods=["POST"])
def api_importar_excel():
    """
    Recibe un archivo Excel multipart (campo 'archivo') e inserta las filas
    en ventanas_final. Devuelve {insertados, errores, detalle_errores}.
    """
    if "archivo" not in request.files:
        return jsonify({"error": "Se requiere un archivo en el campo 'archivo'"}), 400

    archivo = request.files["archivo"]
    if not archivo.filename:
        return jsonify({"error": "El archivo no tiene nombre"}), 400

    nombre = archivo.filename.lower()
    if not (nombre.endswith(".xlsx") or nombre.endswith(".xls")):
        return jsonify({"error": "Solo se aceptan archivos .xlsx o .xls"}), 400

    try:
        reporte = importar_excel(archivo.stream)
        return jsonify(reporte)
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500
