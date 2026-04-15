#!/bin/sh

# "set -e" = le script s'arrête immédiatement si une commande échoue
# C'est une bonne pratique pour détecter les erreurs tôt
set -e

# ------------------------------------------------------------
# LECTURE DES SECRETS
# Les mots de passe sont montés en tant que fichiers dans /run/secrets/
# On les lit avec "cat" et on les stocke dans des variables locales
# ------------------------------------------------------------
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# ------------------------------------------------------------
# INITIALISATION (seulement si la DB n'existe pas encore)
# On vérifie si le dossier de notre base WordPress existe.
# Ce dossier est créé lors du premier "CREATE DATABASE".
# Si le volume est vide (premier démarrage), on initialise tout.
# Si le volume a déjà des données, on skippe (les données persistent).
# ------------------------------------------------------------
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then

    echo "[MariaDB] First start detected — initializing database..."

    # mysql_install_db : initialise les fichiers système de MariaDB
    # (crée la base "mysql" interne, les tables de privilèges, etc.)
    # --user=mysql : les fichiers appartiennent à l'utilisateur mysql
    # --datadir    : là où MariaDB stocke les données (monté sur le volume)
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # On démarre mysqld temporairement en background pour pouvoir
    # exécuter des commandes SQL d'initialisation.
    # --skip-networking : pas de connexion réseau pendant l'init (sécurité)
    # & = lancement en background
    mysqld --user=mysql --skip-networking &
    TEMP_PID=$!

    # On attend que le serveur soit prêt à recevoir des connexions.
    # mysqladmin ping retourne 0 quand le serveur répond.
    echo "[MariaDB] Waiting for server to be ready..."
    until mysqladmin ping --silent; do
        sleep 1
    done

    echo "[MariaDB] Server ready. Running setup SQL..."

    # On exécute les commandes SQL d'initialisation via un heredoc.
    # mysql -u root : connexion en root (pas encore de mot de passe au premier démarrage)
    mysql -u root << EOF

-- Crée la base de données WordPress
-- CHARACTER SET et COLLATE : définit l'encodage (utf8mb4 = support emojis + unicode complet)
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

-- Crée l'utilisateur WordPress avec son mot de passe
-- '%' signifie "depuis n'importe quel hôte" (nécessaire car WordPress est dans un autre container)
CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- Donne tous les droits à l'utilisateur WordPress sur sa base uniquement
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%';

-- Définit le mot de passe root
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Supprime les utilisateurs anonymes (sécurité)
DELETE FROM mysql.user WHERE User='';

-- Applique les changements de privilèges immédiatement
FLUSH PRIVILEGES;

EOF

    echo "[MariaDB] Setup complete. Stopping temporary server..."

    # Arrête le serveur temporaire proprement
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

    # Attend que le processus temporaire soit bien terminé
    wait $TEMP_PID

    echo "[MariaDB] Initialization done."
fi

# ------------------------------------------------------------
# LANCEMENT FINAL : mysqld en foreground = PID 1 du container
# --user=mysql       : mysqld tourne sous l'utilisateur mysql (pas root)
# --datadir          : répertoire des données (notre volume)
# --bind-address=0.0.0.0 : écoute sur toutes les interfaces réseau
#                          (nécessaire pour que WordPress puisse se connecter)
# exec remplace le shell par mysqld → mysqld devient PID 1
# ------------------------------------------------------------
echo "[MariaDB] Starting MariaDB server..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0
