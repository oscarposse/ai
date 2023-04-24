#!/bin/bash

LOG_FILE="/ruta/a/tu/archivo.log"

# Contar errores por tipo y causa
echo "Errores por tipo y causa:"
grep ERROR $LOG_FILE | awk '{print $2, $NF}' | sort | uniq -c | sort -rn

# Contar avisos por tipo y causa
echo "Avisos por tipo y causa:"
grep WARN $LOG_FILE | awk '{print $2, $NF}' | sort | uniq -c | sort -rn

# Contar errores y avisos por fecha
echo "Errores y avisos por fecha:"
grep -E 'ERROR|WARN' $LOG_FILE | awk '{print $1}' | sort | uniq -c | sort -rn