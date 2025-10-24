# Usamos una imagen base de Python
FROM python:3.10-slim

# Establecemos el directorio de trabajo
WORKDIR /app

# 1. Instalar dependencias del sistema y Google Chrome
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    gnupg \
    --no-install-recommends \
# Agregamos el repositorio de Google Chrome
&& wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
&& echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
# Instalamos Chrome
&& apt-get update \
&& apt-get install -y google-chrome-stable \
# Limpiamos la caché de apt
&& rm -rf /var/lib/apt/lists/*

# 2. Instalar el chromedriver que COINCIDA con la versión de Chrome
# Obtenemos la versión MAYOR de Chrome (ej. 123)
RUN CHROME_MAJOR_VERSION=$(google-chrome --product-version | cut -d . -f 1)
# Buscamos la última versión de chromedriver para esa versión mayor
RUN CD_VERSION=$(curl -sS https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_${CHROME_MAJOR_VERSION})
# Descargamos, descomprimimos y movemos chromedriver al PATH
RUN wget -q https://storage.googleapis.com/chrome-for-testing-public/$CD_VERSION/linux64/chromedriver-linux64.zip
RUN unzip chromedriver-linux64.zip
RUN mv chromedriver-linux64/chromedriver /usr/bin/chromedriver
RUN chmod +x /usr/bin/chromedriver
# Limpiamos los archivos de instalación
RUN rm -rf chromedriver-linux64.zip chromedriver-linux64

# 3. Instalar las dependencias de Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Copiar el código de tu aplicación
COPY api.py .

# 5. Comando para iniciar la aplicación
# Railway inyectará la variable $PORT automáticamente
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "$PORT"]

