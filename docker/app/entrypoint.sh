#!/bin/sh
set -e

cd /var/www

echo "[Entrypoint] Verificando estructura de directorios..."
mkdir -p \
  storage/framework/cache/data \
  storage/framework/sessions \
  storage/framework/views \
  storage/logs \
  storage/app/public \
  storage/app/private \
  storage/app/livewire-tmp \
  bootstrap/cache

# Crear directorios de Nginx (necesarios para uploads)
mkdir -p \
  /var/lib/nginx/tmp/client_body \
  /var/lib/nginx/tmp/fastcgi \
  /var/lib/nginx/tmp/proxy
chown -R nginx:nginx /var/lib/nginx/tmp

# Crear archivo de log explícitamente antes de que Laravel lo use
touch storage/logs/laravel.log

# Permisos críticos para storage y logs
chown -R www-data:www-data storage bootstrap/cache public
chmod -R 775 storage bootstrap/cache
chmod 666 storage/logs/laravel.log
chmod 775 public

# Enlace simbólico de storage
echo "[Entrypoint] Creando enlace simbólico storage..."
rm -f public/storage
su-exec www-data php artisan storage:link --force || echo "[Entrypoint] Warning: No se pudo crear enlace simbólico, continuando..."

# Esperar a que la base de datos esté lista (solo si DB_HOST está configurado)
if [ -n "${DB_HOST}" ]; then
  DB_PORT_DEFAULT=3306
  if [ "${DB_CONNECTION}" = "pgsql" ]; then
    DB_PORT_DEFAULT=5432
  fi
  
  echo "[Entrypoint] Esperando conexión a base de datos (${DB_CONNECTION:-mysql}) en ${DB_HOST}:${DB_PORT:-$DB_PORT_DEFAULT}..."
  MAX_TRIES=60
  RETRY=0
  
  # Primero verificar conectividad de red básica
  while [ $RETRY -lt $MAX_TRIES ]; do
    if nc -z "${DB_HOST}" "${DB_PORT:-$DB_PORT_DEFAULT}" 2>/dev/null; then
      echo "[Entrypoint] Puerto de base de datos accesible!"
      break
    fi
    RETRY=$((RETRY + 1))
    echo "[Entrypoint] Esperando puerto de base de datos... intento $RETRY/$MAX_TRIES"
    sleep 2
  done
  
  if [ $RETRY -eq $MAX_TRIES ]; then
    echo "[Entrypoint] ERROR: No se pudo conectar al puerto de la base de datos"
    exit 1
  fi
  
  # Ahora verificar conexión real de base de datos
  echo "[Entrypoint] Verificando conexión a base de datos..."
  RETRY=0
  while [ $RETRY -lt 30 ]; do
    if su-exec www-data php artisan db:show > /dev/null 2>&1; then
      echo "[Entrypoint] Base de datos conectada y lista!"
      sleep 3
      break
    fi
    RETRY=$((RETRY + 1))
    echo "[Entrypoint] Esperando base de datos... intento $RETRY/30"
    sleep 2
  done
  
  if [ $RETRY -eq 30 ]; then
    echo "[Entrypoint] ERROR: Puerto accesible pero no se puede conectar a la base de datos"
    echo "[Entrypoint] Verifica DB_CONNECTION, DB_DATABASE, DB_USERNAME y DB_PASSWORD"
    exit 1
  fi
fi

# Migraciones ANTES de optimización (para que existan tablas necesarias)
if [ "${AUTO_MIGRATE}" = "true" ]; then
  echo "[Entrypoint] Ejecutando migraciones (AUTO_MIGRATE=true)..."
  su-exec www-data php artisan migrate --force
  
  # Ejecutar seeders solo si AUTO_SEED está habilitado
  if [ "${AUTO_SEED}" = "true" ]; then
    # Verificar si ya se ejecutaron los seeders (usando tabla de control)
    SEED_EXECUTED=$(su-exec www-data php artisan tinker --execute="echo \App\Models\User::count();" 2>/dev/null || echo "0")
    
    if [ "$SEED_EXECUTED" -gt 0 ] && [ "${FORCE_SEED}" != "true" ]; then
      echo "[Entrypoint] ⏭️  Seeders omitidos (ya existen datos, usa FORCE_SEED=true para forzar)"
    else
      echo "[Entrypoint] Ejecutando seeders (AUTO_SEED=true)..."
      su-exec www-data php artisan db:seed --force
      
      echo "[Entrypoint] Generando permisos..."
      su-exec www-data php artisan generate:permissions || echo "[Entrypoint] Warning: generate:permissions falló"
      
      echo "[Entrypoint] Creando super admin..."
      su-exec www-data php artisan create:super-admin "${ADMIN_EMAIL:-admin@example.com}" || echo "[Entrypoint] Warning: create:super-admin falló"
    fi
  else
    echo "[Entrypoint] Seeders omitidos (AUTO_SEED=${AUTO_SEED:-false})"
  fi
else
  echo "[Entrypoint] Migraciones omitidas (AUTO_MIGRATE=${AUTO_MIGRATE:-false})"
  echo "[Entrypoint] ⚠️  Asegúrate de ejecutar 'php artisan migrate' manualmente"
fi

echo "[Entrypoint] Optimizando Laravel..."
# Limpiar caches solo si ya existen (evita error en primera ejecución)
su-exec www-data php artisan config:clear 2>/dev/null || true
su-exec www-data php artisan route:clear 2>/dev/null || true
su-exec www-data php artisan view:clear 2>/dev/null || true

# Optimizar Laravel (config + routes + events cache)
# Según docs: https://laravel.com/docs/deployment#optimization
su-exec www-data php artisan optimize

# Cachear vistas Blade
su-exec www-data php artisan view:cache

echo "[Entrypoint] Iniciando PHP-FPM y Nginx..."
php-fpm -D

# Tail logs de Laravel a stdout para docker logs
tail -f storage/logs/laravel.log 2>/dev/null &

exec nginx -g 'daemon off;'
