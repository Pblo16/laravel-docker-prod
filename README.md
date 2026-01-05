# 🐳 Laravel Docker Production

Configuración de Docker lista para producción para aplicaciones Laravel con Nginx, PHP-FPM, MySQL y CloudBeaver.

## 🚀 Descarga Rápida

Descarga los archivos de configuración con un solo comando:

```bash
curl -sL https://raw.githubusercontent.com/Pblo16/laravel-docker-prod/main/install.sh | bash
```

El script te pedirá el nombre del directorio y descargará todos los archivos de configuración Docker.

## 📦 ¿Qué incluye?

Esta configuración incluye:

- 🐘 **PHP 8.2-FPM** con Nginx optimizado para Laravel
- 🗄️ **MySQL 8.0** con persistencia de datos
- 🔧 **CloudBeaver** para gestión visual de base de datos
- ⚙️ **Configuración lista para producción**
- 🐳 **Docker Compose** pre-configurado

## 🛠️ Instalación Manual

### 1. Clonar el repositorio

```bash
git clone https://github.com/Pblo16/laravel-docker-prod.git
cd laravel-docker-prod
```

### 2. Configurar variables de entorno

```bash
cp .env.example .env
# Edita el archivo .env con tus configuraciones
nano .env
```

### 3. Agregar tu proyecto Laravel

Coloca tu código Laravel en el directorio raíz o clónalo:

```bash
git clone https://github.com/tu-usuario/tu-proyecto-laravel.git temp
rsync -av --exclude='.git' --exclude='docker' --exclude='docker-compose*.yml' temp/ ./
rm -rf temp
```

### 4. Construir e iniciar los servicios

```bash
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
```

### 5. Configurar Laravel

```bash
# Generar APP_KEY
docker compose -f docker-compose.prod.yml exec app php artisan key:generate

# Ejecutar migraciones
docker compose -f docker-compose.prod.yml exec app php artisan migrate --force

# Limpiar y optimizar
docker compose -f docker-compose.prod.yml exec app php artisan config:cache
docker compose -f docker-compose.prod.yml exec app php artisan route:cache
docker compose -f docker-compose.prod.yml exec app php artisan view:cache
```

## 🏗️ Estructura del Proyecto

```
laravel-docker-prod/
├── docker/
│   └── app/
│       ├── Dockerfile          # Imagen personalizada PHP-FPM + Nginx
│       ├── entrypoint.sh       # Script de inicialización
│       ├── nginx.conf          # Configuración de Nginx
│       ├── php-fpm.conf        # Configuración de PHP-FPM
│       └── php.ini             # Configuración de PHP
├── docker-compose.prod.yml     # Configuración Docker Compose
├── install.sh                  # Script de instalación automática
├── .env                        # Variables de entorno (crear)
└── README.md                   # Este archivo
```

## 📦 Servicios Incluidos

### 🌐 App (Nginx + PHP-FPM)

- **Puerto:** 80
- Servidor web Nginx con PHP 8.2-FPM
- Optimizado para Laravel
- Configuración lista para producción

### 🗄️ MySQL

- **Puerto:** 3306

# Limpiar y optimizar cache

docker compose -f docker-compose.prod.yml exec app php artisan optimiz

- **Puerto:** 8978
- Interfaz web para gestión de base de datos
- Acceso: `http://localhost:8978`
- Usuario por defecto: `admin` / `admin`

## ⚙️ Variables de Entorno

### Aplicación Laravel

```env
APP_NAME="Laravel App"
APP_ENV=production
APP_KEY=                    # Se genera automáticamente
APP_DEBUG=false
APP_URL=http://localhost
```

### Base de Datos

```env
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel_user
DB_PASSWORD=tu_password_seguro
DB_ROOT_PASSWORD=tu_root_password_seguro
```

### Opciones de Despliegue

```env
AUTO_MIGRATE=true          # Ejecutar migraciones al iniciar
AUTO_SEED=false            # Ejecutar seeders al iniciar
```

## 📝 Comandos Útiles

### Gestión de contenedores

```bash
# Ver logs de todos los servicios
docker compose -f docker-compose.prod.yml logs -f

# Ver logs de un servicio específico
docker compose -f docker-compose.prod.yml logs -f app

# Detener servicios
docker compose -f docker-compose.prod.yml down

# Detener y eliminar volúmenes
docker compose -f docker-compose.prod.yml down -v

# Reiniciar servicios
docker compose -f docker-compose.prod.yml restart

# Ver estado de los servicios
docker compose -f docker-compose.prod.yml ps
```

### Comandos de Laravel

```bash
# Ejecutar comandos Artisan
docker compose -f docker-compose.prod.yml exec app php artisan [comando]

# Ejemplos:
docker compose -f docker-compose.prod.yml exec app php artisan migrate
docker compose -f docker-compose.prod.yml exec app php artisan db:seed
docker compose -f docker-compose.prod.yml exec app php artisan cache:clear
docker compose -f docker-compose.prod.yml exec app php artisan config:clear

# Acceder al contenedor
docker compose -f docker-compose.prod.yml exec app bash

# Ejecutar Composer
docker compose -f docker-compose.prod.yml exec app composer install --no-dev --optimize-autoloader
```

### Base de datos

```bash
# Backup de la base de datos
docker compose -f docker-compose.prod.yml exec mysql mysqldump -uroot -p${DB_ROOT_PASSWORD} ${DB_DATABASE} > backup.sql

# Restaurar backup
docker compose -f docker-compose.prod.yml exec -T mysql mysql -uroot -p${DB_ROOT_PASSWORD} ${DB_DATABASE} < backup.sql

# Acceder a MySQL CLI
docker compose -f docker-compose.prod.yml exec mysql mysql -uroot -p
```

## 🔒 Seguridad

Para producción, asegúrate de:

1. ✅ Cambiar todas las contraseñas por defecto
2. ✅ Establecer `APP_DEBUG=false`
3. ✅ Usar contraseñas seguras (mínimo 16 caracteres)
4. ✅ Configurar un firewall apropiado
5. ✅ Usar HTTPS con certificados SSL/TLS
6. ✅ Mantener Docker y las imágenes actualizadas
7. ✅ Limitar el acceso a CloudBeaver o deshabilitarlo en producción

## 🌐 Despliegue en Dokploy

Este proyecto está optimizado para ser desplegado en [Dokploy](https://dokploy.com/):

1. Conecta tu repositorio en Dokploy
2. Selecciona `docker-compose.prod.yml` como archivo de compose
3. Configura las variables de entorno en el panel de Dokploy
4. Despliega

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto es de código abierto. Siéntete libre de usarlo y modificarlo según tus necesidades.

## 🐛 Problemas Comunes

### El contenedor no inicia

```bash
# Verificar logs
docker compose -f docker-compose.prod.yml logs app

# Verificar permisos
sudo chown -R www-data:www-data storage bootstrap/cache
```

### Error de conexión a la base de datos

```bash
# Verificar que MySQL esté corriendo
docker compose -f docker-compose.prod.yml ps

# Verificar logs de MySQL
docker compose -f docker-compose.prod.yml logs mysql

# Esperar a que MySQL esté completamente iniciado (puede tomar 30-60 segundos)
```

### Problemas de permisos

```bash
# Dentro del contenedor
docker compose -f docker-compose.prod.yml exec app bash
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache
```

## 📞 Soporte

Si encuentras algún problema o tienes preguntas:

- 🐛 Reporta bugs en [GitHub Issues](https://github.com/Pblo16/laravel-docker-prod/issues)
- 💬 Discusiones en [GitHub Discussions](https://github.com/Pblo16/laravel-docker-prod/discussions)

---

**Desarrollado con ❤️ para la comunidad Laravel**
