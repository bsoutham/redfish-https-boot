FROM nginx:1.18.0

COPY cert.pem /etc/ssl/certs/nginx-selfsigned.crt
COPY cert.key  /etc/ssl/private/nginx-selfsigned.key

COPY nginx.conf /etc/nginx/nginx.conf

WORKDIR /var/www/

COPY root/* .
