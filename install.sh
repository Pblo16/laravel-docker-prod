#!/bin/bash

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# Advertir sobre sobrescritura
if [ "$(ls -A | grep -v '^\.' | wc -l)" -gt 0 ]; then
    echo -e "${YELLOW}[ADVERTENCIA]${NC} Los archivos existentes serán sobrescritos."
fi

# Descargar archivos usando GitHub tarball (más limpio y rápido)
echo -e "${BLUE}[INFO]${NC} Descargando archivos desde GitHub..."
REPO_URL="https://github.com/Pblo16/laravel-docker-prod"
BRANCH="main"

# Descargar y extraer tarball
curl -sL "${REPO_URL}/archive/refs/heads/${BRANCH}.tar.gz" | tar xz --strip-components=1

# Eliminar el script de instalación descargado (para evitar confusión)
rm -f install.sh

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ¡Descarga completada!                       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓${NC} Archivos descargados en: ${BLUE}$(pwd)${NC}"
echo ""
echo -e "${BLUE}Próximos pasos:${NC}"
echo "  1. Copia el archivo de ejemplo: ${YELLOW}cp .env.prod.example .env${NC}"
echo "  2. Edita las variables de entorno: ${YELLOW}nano .env${NC}"
echo "  3. Construye e inicia: ${YELLOW}docker compose -f docker-compose.prod.yml up -d --build${NC}"
echo ""
