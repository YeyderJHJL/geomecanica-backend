import os
from pathlib import Path

from dotenv import load_dotenv
from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS

from app.database import get_connection


def create_app():
    load_dotenv(Path(__file__).parent.parent / ".env")

    app = Flask(
        __name__,
        static_folder=str(Path(__file__).parent.parent / "dist"),
        static_url_path="",
    )
    app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", "dev-secret-key")

    CORS(app, resources={r"/*": {"origins": "*"}})

    # ── Blueprints ────────────────────────────────────────────────────────────
    from app.ventanas.routes   import bp as ventanas_bp
    from app.importacion.routes import bp as importacion_bp
    from app.dashboard.routes  import bp as dashboard_bp

    app.register_blueprint(ventanas_bp)
    app.register_blueprint(importacion_bp)
    app.register_blueprint(dashboard_bp)

    # ── Health ────────────────────────────────────────────────────────────────
    @app.route("/health")
    def health_db():
        db_ok = False
        db_msg = ""
        try:
            conn = get_connection()
            conn.close()
            db_ok  = True
            db_msg = "Conexión exitosa"
        except Exception as e:
            db_msg = str(e)

        return jsonify({
            "status":       "ok",
            "db_connected": db_ok,
            "db_message":   db_msg,
            "server":       os.environ.get("DB_SERVER",   "(no configurado)"),
            "database":     os.environ.get("DB_DATABASE", "(no configurado)"),
        })

    # ── Sirve el frontend React (dist/) en cualquier ruta no-API ─────────────
    @app.route("/", defaults={"path": ""})
    @app.route("/<path:path>")
    def serve_frontend(path):
        dist = Path(__file__).parent.parent / "dist"
        target = dist / path
        if path and target.is_file():
            return send_from_directory(str(dist), path)
        index = dist / "index.html"
        if index.exists():
            return send_from_directory(str(dist), "index.html")
        return jsonify({"error": "Frontend no encontrado. Ejecuta: pnpm build"}), 404

    return app
