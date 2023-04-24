#!/bin/bash

# Función para mostrar el menú de versiones y obtener la selección del usuario
function show_menu() {
  echo "Seleccione la versión que desea actualizar:"
  select version_choice in "${versions[@]}"; do
    if [[ " ${versions[@]} " =~ " ${version_choice} " ]]; then
      echo "Ha seleccionado la versión $version_choice."
      break
    else
      echo "Opción inválida. Seleccione una opción válida."
    fi
  done
}

# Función para realizar el backup
function do_backup() {
  backup_file="$1.bak.$(date +%Y%m%d%H%M%S)"
  echo "Creando archivo de backup $backup_file..."
  cp "$1" "$backup_file"
  echo "El archivo de backup $backup_file ha sido creado."
}

# Obtener la lista de versiones instaladas
versions=($(rpm -qa | grep "jboss-eap"))

# Mostrar las versiones encontradas y las aplicaciones que usa cada una
echo "Las siguientes versiones de JBoss están instaladas:"
for version in "${versions[@]}"; do
  echo "- $version"
  echo "  Aplicaciones que usan esta versión:"
  rpm -q --whatrequires "$version"
done

# Mostrar el menú de selección de versiones y obtener la selección del usuario
show_menu

# Realizar backup antes de actualizar
echo "Realizando backup antes de actualizar..."
do_backup "$version_choice"

# Instalar la siguiente versión disponible
echo "Actualizando a la siguiente versión disponible..."
sudo yum update "$version_choice" -y

# Preguntar si desea instalar parches
read -rp "¿Desea instalar parches? (S/n): " install_patches
if [[ "$install_patches" =~ ^[Ss]$ ]]; then
  echo "Instalando parches..."
  sudo yum update --security -y
else
  echo "Parches no instalados."
fi

echo "La actualización ha finalizado."
