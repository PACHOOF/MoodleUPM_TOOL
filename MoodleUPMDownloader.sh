#!/bin/bash
#2vrj28udq4tbn4767katgioco6

#encontrar paginas CON EL NOMBRE y dar a elegir cual descargar


pagina_ppal="https://moodle.upm.es/titulaciones/oficiales/my/"
pagina_curso="https://moodle.upm.es/titulaciones/oficiales/course/view.php?id="
cookie=$1
cabecera_general="https://moodle.upm.es/titulaciones/oficiales/mod/resource/view.php?id="



echo -e "\n[+] Descargando Pagina Fuente...\n"
curl -L -b "MoodleSessionofi2526=${cookie}" ${pagina_ppal} -o source_ppal.html 2>/dev/null
#curl -L -b "MoodleSessionofi2526=${cookie}" ${pagina_concurrencia} -o source.html 2>/dev/null

mapfile -t courseid_lista < <(xmllint --html --xpath '//section[@id="inst159348"]//select[@name="course"]/option' source_ppal.html |grep -oP '<option value="\K[^"]+')
mapfile -t coursename_lista < <(xmllint --html --xpath '//section[@id="inst159348"]//select[@name="course"]/option' source_ppal.html | grep -oP '<option value="[^"]+">\K[^<]+')

echo -e "\n[+] CURSOS DISPONIBLES:\n"
for i in $(seq 0 ${#coursename_lista[@]});do
  echo -e "  [${i}] ${coursename_lista[${i}]}\n"
done
 
echo -e -n "\n[+] Selecciona los cursos a descargar: "
read cursos_elegidos
cursos_elegidos_SANT=$(echo ${cursos_elegidos} | tr -d ' ' | sed 's/,/ /g' | sed 's/ /\n/g' | sort -u)

for j in ${cursos_elegidos_SANT}; do 
  curl -L -b "MoodleSessionofi2526=${cookie}" "${pagina_curso}${courseid_lista[${j}]}" -o source.html 2>/dev/null

  #TIENEN QUE TENER SECTIONNAME
  dataid_secciones=$(xmllint --html --xpath '//li[@data-sectionname]/@data-id' source.html 2>/dev/null | sort -u | grep -oP 'data-id="\K\d+')
  dataid_recursos=$(xmllint --html --xpath '//li[@data-sectionname]//li/@data-id' source.html 2>/dev/null | sort -u | grep -oP 'data-id="\K\d+')
  #dataid_section=$(grep -A 10 -i 'id="section-1"' source.html | grep -oP 'data-id="\K\d+')
  #dataid_lista=$(xmllint --html --xpath '//li[@id="section-1"]//@data-id' source.html 2>/dev/null | sort -u | grep -oP 'data-id="\K\d+' | grep -v "^${dataid_section}$")
  
  file_url_lista=()
  file_name_lista=()

  for dataid in ${dataid_recursos}; do 
    echo -ne "  [*] Extrayendo archivo con id=${dataid}..."
    curl -L -b "MoodleSessionofi2526=${cookie}" "${cabecera_general}${dataid}" -o source_end.html 2>/dev/null
    sleep 0.25

    file_url=$(xmllint --html --xpath '//div[@id="region-main-box"]//div[@role="main"]//@href' source_end.html | grep -oP 'href="\K[^"]+')
    file_name=$(basename ${file_url})
    
    if [ ${file_name} != "invalidcoursemodule" ];then
      file_url_lista+=(${file_url})
      file_name_lista+=(${file_name})
      echo -ne "\r  [+] Archivo \033[1m${file_name}\033[0m encontrado\n"
    else 
      echo -ne "\r\033[K"
    fi
    sleep 0.25
  done
  
  echo -ne "\nPulse cualquier tecla para continuar: "
  read continuacion

  for n in "${!file_name_lista[@]}";do
    echo -ne "\n  [*] Descargando Archivo ${file_name_lista[$n]}..."
    echo "${file_url_lista[$n]}"
    curl -L -b "MoodleSessionofi2526=${cookie}" "${file_url_lista[$n]}" -o "${file_name_lista[$n]}" 2>/dev/null
    sleep 0.25
    echo -ne "\r  [+] Descarga finalizada -> ${file_name_lista[$n]}"
  done
done
