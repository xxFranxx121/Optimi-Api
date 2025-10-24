# Dockerfile - basado en ubuntu para mayor compatibilidad
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Actualizar e instalar utilidades y dependencias necesarias para Chrome
RUN apt-get update && apt-get install -y \
    wget \
    gnupg2 \
    unzip \
    ca-certificates \
    fonts-liberation \
    libx11-6 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxss1 \
    libxtst6 \
    lsb-release \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Instala Google Chrome estable (key + repo)
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list' && \
    apt-get update && apt-get install -y google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# Descarga Chrome-for-Testing matching driver (más robusto)
RUN CHROME_VER=$(google-chrome --version | awk '{print $3}' | cut -d'.' -f1) && \
    DRIVER_TAG=$(wget -qO- "https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_$CHROME_VER") && \
    wget -q "https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/$DRIVER_TAG/linux64/chromedriver-linux64.zip" -O /tmp/chromedriver.zip && \
    unzip /tmp/chromedriver.zip -d /tmp && \
    mv /tmp/chromedriver/chromedriver /usr/local/bin/chromedriver && chmod +x /usr/local/bin/chromedriver && \
    rm -rf /tmp/chromedriver* /tmp/chromedriver.zip

# Variables de entorno para las rutas
ENV CHROME_BIN=/usr/bin/google-chrome
ENV CHROMEDRIVER_PATH=/usr/local/bin/chromedriver
ENV PYTHONUNBUFFERED=1

# Copiar proyecto
WORKDIR /app
COPY . /app

# Instalar dependencias Python desde requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

# Expone puerto
EXPOSE 8000

# Comando por defecto
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"]


