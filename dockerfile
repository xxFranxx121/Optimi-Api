# Imagen base de Python
FROM python:3.11-slim

# Evita preguntas en apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Instala dependencias del sistema, Chrome y Chromedriver
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    curl \
    gnupg \
    chromium \
    chromium-driver \
    && rm -rf /var/lib/apt/lists/*

# Configura variables de entorno
ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMEDRIVER_PATH=/usr/bin/chromedriver

# Crea el directorio del proyecto
WORKDIR /app

# Copia los archivos
COPY . .

# Instala dependencias del proyecto
RUN pip install --no-cache-dir -r requirements.txt

# Expone el puerto
EXPOSE 8000

# Comando para ejecutar FastAPI con Uvicorn
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"]

