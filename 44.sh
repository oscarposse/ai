#!/bin/bash

# Función para mostrar un mensaje de error y salir del script
error_exit() {
  echo "$1" >&2
  exit 1
}

# Función para comprobar si un comando está instalado
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Comprobar si yum está instalado
if ! command_exists yum; then
  error_exit "El comando yum no está instalado. Instálalo e inténtalo de nuevo."
fi

# Obtener la lista de versiones de JBoss instaladas
jboss_versions=$(rpm -qa | grep -i jboss)

# Comprobar si hay versiones de JBoss instaladas
if [ -z "$jboss_versions" ]; then
  echo "No se encontraron versiones de JBoss instaladas."
  exit 0
fi

# Mostrar las versiones de JBoss encontradas y las aplicaciones que utilizan cada una
echo "Versiones de JBoss encontradas:"
for version in $jboss_versions; do
  echo "$version:"
  rpm -ql "$version" | grep -i '.ear\|.war'
done

# Pedir al usuario que seleccione una versión para actualizar
read -rp "Selecciona la versión de JBoss que quieres actualizar: " selected_version
if ! rpm -qa | grep -qi "$selected_version"; then
  error_exit "La versión seleccionada no está instalada. Inténtalo de nuevo."
fi

# Hacer una copia de seguridad del directorio de instalación de JBoss
jboss_dir=$(rpm -ql "$selected_version" | head -n 1 | xargs dirname)
timestamp=$(date +%Y%m%d%H%M%S)
backup_file="/tmp/jboss_backup_${timestamp}.tar.gz"
tar czf "$backup_file" "$jboss_dir" || error_exit "Error al hacer la copia de seguridad de JBoss."

# Actualizar JBoss a la última versión disponible
echo "Actualizando JBoss a la última versión disponible..."
sudo yum update -y "$selected_version" || error_exit "Error al actualizar JBoss."

# Preguntar si se quieren instalar parches
read -rp "¿Quieres instalar parches para esta versión de JBoss? (S/N): " install_patches
if [ "${install_patches^^}" == "S" ]; then
  echo "Instalando parches para la versión $selected_version..."
  # Lógica para instalar parches aquí
fi

echo "El proceso de actualización se ha completado correctamente."
