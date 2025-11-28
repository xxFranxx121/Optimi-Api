# Usamos una imagen base de Python
FROM python:3.10-slim

# Establecemos el directorio de trabajo
WORKDIR /app

# 1. Instalar dependencias CRUCIALES y Chrome (Método moderno)
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    gnupg \
    libgbm-dev \
    libnss3 \
    libfontconfig1 \
    libxcomposite1 \
    libxrandr2 \
    libxcursor1 \
    libxi6 \
    libxtst6 \
    --no-install-recommends \
    # Descargar la llave y guardarla en un keyring seguro (el reemplazo de apt-key)
    && wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
    # Agregar el repositorio referenciando al keyring
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    # Instalar Chrome
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    # Limpiar
    && rm -rf /var/lib/apt/lists/*

# 2. Instalar el chromedriver coincidente
# NOTA: Los paths /usr/bin/google-chrome y /usr/bin/chromedriver coinciden con tu api.py
RUN export CHROME_MAJOR_VERSION=$(google-chrome --product-version | cut -d . -f 1) \
    # Usamos wget -qO- en lugar de curl -sS
    && export CD_VERSION=$(wget -qO- https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_${CHROME_MAJOR_VERSION}) \
    && wget -q https://storage.googleapis.com/chrome-for-testing-public/$CD_VERSION/linux64/chromedriver-linux64.zip \
    && unzip chromedriver-linux64.zip \
    && mv chromedriver-linux64/chromedriver /usr/bin/chromedriver \
    && chmod +x /usr/bin/chromedriver \
    && rm -rf chromedriver-linux64.zip chromedriver-linux64

# 3. Instalar las dependencias de Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Copiar el código de tu aplicación
COPY api.py .

# 5. Comando para iniciar la aplicación
CMD ["sh", "-c", "uvicorn api:app --host 0.0.0.0 --port $PORT"]






