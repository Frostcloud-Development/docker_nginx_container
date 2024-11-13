# Use Debian as the base image
FROM debian:bullseye-slim

# Environment variables for non-interactive apt install
ENV DEBIAN_FRONTEND=noninteractive
ENV PHP_VERSION=8.3

# Update the package list and install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg2 \
    lsb-release \
    apt-transport-https \
    software-properties-common \
    memcached \
    build-essential \
    libpcre3 \
    libpcre3-dev \
    zlib1g \
    zlib1g-dev \
    libssl-dev \
    curl \
    --no-install-recommends

# Download and build NGINX with http_realip_module
RUN curl -O http://nginx.org/download/nginx-1.24.0.tar.gz \
    && tar -xzvf nginx-1.24.0.tar.gz \
    && cd nginx-1.24.0 \
    && ./configure --sbin-path=/usr/bin/nginx --conf-path=/etc/nginx/nginx.conf --with-pcre --pid-path=/var/run/nginx.pid --with-http_ssl_module --with-http_realip_module \
    && make \
    && make install

RUN rm -rf /nginx-1.24.0*

# Add the PHP repository for Debian
RUN curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
RUN sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
RUN apt update

# Install PHP 8.3 and necessary extensions
RUN apt-get install -y \
    php${PHP_VERSION} \
    php${PHP_VERSION}-cli \
	php${PHP_VERSION}-curl \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-ctype \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-mysqli \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-iconv \
    php${PHP_VERSION}-dom \
    php${PHP_VERSION}-simplexml \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-memcached \
    --no-install-recommends

# PHP-FPM configuration (optional: can be further customized)
RUN sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/${PHP_VERSION}/fpm/php.ini \
    && echo "listen.owner = www-data" >> /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf \
    && echo "listen.group = www-data" >> /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

# Clean up apt cache to reduce image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Expose the default HTTP port for NGINX
EXPOSE 80
