# Paso 6 — Cliente HTTP

Prueba de la API desde fuera, por HTTP. Aquí hay dos formas de ejecutar la
secuencia de 9 peticiones del enunciado; usa la que prefieras.

## Archivos

- `inscripciones.postman_collection.json` — colección para **Postman** (o Insomnia,
  que también la importa). Trae las 9 peticiones en orden, dos variables
  (`base_url` y `inscripcion_id`) y un test por petición que verifica el código de
  respuesta y el `detail`/`estado` esperado.
- `probar_api.ps1` — el mismo recorrido como **script de PowerShell**, por si no
  quieres abrir Postman. Imprime OK/FALLO por cada verificación.
- `resultados.png` — **(pendiente: agrégala tú)** captura con los resultados.

## Cómo probar con Postman

1. Levanta la API y déjala corriendo (los datos están en memoria, así que
   arranca limpia):

       python -m uvicorn app.main:app

2. En Postman: *Import* → elige `inscripciones.postman_collection.json`.
3. Abre la colección → botón *Run* (Collection Runner) → *Run*.
4. Deben pasar las 9 peticiones con sus tests en verde.
5. Toma una captura de los resultados y guárdala aquí como `resultados.png`.

> La variable `base_url` vale `http://127.0.0.1:8000`. Si corres la API en otro
> puerto (p. ej. 8001), cámbiala en la pestaña *Variables* de la colección.
> Si usas Postman, abre la versión de escritorio: la web no llega a 127.0.0.1.

## Cómo probar con PowerShell

Con la API corriendo:

    powershell -ExecutionPolicy Bypass -File cliente-http\probar_api.ps1

La URL base está en la variable `$baseUrl` dentro del script (cámbiala si usas
otro puerto). Al final imprime "TODAS LAS PRUEBAS PASARON" si todo está bien.

## Secuencia (tabla del enunciado)

| # | Petición                              | Esperado                        |
|---|---------------------------------------|---------------------------------|
| 1 | POST inscribir e1 en IS2              | 201                             |
| 2 | POST inscribir e1 en IS2 otra vez     | 409 DUPLICADA                   |
| 3 | POST inscribir e4 en IS2              | 409 PRERREQUISITOS_PENDIENTES   |
| 4 | POST inscribir e2 en IS2              | 201                             |
| 5 | POST inscribir e3 en IS2              | 409 SIN_CUPO                    |
| 6 | GET /inscripciones/{id}               | 200                             |
| 7 | GET /estudiantes/e1/inscripciones     | 200                             |
| 8 | PATCH /inscripciones/{id} a CANCELADA | 200                             |
| 9 | GET /cursos                           | 200, IS2 con 1 cupo disponible  |
