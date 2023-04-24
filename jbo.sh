#!/bin/bash

JBossPath=/opt

get_installed_versions() {
    ls -d $JBossPath/wildfly-* 2>/dev/null | awk -F'-' '{print $NF}' | sort -V
}

get_apps_for_version() {
    VersionPath="$JBossPath/wildfly-$1"
    grep -R 'jboss.server.base.dir' $VersionPath/domain/configuration $VersionPath/standalone/configuration | sed 's/.*\///' | sort -u
}

display_versions_and_apps() {
    Versions=($1)
    echo "Se encontraron las siguientes versiones de JBoss instaladas en $JBossPath:"
    for Version in "${Versions[@]}"; do
        Apps=$(get_apps_for_version $Version)
        echo "- $Version: ${Apps[*]}"
    done
}

backup_version() {
    Version="$1"
    BackupFile="$JBossPath/wildfly-$Version-backup-$(date +"%Y%m%d%H%M%S").tar.gz"
    echo "Haciendo backup de JBoss $Version a $BackupFile..."
    tar -czvf $BackupFile "$JBossPath/wildfly-$Version" >/dev/null 2>&1
}

download_and_install_latest_version() {
    echo "Obteniendo última versión de JBoss..."
    LatestVersion=$(curl -s https://download.jboss.org/wildfly/ | grep -o 'wildfly-[0-9]\+\.[0-9]\+\.[0-9]\+' | sort -rV | head -n 1)
    LatestVersionNumber=$(echo $LatestVersion | awk -F'-' '{print $2}')
    echo "Descargando y descomprimiendo JBoss $LatestVersion..."
    wget -q https://download.jboss.org/wildfly/$LatestVersion/wildfly-$LatestVersionNumber.zip -O jboss.zip
    unzip -q jboss.zip -d $JBossPath
}

copy_config_files() {
    FromVersion="$1"
    ToVersion="$2"
    echo "Copiando archivos de configuración de JBoss $FromVersion a JBoss $ToVersion..."
    cp -r "$JBossPath/wildfly-$FromVersion/standalone/configuration"/* "$JBossPath/wildfly-$ToVersion/standalone/configuration"
}

start_and_check_new_version() {
    Version="$1"
    echo "Iniciando JBoss $Version..."
    nohup "$JBossPath/wildfly-$Version/bin/standalone.sh" -c standalone.xml >/dev/null 2>&1 &
    sleep 10
    if curl -s http://localhost:8080/ >/dev/null; then
        echo "JBoss $Version se ha actualizado exitosamente."
    else
        echo "Error: JBoss $Version no se ha iniciado correctamente."
    fi
}

versions=($(get_installed_versions))
display_versions_and_apps "${versions[*]}"

# Prompt para seleccionar la versión a actualizar
PS3="Seleccione una versión para actualizar: "
select VersionToUpgrade in "${versions[@]}"; do
    if [[ -n "$VersionToUpgrade" && "${versions[@]}" =~ "$VersionToUpgrade" ]]; then
        break
    else
        echo "Selección inválida. Por favor, seleccione una versión existente."
    fi
done

backup_version $VersionToUpgrade
download_and_install_latest_version
copy_config_files $VersionToUpgrade $LatestVersionNumber
start_and_check_new_version $
