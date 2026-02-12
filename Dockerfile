# Utilisation de l'image de base demandée (PHP 8.4 sur Debian Trixie)
FROM ghcr.io/laveracloudsolutions/php:8.4-apache-trixie

# Installation des dépendances (Vérifiées pour Debian 13 Trixie)
RUN apt-get update -qq && \
    apt-get upgrade -y && \
    apt-get install -qy \
    apache2 \
    ca-certificates \
    curl \
    bind9-dnsutils \
    expat \
    fontconfig \
    git \
    gnupg \
    gnutls-bin \
    iputils-ping \
    libapache2-mod-security2 \
    libc6 \
    libfreetype-dev \
    libfreetype6 \
    libgrpc++-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libjpeg62-turbo \
    libpng-dev \
    libpng16-16t64 \
    libpq-dev \
    libsqlite3-0 \
    libxml2-dev \
    libxrender1 \
    libzip-dev \
    linux-libc-dev \
    net-tools \
    perl \
    xz-utils \
    unzip \
    vim \
    xfonts-75dpi \
    xfonts-base \
    xvfb \
    zip \
    zlib1g-dev

# Nettoyage des listes apt
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# PHP Extensions Standards
RUN docker-php-ext-configure zip && \
    docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j"$(nproc)" intl pgsql pdo pdo_pgsql opcache zip gd

# PHP Extensions via PECL
RUN pecl install redis opentelemetry protobuf && \
    docker-php-ext-enable redis opentelemetry protobuf

# Compilation manuelle de gRPC (méthode fiable pour PHP 8.4/8.5)
RUN git clone --depth 1 -b v1.63.x https://github.com/grpc/grpc /tmp/grpc \
    && cd /tmp/grpc/src/php/ext/grpc \
    && phpize && ./configure && make -j"$(nproc)" && make install \
    && rm -rf /tmp/grpc \
    && docker-php-ext-enable grpc

# Configuration Apache
RUN a2enmod headers rewrite remoteip security2

# Timezone
RUN ln -snf /usr/share/zoneinfo/Europe/Paris /etc/localtime && echo "Europe/Paris" > /etc/timezone

EXPOSE 8080
WORKDIR /var/www/html

# Copies de configuration
COPY ./config/php/php.ini /usr/local/etc/php/php.ini
COPY ./config/apache/VirtualHost.conf /etc/apache2/sites-available/000-default.conf
COPY ./config/apache/apache2.conf /etc/apache2/apache2.conf
COPY ./config/apache/ports.conf /etc/apache2/ports.conf
COPY ./config/apache/mods-enabled/deflate.conf /etc/apache2/mods-enabled/deflate.conf