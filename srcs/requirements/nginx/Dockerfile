FROM alpine:3.22

# nginx    = le serveur web
# openssl  = pour générer le certificat SSL auto-signé
RUN apk add --no-cache nginx openssl

# Crée le répertoire où openssl stockera le certificat
RUN mkdir -p /etc/nginx/ssl

# Génère un certificat SSL auto-signé directement pendant le build
# req        = commande de gestion des certificats
# -x509      = génère un certificat auto-signé (pas une demande de signature)
# -nodes     = pas de mot de passe sur la clé privée (sinon nginx demanderait
#              le mot de passe au démarrage, impossible en container)
# -days 365  = valable 1 an
# -newkey rsa:2048 = génère une nouvelle clé RSA de 2048 bits
# -keyout    = fichier où écrire la clé privée
# -out       = fichier où écrire le certificat public
# -subj      = informations du certificat (évite le questionnaire interactif)
#   /C=FR    = Country
#   /ST=...  = State
#   /O=...   = Organization
#   /CN=...  = Common Name (doit correspondre au domain name)
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/key.pem \
    -out /etc/nginx/ssl/cert.pem \
    -subj "/C=FR/ST=Lyon/O=42/CN=kporceil.42.fr"

# Copie notre configuration NGINX
COPY conf/nginx.conf /etc/nginx/nginx.conf

# NGINX écoute uniquement sur le port 443 (HTTPS)
# Le port 80 (HTTP) n'est volontairement pas exposé
EXPOSE 443

# Lance NGINX en foreground
# "daemon off" = ne pas se mettre en background → NGINX devient PID 1
ENTRYPOINT ["nginx", "-g", "daemon off;"]
