# MoodleUPM_TOOL

Herramienta para automatizar la descarga masiva de recursos (apuntes, PDFs, materiales de curso) desde Moodle de la UPM, evitando tener que descargar archivo por archivo manualmente desde el navegador.

Incluye dos versiones equivalentes:

- **`MoodleUPMDownloader.sh`** — versión original en Bash.
- **`main.py`** — reescritura en Python, más robusta y fácil de mantener/extender.

## ¿Qué hace?

1. El usuario selecciona qué curso(s) de Moodle quiere descargar.
2. La herramienta recorre esos cursos y descarga automáticamente todos los recursos disponibles (documentos, presentaciones, PDFs, etc.).
3. Los archivos se guardan localmente, evitando la descarga manual recurso por recurso.

## Autenticación

Moodle UPM no permite autenticación automatizada sencilla (login + contraseña por script), así que la herramienta usa la **cookie de sesión** de un navegador donde ya se ha iniciado sesión manualmente:

1. Inicia sesión normalmente en Moodle desde tu navegador.
2. Extrae la cookie de sesión (por ejemplo, desde las herramientas de desarrollador del navegador).
3. Pega esa cookie en la configuración del script.
4. Ejecuta la herramienta — usará esa sesión para autenticar las peticiones de descarga.

> **Nota:** la cookie es personal e intransferible — equivale a tu sesión iniciada. No la compartas ni la subas a ningún repositorio público.

## Uso

### Versión Python (recomendada)

```bash
python main.py
```

Sigue las instrucciones interactivas para indicar la cookie de sesión y seleccionar los cursos a descargar.

### Versión Bash

```bash
chmod +x MoodleUPMDownloader.sh
./MoodleUPMDownloader.sh
```

También puede ejecutarse en Windows mediante PowerShell/WSL.

## Motivación

Este proyecto nació de la necesidad práctica de descargar grandes volúmenes de material de varias asignaturas sin tener que hacerlo manualmente recurso por recurso desde la interfaz web de Moodle, ahorrando tiempo en tareas repetitivas durante el curso.

## Aviso de uso responsable

Esta herramienta está pensada para uso personal sobre cursos a los que el propio usuario tiene acceso legítimo como estudiante matriculado. No está diseñada ni debe usarse para acceder a contenido no autorizado.

## Licencia

MIT
