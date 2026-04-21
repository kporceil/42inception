FROM alpine:3.22

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

RUN ln -sf /usr/bin/php83 /usr/bin/php \
    && ln -sf /usr/sbin/php-fpm83 /usr/sbin/php-fpm

RUN wget -O /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

COPY conf/www.conf /etc/php83/php-fpm.d/www.conf

COPY tools/init_wp.sh /usr/local/bin/init_wp.sh
RUN chmod +x /usr/local/bin/init_wp.sh

EXPOSE 9000

ENTRYPOINT ["init_wp.sh"]
