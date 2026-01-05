#!/bin/bash

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║     Laravel Docker Production Setup                   ║
║     Descarga de archivos                              ║
╚═══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Descargar archivos en el directorio actual
echo -e "${BLUE}[INFO]${NC} Descargando archivos en el directorio actual..."
git clone https://github.com/Pblo16/laravel-docker-prod.git temp-download
mv temp-download/* temp-download/.[!.]* . 2>/dev/null || true
rm -rf temp-download

# Mensaje final
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ¡Descarga completada!                       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓${NC} Archivos descargados en: ${BLUE}$(pwd)${NC}"
echo ""
