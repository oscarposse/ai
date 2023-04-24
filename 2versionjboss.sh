#!/bin/bash

# Función para preguntar si se desean instalar parches
ask_install_patches() {
    while true; do
        read -p "¿Desea instalar los últimos parches de JBoss? (s/n): " choice
        case "$choice" in
            s|S ) return 0;;
            n|N ) return 1;;
            * ) echo "Por favor, responda s o n.";;
        esac
    done
}

# Función para obtener las versiones de JBoss instaladas
get_installed_versions() {
    rpm -qa | grep wildfly | cut -d'-' -f2 | sort -V
}

# Función para obtener las aplicaciones desplegadas en una versión de JBoss
get_deployed_apps() {
    version="$1"
    apps=$(ls -1 "${JBossPath}/wildfly-${version}/standalone/deployments" | grep -vE '\.(dodeploy|tmp)$' | cut -d'.' -f1)
    if [[ -n $apps ]]; then
        echo "${apps// /, }"
    else
        echo "Ninguna"
    fi
}

# Función para mostrar las versiones de JBoss instaladas y las aplicaciones que utilizan
display_versions_and_apps() {
    versions=("$@")
    echo "Versiones de JBoss instaladas:"
    for version in "${versions[@]}"; do
        apps=$(get_deployed_apps "$version")
        echo "  - ${version}: ${apps}"
    done
}

# Función para hacer una copia de seguridad de la versión actual de JBoss
backup_current_version() {
    version="$1"
    echo "Haciendo una copia de seguridad de la versión ${version}..."
    cp -r "${JBossPath}/wildfly-${version}" "${JBossPath}/wildfly-${version}-backup"
}

# Función para actualizar una versión de JBoss
update_jboss_version() {
    version="$1"
    echo "Actualizando la versión ${version}..."
    yum -y update "wildfly-${version}*"
}

# Función principal del script
main() {
    JBossPath="/opt"

    # Obtener las versiones de JBoss instaladas y mostrarlas
    versions=($(get_installed_versions))
    display_versions_and_apps "${versions[@]}"

    # Preguntar si se desean instalar los últimos parches
    if ask_install_patches; then
        echo "Instalando los últimos parches de JBoss..."
        yum -y update wildfly-*
    fi

    # Mostrar el menú y actualizar la versión seleccionada
    while true; do
        read -p "¿Qué versión de JBoss desea actualizar? (Escriba el número de versión o 'q' para salir): " version_choice
        if [[ $version_choice == "q" ]]; then
            echo "Saliendo..."
            exit 0
        fi
        if [[ "${versions[@]}" =~ "${version_choice}" ]]; then
            backup_current_version "$version_choice"
            update_jboss_version "$version_choice"
            echo "¡La versión ${version_choice} ha sido actualizada con éxito!"
            exit 0
        else
            echo "Por favor, seleccione una versión válida."