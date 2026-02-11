# Dockerfile
FROM ghcr.io/laveracloudsolutions/php-runner:8.4-apache

ENV COMPOSER_VERSION=2.2.25
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV APACHE_DOCUMENT_ROOT=/var/www/html/api/public

RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

ENV NODE_MAJOR=20
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update -qq && \
    apt-get upgrade -y && \
    apt-get install -qy \
    bind9=1:9.* \
    git=1:2.* \
    glibc-source=2.* \
    gnutls-bin=3.* \
    libkrb5-3=1.20.* \
    libtasn1-6=4.* \
    nodejs=20.* \
    yarn \
    zsh=5.*


RUN rm -rf /tmp/* /var/tmp/*

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION}

RUN pecl install xdebug && docker-php-ext-enable xdebug
RUN pecl install pcov && docker-php-ext-enable pcov

RUN a2enmod rewrite remoteip headers security2

RUN npm install -g commitizen

RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash
RUN apt install symfony-cli

COPY ./config/apache/000-default.conf /etc/apache2/sites-available/
COPY ./config/php/php.ini $PHP_INI_DIR/php.ini
COPY ./config/php/php-cli.ini $PHP_INI_DIR/php-cli.ini
COPY ./config/php/xdebug.ini $PHP_INI_DIR/conf.d/xxx-xdebug.ini
