#!/bin/bash
#Custom script for update with Ansible


#Cleaning old sources
cd /usr/src
rm -rf nginx*
rm -rf openssl*


#Download Latest nginx, nasxsi & OpenSSL, then extract.
latest_nginx=$(curl -L http://nginx.org/en/download.html | egrep -o "nginx\-[0-9.]+\.tar[.a-z]*" | head -n 1)
(curl -fLRO "https://www.openssl.org/source/openssl-1.1.0c.tar.gz" && tar -xaf "openssl-1.1.0c.tar.gz") &
(curl -fLRO "http://nginx.org/download/${latest_nginx}" && tar -xaf "${latest_nginx}") &
wait

#Cleaning
rm /usr/src/*.tar.gz

#Patch OpenSSL
latest_openssl=$(echo openssl-1.1.0*)
cd "${latest_openssl}"


#Dynamic TLS Records
cd /usr/src
cd "${latest_nginx//.tar*}"
wget https://raw.githubusercontent.com/cujanovic/nginx-dynamic-tls-records-patch/master/nginx__dynamic_tls_records_1.11.5%2B.patch
patch -p1 < nginx__dynamic_tls_records_1.11.5*.patch

#Configure NGINX & make & install
./config
./configure \
--http-client-body-temp-path=/usr/local/etc/nginx/body \
--http-fastcgi-temp-path=/usr/local/etc/nginx/fastcgi \
--http-proxy-temp-path=/usr/local/etc/nginx/proxy \
--http-scgi-temp-path=/usr/local/etc/nginx/scgi \
--http-uwsgi-temp-path=/usr/local/etc/nginx/uwsgi \
--user=www-data \
--group=www-data \
--prefix=/etc/nginx \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--pid-path=/usr/local/etc/nginx.pid \
--lock-path=/usr/local/etc/nginx.lock \
--with-pcre-jit \
--with-http_v2_module \
--with-debug \
--with-http_stub_status_module \
--with-http_realip_module \
--with-http_addition_module \
--with-http_dav_module \
--with-http_gzip_static_module \
--with-http_sub_module \
--with-http_xslt_module \
--with-file-aio \
--with-threads \
--with-http_ssl_module \
--with-http_geoip_module \
--with-openssl=/usr/src/${latest_openssl} \
--with-ld-opt=-lrt \

make
make install

service nginx stop
service nginx start
