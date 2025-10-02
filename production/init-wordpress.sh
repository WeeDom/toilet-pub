#!/bin/bash
set -e

echo "Installing PostgreSQL DB driver for WordPress..."

cd /var/www/html/wp-content
mkdir -p db.php
cd /tmp
curl -fsSL https://raw.githubusercontent.com/kevinoid/wp-postgresql/master/db.php -o /var/www/html/wp-content/db.php

chown www-data:www-data /var/www/html/wp-content/db.php

echo "✅ PostgreSQL DB driver installed."
