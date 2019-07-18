FROM alpine

ENV SYS_GROUP postgres
ENV SYS_USER postgres


RUN set -eux; \
	getent group ${SYS_GROUP} || addgroup -S ${SYS_GROUP}; \
	getent passwd ${SYS_USER} || adduser -S ${SYS_USER}  -G ${SYS_GROUP} -s "/bin/sh";

ENV PGPOOL_VERSION 4.0.5

ENV PG_POOL_INSTALL_PATH  /opt/pgpool

ENV PG_VERSION 11.4-r0

ENV LANG C

RUN apk update && apk upgrade \
  &&  apk --update --no-cache add curl build-base binutils  flex bison opensp openjade perl libxml2-utils docbook2x libbsd musl-dev bind-dev libpq postgresql-dev postgresql-client openssl-dev \
                                linux-headers gcc make libgcc g++ file imagemagick-dev libjpeg-turbo-dev libpng-dev  \
                                libffi-dev py-setproctitle python python2 python2-dev python-dev py2-pip  tzdata openntpd ca-certificates openssl openssh git dos2unix && \
    mkdir -p  ${PG_POOL_INSTALL_PATH} &&  \
    cd ${PG_POOL_INSTALL_PATH} && \
    wget https://www.pgpool.net/download.php?f=pgpool-II-${PGPOOL_VERSION}.tar.gz -O - | tar -xz  --directory  ${PG_POOL_INSTALL_PATH}  --strip-components=1 --no-same-owner && \
    cd ${PG_POOL_INSTALL_PATH} && \
    ./configure --prefix=/usr \
                --sysconfdir=/etc \
                --mandir=/usr/share/man \
                --infodir=/usr/share/info \
                --with-openssl && \
    make && \
    make install && \
    rm -rf ${PG_POOL_INSTALL_PATH} && \
    apk del postgresql-dev linux-headers gcc make libgcc g++ build-base binutils  flex bison opensp openjade perl libxml2-utils docbook2x libbsd musl-dev bind-dev  file imagemagick-dev libjpeg-turbo-dev libpng-dev libffi-dev openssh git openntpd tzdata

RUN pip install Jinja2

RUN mkdir /etc/pgpool2 /var/run/pgpool /var/log/pgpool /var/run/postgresql /var/log/postgresql/ && \
    chown ${SYS_USER}:${SYS_GROUP} -R /etc/pgpool2 /var/run/pgpool /var/log/pgpool /var/run/postgresql /var/log/postgresql

# Post Install Configuration.
ADD bin/configure-pgpool2.py /usr/bin/configure-pgpool2
RUN dos2unix /usr/bin/configure-pgpool2
RUN chmod +x /usr/bin/configure-pgpool2

ADD conf/pcp.conf.template /usr/share/pgpool2/pcp.conf.template
ADD conf/pgpool.conf.template /usr/share/pgpool2/pgpool.conf.template

# Start the container.
COPY script/docker-entrypoint.sh /
RUN dos2unix /docker-entrypoint.sh && apk del dos2unix
#make sure the file can be executed
RUN ["chmod", "+x", "/docker-entrypoint.sh"]
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 9999 9898

CMD ["pgpool","-n", "-f", "/etc/pgpool2/pgpool.conf", "-F", "/etc/pgpool2/pcp.conf"]