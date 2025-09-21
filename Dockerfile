# Dockerfile for building Symfony PHP-FPM app.
# Multi-stage build for optimized production image.

# --- Build stage
FROM php:8.3-fpm-alpine AS build

RUN set -eux; \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS icu-dev git unzip; \
    docker-php-ext-configure intl; \
    docker-php-ext-install -j"$(nproc)" intl opcache; \
    apk del .build-deps; \
    apk add --no-cache icu-libs

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY . .

RUN COMPOSER_ALLOW_SUPERUSER=1 \
    composer install --no-dev --prefer-dist --no-interaction --no-progress \
 && composer dump-autoload --classmap-authoritative --no-dev

# --- Runtime stage
FROM php:8.3-fpm-alpine
RUN apk add --no-cache icu-libs netcat-openbsd \
 && docker-php-ext-install opcache

WORKDIR /app
COPY --from=build /app /app

ARG APP_VERSION=unknown
LABEL org.opencontainers.image.title="ksymfony" \
      org.opencontainers.image.version=$APP_VERSION

RUN addgroup -g 1000 app && adduser -D -G app -u 1000 app
RUN mkdir -p var && chown -R 1000:1000 var
USER app

ENV APP_ENV=prod APP_DEBUG=0
EXPOSE 9000
CMD ["php-fpm", "-F"]
