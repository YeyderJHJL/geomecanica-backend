FROM python:3.10-bookworm

# Microsoft ODBC Driver 18 for SQL Server (pyodbc dependency).
# Usa el paquete oficial packages-microsoft-prod.deb que registra el repo
# y la clave GPG correctamente, sin manipular sources.list a mano.
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl gnupg ca-certificates apt-transport-https unixodbc-dev && \
    curl -fsSL -O https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000
CMD ["python3", "run.py"]
