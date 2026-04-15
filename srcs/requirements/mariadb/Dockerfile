FROM alpine:3.22

# apk = gestionnaire de paquets Alpine (équivalent apt sur Debian)
# mariadb       = le serveur de base de données
# mariadb-client = outils en ligne de commande (mysqladmin, mysql...)
# --no-cache = ne pas garder le cache apk dans l'image (réduit la taille)
RUN apk add --no-cache mariadb mariadb-client

# Crée le répertoire du socket mysqld (Alpine ne le crée pas automatiquement)
# et donne les droits à l'utilisateur mysql
RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

# Copie la config MariaDB
COPY conf/my.cnf /etc/my.cnf.d/inception.cnf

# Copie notre script d'initialisation dans l'image
COPY tools/init_db.sh /usr/local/bin/init_db.sh

RUN chmod +x /usr/local/bin/init_db.sh

EXPOSE 3306

ENTRYPOINT ["init_db.sh"]
