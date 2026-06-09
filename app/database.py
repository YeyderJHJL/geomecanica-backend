import os


def get_connection():
    """Crea y devuelve una conexión pyodbc a SQL Server leyendo credenciales del entorno."""
    try:
        import pyodbc
    except ImportError:
        raise RuntimeError("pyodbc no está instalado. Ejecuta: pip install pyodbc")

    server   = os.environ["DB_SERVER"]
    database = os.environ["DB_DATABASE"]
    username = os.environ.get("DB_USER") or None
    password = os.environ.get("DB_PASSWORD") or None
    driver   = os.environ.get("DB_DRIVER", "ODBC Driver 17 for SQL Server")

    if username:
        conn_str = (
            f"DRIVER={{{driver}}};"
            f"SERVER={server};"
            f"DATABASE={database};"
            f"UID={username};"
            f"PWD={password};"
            "TrustServerCertificate=yes;"
        )
    else:
        conn_str = (
            f"DRIVER={{{driver}}};"
            f"SERVER={server};"
            f"DATABASE={database};"
            "Trusted_Connection=yes;"
            "TrustServerCertificate=yes;"
        )

    return pyodbc.connect(conn_str, timeout=30)
