# Diseño de la API de Inscripciones

Grupo: ______________________________

## Paso 1 — Recursos

Un recurso es un **sustantivo** que la API expone con su propia URI.
La fila de *Curso* ya está hecha como ejemplo.

| Recurso     | URI de la colección      | Atributos clave                                 | Se relaciona con    |
|-------------|--------------------------|-------------------------------------------------|---------------------|
| Curso       | `/cursos`                | codigo, nombre, cupos, prerrequisitos           | Inscripción         |
| Estudiante  | `/estudiantes`           | id, nombre, aprobados                            | Inscripción         |
| Inscripción | `/inscripciones`         | id, estudiante_id, curso_codigo, estado, creada_en | Estudiante, Curso |

**Pregunta:** "inscribir" es un verbo. ¿Por qué en REST lo modelamos como el
recurso *Inscripción* y no como una URI `/inscribir`?

> Respuesta: En REST las URIs nombran recursos (sustantivos) y el verbo lo da el
> método HTTP. `/inscribir` sería una acción suelta: no se podría consultar,
> listar ni cancelar después. Al modelar la *Inscripción* como recurso, inscribir
> es `POST /inscripciones` (crea el recurso), consultarla es `GET /inscripciones/{id}`
> y cancelarla es `PATCH /inscripciones/{id}`. Así la inscripción tiene identidad,
> estado e historial propios, y toda su vida se maneja con los métodos HTTP sobre
> la misma URI. Además es el recurso que **relaciona** a un Estudiante con un Curso,
> y donde viven los datos de esa relación (estado, fecha). Los cupos se guardan en
> el Curso y los cursos aprobados en el Estudiante.

## Paso 2 — Contrato: los 5 endpoints

Completa el código de éxito y los errores posibles de cada endpoint.
Pistas: crear → `201`; no existe → `404`; choca con una regla de negocio → `409`.

| # | Método | URI                                      | Cuerpo que recibe     | Éxito | Errores |
|---|--------|------------------------------------------|-----------------------|-------|---------|
| 1 | GET    | `/cursos`                                | —                     | 200   | —       |
| 2 | POST   | `/inscripciones`                         | `InscripcionCrear`    | 201   | 404 (estudiante o curso no existe); 409 (DUPLICADA, PRERREQUISITOS_PENDIENTES o SIN_CUPO) |
| 3 | GET    | `/inscripciones/{inscripcion_id}`        | —                     | 200   | 404 (inscripción no existe) |
| 4 | GET    | `/estudiantes/{estudiante_id}/inscripciones` | —                 | 200   | 404 (estudiante no existe) |
| 5 | PATCH  | `/inscripciones/{inscripcion_id}`        | `CambioEstado`        | 200   | 404 (inscripción no existe); 409 (TRANSICION_INVALIDA) |

## Paso 3 — Estados de una inscripción

```
   POST /inscripciones            PATCH {"estado": "CANCELADA"}
  ─────────────────────▶  ACTIVA  ──────────────────────────────▶  CANCELADA
```

**Pregunta:** ¿Qué debe responder la API si alguien intenta cancelar una
inscripción que ya está CANCELADA? ¿Por qué?

> Respuesta:
