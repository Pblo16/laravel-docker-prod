# Laravel Docker Production Setup - AI Coding Instructions

## Project Overview

Production-ready Docker configuration for Laravel applications. Single-container architecture (PHP-FPM + Nginx) with Redis, optimized for Dokploy deployment. Uses multi-stage build with separate Composer and Node stages for efficient layer caching.

## Architecture & Design Decisions

### Single Container Strategy

- **One container**: Nginx and PHP-FPM run together in Alpine Linux (`php:8.3-fpm-alpine`)
- **Why**: Simplified deployment on Dokploy, reduced orchestration complexity, optimized for small-to-medium Laravel apps
- **Trade-off**: Less horizontal scalability vs. microservices, but faster builds and simpler configuration

### Multi-Stage Dockerfile Pattern

Three distinct build stages in [docker/app/Dockerfile](docker/app/Dockerfile):

1. **composer-deps**: Install PHP dependencies with `--no-dev --prefer-dist --ignore-platform-reqs`
2. **frontend-builder**: Node 20 + pnpm for Vite builds, requires vendor copied for WireUI/Blade component imports
3. **Runtime**: Alpine-based PHP-FPM with compiled assets and optimized autoloader

**Critical**: Frontend stage MUST copy `vendor/` before running `pnpm build` (line 28) - WireUI/Livewire imports fail otherwise.

### Database Driver Architecture

[Dockerfile lines 67-106](docker/app/Dockerfile#L67-L106) has **switchable database drivers**:

- Default: PostgreSQL (`pdo_pgsql`)
- Comment PostgreSQL block, uncomment MySQL block for `pdo_mysql`
- Install ONLY needed drivers to minimize image size (~50MB difference)

## Critical Workflows

### Build & Deploy

```bash
# Build and start (required: .env with DB credentials)
docker compose -f docker-compose.prod.yml up -d --build

# View real-time logs (entrypoint + Laravel)
docker compose -f docker-compose.prod.yml logs -f app
```

### Automated Bootstrap (AUTO_MIGRATE/AUTO_SEED)

[entrypoint.sh lines 62-96](docker/app/entrypoint.sh#L62-L96) handles:

- `AUTO_MIGRATE=true`: Runs migrations on container start
- `AUTO_SEED=true`: Seeds database ONCE (checks `User::count()` to prevent duplicates)
- `FORCE_SEED=true`: Override duplicate prevention
- Custom artisan commands: `generate:permissions`, `create:super-admin` (project-specific)

**Important**: Migrations run BEFORE cache optimization to ensure tables exist for `config:cache`.

### Database Connection Wait Logic

[entrypoint.sh lines 36-60](docker/app/entrypoint.sh#L36-L60):

1. Port check with `nc -z` (max 60 attempts)
2. Laravel connection test with `php artisan db:show` (max 30 attempts)
3. Explicit error messages distinguish port vs. credentials issues

### Cache Optimization Strategy

[entrypoint.sh lines 106-115](docker/app/entrypoint.sh#L106-L115):

```bash
php artisan optimize      # Routes + config + events
php artisan view:cache    # Blade templates
```

**Production workflow**: Clear old caches → run `optimize` → cache views. Follows [Laravel deployment docs](https://laravel.com/docs/deployment#optimization).

## Project-Specific Conventions

### Environment Variables Pattern

[.env.prod.example](.env.prod.example) groups by concern (Application, Database, Cache, Queue):

- `TRUSTED_PROXIES=*`: Required for Traefik/Dokploy reverse proxy (CloudFlare, load balancers)
- `AUTO_MIGRATE`/`AUTO_SEED`: Docker-specific deployment flags (not standard Laravel)
- `ADMIN_IDENTIFIER`: Email migration helper (set to old email before changing `ADMIN_EMAIL`)

### File Permissions Strategy

Dual ownership model:

- `www-data:www-data` owns Laravel files (PHP-FPM runs as www-data)
- `nginx` added to `www-data` group ([Dockerfile line 151](docker/app/Dockerfile#L151))
- Directories: `775`, logs: `666`, public: `755`
- Nginx temp dirs: `/var/lib/nginx/tmp/*` (created in entrypoint, owned by nginx)

### Nginx Configuration

[docker/app/nginx.conf](docker/app/nginx.conf):

- Healthcheck endpoint: `/up` returns `200 OK` (used by Docker/Dokploy)
- FPM status: `/fpm-status`, `/fpm-ping` (internal monitoring)
- Proxy headers: Forwards `X-Forwarded-*` to Laravel for HTTPS detection
- CSP header: Allows `'unsafe-inline'` for Livewire/Alpine.js compatibility

### PHP Optimizations

[docker/app/php.ini](docker/app/php.ini):

- OPcache: `validate_timestamps=0` (never check file changes in production)
- `max_accelerated_files=20000` for large codebases
- `realpath_cache_size=4096K` reduces filesystem stat calls

## Common Tasks

### Switching Database Drivers

1. Edit [Dockerfile lines 67-106](docker/app/Dockerfile#L67-L106)
2. Comment PostgreSQL block, uncomment MySQL block
3. Update `.env`: `DB_CONNECTION=mysql`, `DB_PORT=3306`
4. Rebuild: `docker compose -f docker-compose.prod.yml build`

### Adding PHP Extensions

Add to Dockerfile after line 66:

```dockerfile
RUN apk add --no-cache libextension \
    && apk add --no-cache --virtual .build-deps libextension-dev \
    && docker-php-ext-install extension \
    && apk del .build-deps
```

### Debugging Build Failures

- **Frontend build fails**: Check if `vendor/` copied before `pnpm build` (line 28)
- **Permission errors**: Verify `storage/` directories created BEFORE `composer dump-autoload` (line 139)
- **Database connection fails**: Check entrypoint logs for port vs. credentials failure

### Installing Script

[install.sh](install.sh) downloads repo via GitHub tarball API, excludes README to prevent overwrite. Run: `curl -sL https://raw.githubusercontent.com/Pblo16/laravel-docker-prod/main/install.sh | bash`

## Integration Points

- **Dokploy**: Uses `docker-compose.prod.yml`, reads env vars from UI, Traefik proxy integration
- **Redis**: Optional caching layer, configured via `CACHE_STORE=redis` and `SESSION_DRIVER=redis`
- **CloudBeaver**: Database GUI (mentioned in README but not in docker-compose.prod.yml - external service)

## File References

Key files to understand the full architecture:

- [docker-compose.prod.yml](docker-compose.prod.yml) - Service definitions, volume mounts
- [docker/app/Dockerfile](docker/app/Dockerfile) - Multi-stage build, database drivers
- [docker/app/entrypoint.sh](docker/app/entrypoint.sh) - Startup automation, migrations, optimizations
- [docker/app/nginx.conf](docker/app/nginx.conf) - Routing, security headers, FastCGI config
- [.env.prod.example](.env.prod.example) - Complete environment variable reference
