#!/bin/bash

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║     Laravel Docker Production Setup                   ║
║     Instalación automática                            ║
╚═══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Solicitar información al usuario
echo ""
print_message "Configuración del proyecto"
echo ""

read -p "Nombre del directorio para el proyecto [laravel-app]: " PROJECT_DIR
PROJECT_DIR=${PROJECT_DIR:-laravel-app}

read -p "Nombre de la base de datos [laravel]: " DB_NAME
DB_NAME=${DB_NAME:-laravel}

read -p "Usuario de la base de datos [laravel_user]: " DB_USER
DB_USER=${DB_USER:-laravel_user}

read -sp "Contraseña de la base de datos [genera aleatoria]: " DB_PASS
echo ""
if [ -z "$DB_PASS" ]; then
    DB_PASS=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
    print_warning "Contraseña generada automáticamente: $DB_PASS"
fi

read -sp "Contraseña de root de MySQL [genera aleatoria]: " DB_ROOT_PASS
echo ""
if [ -z "$DB_ROOT_PASS" ]; then
    DB_ROOT_PASS=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
    print_warning "Contraseña root generada: $DB_ROOT_PASS"
fi

read -p "URL de la aplicación [http://localhost]: " APP_URL
APP_URL=${APP_URL:-http://localhost}

# Clonar repositorio
echo ""
print_message "Clonando repositorio..."
if [ -d "$PROJECT_DIR" ]; then
    print_error "El directorio $PROJECT_DIR ya existe."
    read -p "¿Deseas eliminarlo y continuar? (s/N): " CONFIRM
    if [[ $CONFIRM =~ ^[Ss]$ ]]; then
        rm -rf "$PROJECT_DIR"
    else
        print_error "Instalación cancelada."
        exit 1
    fi
fi

git clone https://github.com/Pblo16/laravel-docker-prod.git "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Crear archivo .env
print_message "Creando archivo de configuración .env..."
cat > .env << EOL
# Laravel Configuration
APP_NAME="Laravel App"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=${APP_URL}
APP_TIMEZONE=UTC
APP_LOCALE=es

# Database Configuration
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=${DB_NAME}
DB_USERNAME=${DB_USER}
DB_PASSWORD=${DB_PASS}
DB_ROOT_PASSWORD=${DB_ROOT_PASS}

# Database Manager (CloudBeaver)
DB_MANAGER_USER=admin
DB_MANAGER_PASSWORD=admin

# Cache & Queue
CACHE_STORE=file
QUEUE_CONNECTION=database
SESSION_DRIVER=file

# Deployment Options
AUTO_MIGRATE=true
AUTO_SEED=false

# Mail Configuration
MAIL_MAILER=log
MAIL_HOST=
MAIL_PORT=
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_ENCRYPTION=
MAIL_FROM_ADDRESS=
MAIL_FROM_NAME=
EOL

print_success "Archivo .env creado."

# Preguntar si quiere clonar un proyecto Laravel existente
echo ""
read -p "¿Deseas clonar un proyecto Laravel existente? (s/N): " CLONE_LARAVEL
if [[ $CLONE_LARAVEL =~ ^[Ss]$ ]]; then
    read -p "URL del repositorio Laravel: " LARAVEL_REPO
    if [ -n "$LARAVEL_REPO" ]; then
        print_message "Clonando proyecto Laravel..."
        git clone "$LARAVEL_REPO" temp-laravel
        # Copiar archivos sin sobrescribir docker y docker-compose
        rsync -av --exclude='.git' --exclude='docker' --exclude='docker-compose*.yml' temp-laravel/ ./
        rm -rf temp-laravel
        print_success "Proyecto Laravel clonado."
    fi
else
    print_warning "No se clonó ningún proyecto Laravel. Asegúrate de agregar tu código Laravel a este directorio."
fi

# Construir imágenes
echo ""
print_message "Construyendo imágenes Docker..."
docker compose -f docker-compose.prod.yml build

# Iniciar servicios
print_message "Iniciando servicios..."
docker compose -f docker-compose.prod.yml up -d

# Esperar a que MySQL esté listo
print_message "Esperando a que MySQL esté listo..."
sleep 10

# Generar APP_KEY si no existe
print_message "Generando APP_KEY..."
docker compose -f docker-compose.prod.yml exec -T app php artisan key:generate --force

# Ejecutar migraciones si AUTO_MIGRATE está habilitado
if [ "$AUTO_MIGRATE" = "true" ]; then
    print_message "Ejecutando migraciones..."
    docker compose -f docker-compose.prod.yml exec -T app php artisan migrate --force
fi

# Resumen
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ¡Instalación completada!                    ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
print_success "Tu aplicación Laravel está corriendo."
echo ""
echo -e "${BLUE}Información importante:${NC}"
echo -e "  📁 Directorio: ${GREEN}$(pwd)${NC}"
echo -e "  🌐 URL: ${GREEN}${APP_URL}${NC}"
echo -e "  🗄️  Base de datos: ${GREEN}${DB_NAME}${NC}"
echo -e "  👤 Usuario DB: ${GREEN}${DB_USER}${NC}"
echo -e "  🔑 Contraseña DB: ${GREEN}${DB_PASS}${NC}"
echo -e "  🔐 Root password: ${GREEN}${DB_ROOT_PASS}${NC}"
echo ""
echo -e "${BLUE}Comandos útiles:${NC}"
echo "  Ver logs:           docker compose -f docker-compose.prod.yml logs -f"
echo "  Detener servicios:  docker compose -f docker-compose.prod.yml down"
echo "  Reiniciar:          docker compose -f docker-compose.prod.yml restart"
echo "  Ejecutar artisan:   docker compose -f docker-compose.prod.yml exec app php artisan"
echo ""
print_warning "Guarda las credenciales de la base de datos en un lugar seguro."
echo ""
