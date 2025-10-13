FROM wordpress:php8.2-fpm

# Install PostgreSQL extension
RUN apt-get update && apt-get install -y less mariadb-client \
    libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql \
    && rm -rf /var/lib/apt/lists/*

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

# Copy the PostgreSQL database drop-in
COPY db.php /var/www/html/wp-content/

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html/