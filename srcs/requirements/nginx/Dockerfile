FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

# Copie la configuration Nginx en tant que template
COPY ./conf/nginx.conf /etc/nginx/nginx.conf.template

EXPOSE 443

# Génère le certificat SSL avec le bon DOMAIN_NAME (disponible au runtime)
# puis applique envsubst sur le template nginx et lance nginx
CMD ["sh", "-c", "\
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/nginx.key \
        -out /etc/ssl/certs/nginx.crt \
        -subj \"/C=FR/ST=IDF/L=Paris/O=42/CN=${DOMAIN_NAME}\" && \
    envsubst '${DOMAIN_NAME}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && \
    nginx -g 'daemon off;'"]
