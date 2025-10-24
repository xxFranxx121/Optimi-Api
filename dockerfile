# Imagen oficial de Selenium con Chrome y Chromedriver ya instalados
FROM selenium/standalone-chrome:127.0

# Instalar dependencias Python
USER root
RUN apt-get update && apt-get install -y python3 python3-pip && rm -rf /var/lib/apt/lists/*

# Configuración de entorno
ENV PYTHONUNBUFFERED=1
ENV CHROME_BIN=/opt/google/chrome/google-chrome
ENV CHROMEDRIVER_PATH=/usr/bin/chromedriver

WORKDIR /app
COPY . /app

# Instalar dependencias Python
RUN pip3 install --no-cache-dir -r requirements.txt

EXPOSE 8000

CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"]



