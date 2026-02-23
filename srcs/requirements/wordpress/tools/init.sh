#!/bin/bash

# Attendre que MariaDB soit disponible
sleep 5

# Créer wp-config.php uniquement s'il n'existe pas déjà
if [ ! -f /var/www/html/wp-config.php ]; then
    wp config create \
        --allow-root \
        --path=/var/www/html \
        --dbname=$MYSQL_DATABASE \
        --dbuser=$MYSQL_USER \
        --dbpass=$MYSQL_PASSWORD \
        --dbhost=mariadb:3306
fi

# Installer WordPress uniquement s'il ne l'est pas déjà (idempotent au redémarrage)
if ! wp core is-installed --allow-root --path=/var/www/html; then
    wp core install \
        --allow-root \
        --path=/var/www/html \
        --url=$DOMAIN_NAME \
        --title=$WP_TITLE \
        --admin_user=$WP_ADMIN \
        --admin_password=$WP_ADMIN_PASSWORD \
        --admin_email=$WP_ADMIN_EMAIL \
        --skip-email

    # Créer un utilisateur standard
    wp user create \
        --allow-root \
        --path=/var/www/html \
        $WP_USER $WP_USER_EMAIL \
        --user_pass=$WP_USER_PASSWORD \
        --role=author
fi

# Créer le dossier run pour php-fpm
mkdir -p /run/php

# Lancer php-fpm en premier plan
exec php-fpm7.4 -F
