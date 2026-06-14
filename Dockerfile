FROM python:3.10-slim

RUN apt-get update && apt-get install -y \
    curl apt-transport-https gnupg2 unixodbc-dev && \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg && \
    curl https://packages.microsoft.com/config/debian/12/prod.list > \
    /etc/apt/sources.list.d/mssql-release.list && \
    sed -i 's/^deb /deb [signed-by=\/usr\/share\/keyrings\/microsoft-prod.gpg] /' \
    /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 5000
CMD ["python3", "run.py"]