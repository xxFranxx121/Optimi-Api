# Imagen base
FROM python:3.11-slim

# Evitar prompts interactivos
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias y Google Chrome estable
RUN apt-get update && apt-get install -y wget gnupg unzip fonts-liberation libx11-6 libxcomposite1 libxdamage1 libxrandr2 libgbm1 libgtk-3-0 libasound2 libnss3 libxss1 libxtst6 libdrm2 libxext6 libxfixes3 && \
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list' && \
    apt-get update && apt-get install -y google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# Variables de entorno
ENV CHROME_BIN=/usr/bin/google-chrome

# Copiar el proyecto
WORKDIR /app
COPY . .

# Instalar dependencias de Python
RUN pip install --no-cache-dir -r requirements.txt

# Exponer puerto
EXPOSE 8000

# Comando de ejecución
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"]


