# Dockerfile
FROM ghcr.io/laveracloudsolutions/php-runner:8.4-apache-trixie

ENV COMPOSER_VERSION=2.2.25
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV APACHE_DOCUMENT_ROOT=/var/www/html/api/public

# Installation de Node.js 20 (Méthode moderne compatible Trixie/Debian 13)
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

# Installation de Yarn (Utilisation du keyring pour éviter apt-key add qui est obsolète)
RUN curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /etc/apt/keyrings/yarn.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Mise à jour et installation des paquets
# Note : libkrb5-3 et libtasn1-6 sont conservés sans version car ils basculent en t64 sur Trixie
RUN apt-get update -qq && \
    apt-get upgrade -y && \
    apt-get install -qy \
    bind9 \
    git \
    glibc-source \
    gnutls-bin \
    libkrb5-3 \
    libtasn1-6 \
    nodejs \
    yarn \
    zsh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Nettoyage
RUN rm -rf /tmp/* /var/tmp/*

# Composer (Version spécifique demandée)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION}

# Extensions PHP de développement (Xdebug et PCOV)
# Sur Trixie/PHP 8.4, PECL installera les versions compatibles automatiquement
RUN pecl install xdebug pcov && \
    docker-php-ext-enable xdebug pcov

# Configuration Apache
RUN a2enmod rewrite remoteip headers security2

# Outillage global
RUN npm install -g commitizen

# Symfony CLI
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash && \
    apt-get install -y symfony-cli

# Copies de configuration
COPY ./config/apache/000-default.conf /etc/apache2/sites-available/
COPY ./config/php/php.ini $PHP_INI_DIR/php.ini
COPY ./config/php/php-cli.ini $PHP_INI_DIR/php-cli.ini
COPY ./config/php/xdebug.ini $PHP_INI_DIR/conf.d/xxx-xdebug.ini
