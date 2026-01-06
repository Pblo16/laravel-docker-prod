# ==============================================
# Multi-stage build optimizado para Dokploy
# Cada stage cachea sus layers independientemente
# ==============================================

# Stage 1: Dependencias de Composer
FROM composer:2 AS composer-deps
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-scripts \
    --no-autoloader \
    --prefer-dist \
    --ignore-platform-reqs

# Stage 2: Build de assets frontend
FROM node:20-alpine AS frontend-builder
WORKDIR /app

# Copiar package files
COPY package.json pnpm-lock.yaml ./

# Instalar dependencias
RUN npm install -g pnpm && pnpm install --frozen-lockfile

# Copiar vendor desde composer stage (necesario para WireUI imports)
COPY --from=composer-deps /app/vendor ./vendor

# Copiar archivos de configuración necesarios para el build
COPY vite.config.js postcss.config.js ./

# Copiar recursos necesarios para compilación
COPY resources ./resources
COPY public ./public

# Build de assets
RUN pnpm build

# Stage 3: Runtime final
FROM php:8.3-fpm-alpine

# ==============================================
# Dependencias del sistema (comunes)
# ==============================================
RUN apk add --no-cache \
    nginx \
    curl \
    su-exec \
    netcat-openbsd \
    libzip \
    icu-libs \
    libintl \
    oniguruma \
    icu-data-full

# ==============================================
# DRIVERS DE BASE DE DATOS
# Descomenta SOLO el bloque que necesites
# ==============================================

# ────────────────────────────────────────────
# Opción A: PostgreSQL (ACTIVO por defecto)
# ────────────────────────────────────────────
RUN apk add --no-cache \
    postgresql-client \
    libpq

RUN apk add --no-cache --virtual .build-deps \
    libzip-dev \
    icu-dev \
    oniguruma-dev \
    libpq-dev \
    && docker-php-ext-install -j$(nproc) pdo pdo_pgsql pgsql intl zip opcache \
    && apk del .build-deps

# ────────────────────────────────────────────
# Opción B: MySQL/MariaDB (COMENTADO)
# Descomenta estas líneas y comenta el bloque PostgreSQL
# ────────────────────────────────────────────
# RUN apk add --no-cache \
#     mysql-client

# RUN apk add --no-cache --virtual .build-deps \
#     libzip-dev \
#     icu-dev \
#     oniguruma-dev \
#     && docker-php-ext-install -j$(nproc) pdo pdo_mysql intl zip opcache \
#     && apk del .build-deps

# ────────────────────────────────────────────
# Opción C: AMBOS (MySQL + PostgreSQL)
# Solo si realmente necesitas ambos drivers
# ────────────────────────────────────────────
# RUN apk add --no-cache \
#     mysql-client \
#     postgresql-client \
#     libpq

# RUN apk add --no-cache --virtual .build-deps \
#     libzip-dev \
#     icu-dev \
#     oniguruma-dev \
#     libpq-dev \
#     && docker-php-ext-install -j$(nproc) pdo pdo_mysql pdo_pgsql pgsql intl zip opcache \
#     && apk del .build-deps

WORKDIR /var/www

# Crear estructura de directorios Laravel PRIMERO
RUN mkdir -p \
    storage/framework/cache/data \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    storage/app/public \
    bootstrap/cache

# Copiar composer files para caching óptimo
COPY composer.json composer.lock ./

# Copiar vendor desde stage de composer
COPY --from=composer-deps /app/vendor ./vendor

# Copiar código de la aplicación (esto invalida cache con menos frecuencia)
COPY --chown=www-data:www-data . .

# Copiar assets compilados desde frontend builder (sobrescribir public/build)
COPY --from=frontend-builder /app/public/build ./public/build

# Generar autoloader optimizado (ahora con directorios existentes)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
RUN composer dump-autoload --optimize --no-dev --classmap-authoritative --ignore-platform-reqs \
    && rm /usr/bin/composer

# Permisos finales
RUN chown -R www-data:www-data storage bootstrap/cache public \
    && chmod -R 775 storage bootstrap/cache \
    && chmod -R 755 public

# Agregar usuario nginx al grupo www-data para acceso compartido
RUN addgroup nginx www-data

# Configuración PHP y PHP-FPM
COPY docker/app/php.ini /usr/local/etc/php/conf.d/laravel.ini
COPY docker/app/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

# Nginx config
COPY docker/app/nginx.conf /etc/nginx/nginx.conf

# Entrypoint optimizado
COPY docker/app/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

# Healthcheck para monitoreo del contenedor
HEALTHCHECK --interval=30s --timeout=5s --start-period=45s --retries=3 \
    CMD curl -f http://127.0.0.1/up || exit 1

ENTRYPOINT ["/entrypoint.sh"]
