#!/bin/bash

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
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

# Verificar si el directorio actual está vacío
if [ "$(ls -A . 2>/dev/null)" ]; then
    echo -e "${BLUE}[INFO]${NC} El directorio actual no está vacío."
    read -p "¿Deseas descargar en el directorio actual de todas formas? (s/N): " CONFIRM_CURRENT
    
    if [[ ! $CONFIRM_CURRENT =~ ^[Ss]$ ]]; then
        read -p "Nombre del directorio para el proyecto [laravel-docker-prod]: " PROJECT_DIR
        PROJECT_DIR=${PROJECT_DIR:-laravel-docker-prod}
        
        if [ -d "$PROJECT_DIR" ]; then
            echo -e "${RED}[ERROR]${NC} El directorio $PROJECT_DIR ya existe."
            read -p "¿Deseas eliminarlo y continuar? (s/N): " CONFIRM
            if [[ $CONFIRM =~ ^[Ss]$ ]]; then
                rm -rf "$PROJECT_DIR"
            else
                echo -e "${RED}[ERROR]${NC} Instalación cancelada."
                exit 1
            fi
        fi
        
        # Clonar en directorio específico
        echo -e "${BLUE}[INFO]${NC} Descargando archivos..."
        git clone https://github.com/Pblo16/laravel-docker-prod.git "$PROJECT_DIR"
        
        echo ""
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║           ¡Descarga completada!                       ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${GREEN}✓${NC} Archivos descargados en: ${BLUE}$(pwd)/$PROJECT_DIR${NC}"
        echo ""
        echo -e "Para continuar:"
        echo -e "  ${BLUE}cd $PROJECT_DIR${NC}"
        echo ""
        exit 0
    fi
fi

# Clonar en directorio actual
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
