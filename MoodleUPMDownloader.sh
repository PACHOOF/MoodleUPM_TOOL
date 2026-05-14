#!/bin/bash
pagina_ppal="https://moodle.upm.es/titulaciones/oficiales/my/"
pagina_curso="https://moodle.upm.es/titulaciones/oficiales/course/view.php?id="
cookie=$1
cabecera_general="https://moodle.upm.es/titulaciones/oficiales/mod/resource/view.php?id="



echo -e "\n\033[1m[+]\033[0m Descargando Pagina Fuente...\n"
curl -L -b "MoodleSessionofi2526=${cookie}" ${pagina_ppal} -o source_ppal.html 2>/dev/null

mapfile -t courseid_lista < <(xmllint --html --xpath '//section[@id="inst159348"]//select[@name="course"]/option' source_ppal.html 2>/dev/null |grep -oP '<option value="\K[^"]+')
mapfile -t coursename_lista < <(xmllint --html --xpath '//section[@id="inst159348"]//select[@name="course"]/option' source_ppal.html 2>/dev/null | grep -oP '<option value="[^"]+">\K[^<]+')

echo -e "\n\033[1m[+]\033[0m CURSOS DISPONIBLES:\n"
for i in $(seq 0 ${#coursename_lista[@]});do
  echo -e "  \033[1m[${i}]\033[0m ${coursename_lista[${i}]}\n"
done
 
echo -e -n "\n\033[1m[+]\033[0m Selecciona los cursos a descargar: "
read cursos_elegidos
cursos_elegidos_SANT=$(echo ${cursos_elegidos} | tr -d ' ' | sed 's/,/ /g' | sed 's/ /\n/g' | sort -u)
echo ""

for j in ${cursos_elegidos_SANT}; do
  echo -e "\033[1m[+]\033[0m Curso \033[1m${coursename_lista[$j]}\033[0m:\n"

  mkdir -p "${coursename_lista[$j]}" # Crear carpeta donde meter el contenido de cada curso

  curl -L -b "MoodleSessionofi2526=${cookie}" "${pagina_curso}${courseid_lista[${j}]}" -o source.html 2>/dev/null

  #TIENEN QUE TENER SECTIONNAME
  mapfile -t dataid_secciones < <(xmllint --html --xpath '//li[@data-sectionname]/@data-id' source.html 2>/dev/null | grep -oP 'data-id="\K\d+')
  mapfile -t datasectionname_secciones < <(xmllint --html --xpath '//li[@data-sectionname]/@data-sectionname' source.html 2>/dev/null | grep -oP 'data-sectionname="\K[^"]+')

  # [!] ITERAR SOBRE CADA DATAID Y BUSCAR LOS RECURSOS POR CADA SECCION
  file_url_lista=()
  file_name_lista=()
  file_section_lista=()

  for m in ${!dataid_secciones[@]}; do
    dataid_recursos=$(xmllint --html --xpath "//li[@data-id=${dataid_secciones[$m]}]//li/@data-id" source.html 2>/dev/null | sort -u | grep -oP 'data-id="\K\d+')

    if [ -n "${dataid_recursos}" ]; then
      mkdir -p "${coursename_lista[$j]}/${datasectionname_secciones[$m]}"

      for dataid in ${dataid_recursos}; do 
        echo -ne "  \033[1m[*]\033[0m Extrayendo archivo con id=${dataid}..."
        curl -L -b "MoodleSessionofi2526=${cookie}" "${cabecera_general}${dataid}" -o source_end.html 2>/dev/null
        sleep 0.1

        file_url=$(xmllint --html --xpath '//div[@id="region-main-box"]//div[@role="main"]//@href' source_end.html 2>/dev/null | grep -oP 'href="\K[^"]+')
        file_name=$(basename "${file_url}")
    
        if [ "${file_name}" != "invalidcoursemodule" ];then
          file_url_lista+=("${file_url}")
          file_name_lista+=("${file_name}")
	  file_section_lista+=("${datasectionname_secciones[$m]}")
          echo -ne "\r  \033[1m[+]\033[0m Archivo \033[1m${file_name}\033[0m encontrado\n"
        else 
          echo -ne "\r\033[K"
        fi
        sleep 0.1
      done
    fi
  done

  echo -ne "\n\033[1m[>]\033[0m Pulse \033[1mENTER\033[0m para continuar"
  read continuacion
 
  for n in "${!file_name_lista[@]}";do
    echo -ne "\n  \033[1m[*]\033[0m Descargando Archivo \033[1m${file_name_lista[$n]}\033[0m..."
    curl -L -b "MoodleSessionofi2526=${cookie}" "${file_url_lista[$n]}" -o "${file_name_lista[$n]}" 2>/dev/null
    mv "${file_name_lista[$n]}" "${coursename_lista[$j]}/${file_section_lista[$n]}/"
    sleep 0.1
    echo -ne "\r  \033[1m[+]\033[0m Descarga finalizada -> \033[1m${coursename_lista[$j]}/${file_section_lista[$n]}/${file_name_lista[$n]}\033[0m"
  done
  echo -e "\n\033[1m  [+] ${coursename_lista[$j]}\033[0m descargado correctamente\n"
done

rm source.html source_end.html source_ppal.html 2>/dev/null
