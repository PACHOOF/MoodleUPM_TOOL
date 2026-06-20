from urllib.parse import unquote
from rich.console import Console
from rich.progress import Progress, BarColumn, DownloadColumn, TransferSpeedColumn, TimeRemainingColumn
from rich.panel import Panel
from rich.text import Text
import requests
from bs4 import BeautifulSoup
import os
import sys
import argparse

#0,1,2,3,4,5,6,7,8,9,10,11,12,13,14

parser = argparse.ArgumentParser(description="Moodle UPM Downloader")
parser.add_argument("cookie", help="Valor de la cookie MoodleSessionofi2526")
parser.add_argument("--all", action="store_true", dest="download_all", help="Descargar todos los cursos sin interacción")
parser.add_argument("-o", "--output", default="descargas", help="Carpeta de destino (por defecto: descargas)")
parser.add_argument("-c", "--course", type=int, help="Índice del curso a descargar directamente")
args = parser.parse_args()

console = Console()

def clean_dirname(name):
    name = BeautifulSoup(name, "html.parser").get_text()
    for char in ['/', '\\', ':', '*', '?', '"', '<', '>', '|']:
        name = name.replace(char, '')
    print("[TRAZA]"+name)
    return name.strip()

url = "https://moodle.upm.es/titulaciones/oficiales/my/"
url_curso = "https://moodle.upm.es/titulaciones/oficiales/course/view.php?id="
url_general = "https://moodle.upm.es/titulaciones/oficiales/mod/resource/view.php?id="

session = requests.Session()
session.headers.update({
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
})

c_name = "MoodleSessionofi2526"
c_value = sys.argv[1]
c_domain = "moodle.upm.es"
session.cookies.set(c_name, c_value, domain=c_domain)

console.print(Panel("[bold cyan]Moodle Downloader[/bold cyan]\n[dim]UPM · Titulaciones Oficiales[/dim]", expand=False))

with console.status("[cyan]Conectando a Moodle...[/cyan]"):
    r = session.get(url, allow_redirects=True)
    soup = BeautifulSoup(r.text, "html.parser")

section = soup.find("section", id="inst159348")
courses = section.find("select", {"name": "course"}).find_all("option")
courses = [c for c in courses if c.get("value") != "1" and c.text != "Ayuda y documentación para estudiantes"]

console.print("\n[bold green]Cursos disponibles:[/bold green]")
for i, course in enumerate(courses):
    console.print(f"  [cyan][{i}][/cyan] {course.text}")

sel_courses_NoSant = console.input("\n[bold yellow]>[/bold yellow] Selecciona los cursos a descargar: ")
sel_courses = [int(id_c) for id_c in sel_courses_NoSant.split(',')]

for id_c in sel_courses:
    console.print(f"\n[bold magenta]━━━ {courses[id_c].text} ━━━[/bold magenta]")

    with console.status(f"[cyan]Cargando secciones...[/cyan]"):
        r_sections = session.get(url_curso + courses[id_c].get("value"))
        soup_sections = BeautifulSoup(r_sections.text, "html.parser")

    course_name = clean_dirname(soup_sections.find("div", {"class": "page-header-headings"}).find("h1").text)
    os.makedirs(course_name, exist_ok=True)

    sections = soup_sections.find_all("li", attrs={"data-sectionname": True})

    for s in sections:
        resources = soup_sections.find("li", attrs={"data-id": s.get("data-id")}).find_all("li", attrs={"data-id": True})

        if not resources:
            continue

        section_name = clean_dirname(s.get("data-sectionname"))
        dir_path = course_name + "/" + section_name
        os.makedirs(dir_path, exist_ok=True)

        console.print(f"\n  [bold blue]📁 {section_name}[/bold blue]")

        for resource in resources:
            r_resource = session.get(url_general + resource.get("data-id"))
            soup_resource = BeautifulSoup(r_resource.text, "html.parser")

            try:
                file_url = soup_resource.find("div", {"id": "region-main-box"}).find("div", {"role": "main"}).find("a").get("href")
                r_file = session.get(file_url, stream=True, allow_redirects=True)
                real_url = r_file.url  # URL final tras los redirects
                file_name = unquote(os.path.basename(real_url.split("?")[0]))  # quita parámetros GET
            except:
                continue

            if file_name == "invalidcoursemodule":
                continue

            file_path = dir_path + "/" + file_name

            r_file = session.get(file_url, stream=True)
            total = int(r_file.headers.get("content-length", 0))

            with Progress(
                "[cyan]{task.description}[/cyan]",
                BarColumn(bar_width=30),
                DownloadColumn(),
                TransferSpeedColumn(),
                TimeRemainingColumn(),
                console=console,
                transient=True
            ) as progress:
                task = progress.add_task(f"  {file_name[:40]}", total=total)
                with open(file_path, "wb") as f:
                    for chunk in r_file.iter_content(chunk_size=8192):
                        f.write(chunk)
                        progress.update(task, advance=len(chunk))

            console.print(f"    [green]✓[/green] {file_name}")

console.print(f"\n[bold green]✓ Descarga completada[/bold green]")