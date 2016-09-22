#!/bin/bash
#Custom script for update with Ansible


#Cleaning old sources
cd /usr/src
rm -rf nginx*
rm -rf openssl*


#Download Latest nginx, nasxsi & OpenSSL, then extract.
latest_nginx=$(curl -L http://nginx.org/en/download.html | egrep -o "nginx\-[0-9.]+\.tar[.a-z]*" | head -n 1)
(curl -fLRO "https://www.openssl.org/source/openssl-1.1.0a.tar.gz" && tar -xaf "openssl-1.1.0a.tar.gz") &
(curl -fLRO "http://nginx.org/download/${latest_nginx}" && tar -xaf "${latest_nginx}") &
wait

#Cleaning
rm /usr/src/*.tar.gz

#Patch OpenSSL
latest_openssl=$(echo openssl-1.1.0a*)
cd "${latest_openssl}"


#Dynamic TLS Records
cd /usr/src
cd "${latest_nginx//.tar*}"
wget https://raw.githubusercontent.com/cloudflare/sslconfig/master/patches/nginx__dynamic_tls_records.patch
patch -p1 < nginx__dynamic_tls_records.patch

#Patch for OpenSSL 1.1.0 support
wget https://raw.githubusercontent.com/stylersnico/nginx-openssl-chacha-naxsi/master/misc/0001-Fix-nginx-build.patch
patch -p1 < 0001-Fix-nginx-build.patch

#Add support for SPDY+HTTP2 patch from cloudflare
wget https://raw.githubusercontent.com/felixbuenemann/sslconfig/updated-nginx-1.9.15-spdy-patch/patches/nginx_1_9_15_http2_spdy.patch
patch -p1 < nginx_1_9_15_http2_spdy.patch

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
--with-ipv6 \
--with-http_v2_module \
--with-http_spdy_module \
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
