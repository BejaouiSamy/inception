#!/bin/bash

# Démarre mysqld temporairement en arriere plan (&) pour l'initialisation
mysqld_safe --user=mysql &

# Attendre que MariaDB soit prêt
sleep 3

# Initialisation
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
EOF

# Arrête le mysqld temporaire
mysqladmin -u root shutdown

# Lance mysqld en "premier plan" (remplace le process shell)
exec mysqld --user=mysql