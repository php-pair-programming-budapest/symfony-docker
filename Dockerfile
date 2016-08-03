FROM php:7.0-fpm

RUN set -xe \
    && apt-get update \
    && apt-get install -qqy git libfreetype6-dev libjpeg62-turbo-dev libmcrypt-dev libpng12-dev libicu-dev unzip \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) iconv mbstring mcrypt intl pdo_mysql gd zip

ENV COMPOSER_VERSION=1.1.0 COMPOSER_ALLOW_SUPERUSER=1
ENV SYMFONY_ENV prod

RUN set -xe \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION} \
    && composer global require --quiet "hirak/prestissimo:^0.3"

COPY composer.json composer.lock ./
RUN composer install --prefer-dist --no-dev --no-interaction --quiet --no-autoloader --no-scripts

COPY bin/ bin/
COPY etc/ etc/
COPY app/ app/
COPY src/ src/
COPY var/ var/
COPY web/ web/

# Build and cleanup
RUN set -xe \
    && composer dump-autoload --optimize \
    && composer run-script post-install-cmd \
    && bin/console assets:install \
    && mv web/ public/ \
    && bin/console cache:clear --no-warmup \
    && rm -rf var/cache/* \
        var/logs/* \
    && chmod -R 777 var/sessions/

VOLUME ["/var/www/html/web", "/var/www/html/var/sessions"]

COPY etc/docker/prod/app/entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
