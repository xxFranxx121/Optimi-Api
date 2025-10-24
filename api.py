from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import traceback

from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time, os

app = FastAPI(title="Laboratorio API", description="Extrae resultados por DNI", version="1.0")

# --- Modelo de entrada ---
class DatosEntrada(BaseModel):
    usuario: str
    password: str
    dni: str


def make_driver():
    options = Options()
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")
    options.add_argument("--disable-extensions")
    options.add_argument("--window-size=1920,1080")
    options.binary_location = os.getenv("CHROME_BIN", "/usr/bin/google-chrome")

    # Selenium Manager se encarga de conseguir el driver correcto automáticamente
    driver = webdriver.Chrome(options=options)
    return driver


def login(driver, wait, usuario, password):
    driver.get("https://coobiselab.optimihub.com.ar")
    wait.until(EC.visibility_of_element_located((By.ID, "username"))).send_keys(usuario)
    driver.find_element(By.ID, "floatingPassword").send_keys(password)
    driver.find_element(By.XPATH, '//button[contains(.,"Acceder")]').click()
    wait.until(EC.visibility_of_element_located((By.ID, "desde")))


def filtrar_por_fecha(wait):
    hoy = time.strftime("%d/%m/%Y")
    hace30 = time.strftime("%d/%m/%Y", time.localtime(time.time() - 30 * 86400))
    fdesde = wait.until(EC.element_to_be_clickable((By.ID, "desde")))
    fdesde.clear()
    fdesde.send_keys(hace30, Keys.TAB)
    fhasta = wait.until(EC.element_to_be_clickable((By.ID, "hasta")))
    fhasta.clear()
    fhasta.send_keys(hoy, Keys.TAB)


def buscar_paciente(driver, wait, dni) -> str:
    inp = wait.until(EC.element_to_be_clickable((By.CSS_SELECTOR, "input.p-autocomplete-input")))
    inp.clear()
    inp.send_keys(dni)
    wait.until(EC.element_to_be_clickable((By.CSS_SELECTOR, "li.p-autocomplete-item"))).click()

    valor = inp.get_attribute("value")
    nombre = valor.split(" - ", 1)[1].strip() if " - " in valor else "<sin nombre>"

    wait.until(EC.element_to_be_clickable((
        By.XPATH,
        "//span[contains(@class,'mdc-button__label') and normalize-space()='Buscar']/ancestor::button[1]"
    ))).click()

    wait.until(EC.element_to_be_clickable((By.CSS_SELECTOR, "div.ag-center-cols-container div[role='row']"))).click()
    wait.until(lambda d: len(d.find_elements(By.CSS_SELECTOR, "div.ag-center-cols-container")) >= 2)
    grids = driver.find_elements(By.CSS_SELECTOR, "div.ag-center-cols-container")
    muestras = grids[1]
    wait.until(lambda d: len(muestras.find_elements(By.CSS_SELECTOR, "div[role='row']")) > 0)
    muestras.find_elements(By.CSS_SELECTOR, "div[role='row']")[0].click()

    return nombre


def extraer_resultados(driver, wait):
    wait.until(lambda d: len(d.find_elements(By.CSS_SELECTOR, "div.ag-center-cols-container")) >= 3)
    grids = driver.find_elements(By.CSS_SELECTOR, "div.ag-center-cols-container")
    resg = grids[2]
    wait.until(lambda d: len(resg.find_elements(By.CSS_SELECTOR, "div[role='row']")) > 0)

    out = []
    for fila in resg.find_elements(By.CSS_SELECTOR, "div[role='row']"):
        c = fila.find_elements(By.CSS_SELECTOR, "div[role='gridcell']")
        if len(c) < 3:
            continue
        practica = c[1].text.strip()
        resultado = c[2].text.strip()
        out.append({"practica": practica, "resultado": resultado})
    return out


@app.post("/resultados")
def obtener_resultados(datos: DatosEntrada):
    driver = make_driver()
    wait = WebDriverWait(driver, 15)
    try:
        login(driver, wait, datos.usuario, datos.password)
        filtrar_por_fecha(wait)
        nombre = buscar_paciente(driver, wait, datos.dni)
        resultados = extraer_resultados(driver, wait)
        return {"nombre": nombre, "resultados": resultados}
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        driver.quit()
