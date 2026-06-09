import os


class Config:
    DB_SERVER   = os.environ.get("DB_SERVER", "localhost")
    DB_DATABASE = os.environ.get("DB_DATABASE", "BBDD_Geoteknia")
    DB_USER     = os.environ.get("DB_USER", "")
    DB_PASSWORD = os.environ.get("DB_PASSWORD", "")
    DB_DRIVER   = os.environ.get("DB_DRIVER", "ODBC Driver 17 for SQL Server")
    SECRET_KEY  = os.environ.get("SECRET_KEY", "dev-secret-key-change-in-production")
    DEBUG       = os.environ.get("FLASK_DEBUG", "0") == "1"
