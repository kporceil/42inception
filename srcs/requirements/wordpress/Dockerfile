FROM alpine:3.22

# php83            = l'interpréteur PHP 8.3
# php83-fpm        = PHP-FPM (le gestionnaire de processus FastCGI)
# php83-mysqli     = extension PHP pour se connecter à MySQL/MariaDB
# php83-phar       = nécessaire pour exécuter WP-CLI (archive PHP)
# php83-openssl    = pour les connexions sécurisées (WordPress l'utilise)
# php83-mbstring   = gestion des chaînes multi-octets (utf8, emojis...)
# php83-curl       = pour que WordPress puisse faire des requêtes HTTP
# php83-dom        = parsing XML/HTML (utilisé par WordPress en interne)
# php83-xml        = support XML
# php83-session    = gestion des sessions PHP (connexion admin WP)
# php83-tokenizer  = analyse syntaxique PHP (utilisé par certains plugins)
# wget             = pour télécharger WP-CLI
RUN apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-phar \
    php83-openssl \
    php83-mbstring \
    php83-curl \
    php83-dom \
    php83-xml \
    php83-session \
    php83-tokenizer \
    wget

# Sur Alpine, le binaire s'appelle "php83" pas "php"
# On crée un lien symbolique pour que "php" et "php-fpm" fonctionnent
RUN ln -sf /usr/bin/php83 /usr/bin/php \
    && ln -sf /usr/sbin/php-fpm83 /usr/sbin/php-fpm

# Télécharge WP-CLI et le rend exécutable
# WP-CLI est un fichier .phar (PHP Archive = exécutable PHP autonome)
RUN wget -O /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# Copie la config PHP-FPM personnalisée
COPY conf/www.conf /etc/php83/php-fpm.d/www.conf

# Copie le script d'initialisation
COPY tools/init_wp.sh /usr/local/bin/init_wp.sh
RUN chmod +x /usr/local/bin/init_wp.sh

# PHP-FPM écoute sur le port 9000 (protocole FastCGI, pas HTTP)
EXPOSE 9000

ENTRYPOINT ["init_wp.sh"]
