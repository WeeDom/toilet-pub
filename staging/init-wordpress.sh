#!/bin/bash
set -e

cd /var/www/html

echo "🏁 Initialising WordPress container..."

# Ensure WordPress core files exist
if [ ! -f "wp-settings.php" ]; then
  echo "📦 Downloading WordPress core..."
  wp core download --allow-root
fi

# Activate WordPress Importer (handy for XML imports)
if ! wp plugin is-installed wordpress-importer --allow-root; then
  echo "📥 Installing WordPress Importer..."
  wp plugin install wordpress-importer --activate --allow-root
else
  wp plugin activate wordpress-importer --allow-root
fi

if wp plugin is-installed akismet --allow-root; then
  echo "📥 Removing Akismet..."
  wp plugin delete akismet --allow-root
fi

if wp plugin is-installed hello.php --allow-root; then
  echo "📥 Removing Dolly..."
  wp plugin delete hello.php --allow-root
fi
# Correct permissions so uploads and themes are writable
echo "🧹 Fixing permissions..."
chown -R www-data:www-data /var/www/html

# Hand over to the normal WordPress PHP-FPM entrypoint
echo "🚀 Starting PHP-FPM..."
exec docker-entrypoint.sh php-fpm
