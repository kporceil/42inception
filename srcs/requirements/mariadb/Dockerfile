FROM alpine:3.22

RUN apk add --no-cache mariadb mariadb-client

RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

RUN rm -f /etc/my.cnf /etc/my.cnf.d/*.cnf
COPY conf/my.cnf /etc/my.cnf

COPY tools/init_db.sh /usr/local/bin/init_db.sh

RUN chmod +x /usr/local/bin/init_db.sh

EXPOSE 3306

ENTRYPOINT ["init_db.sh"]
