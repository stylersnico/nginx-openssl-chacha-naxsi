#!/bin/bash
#Custom script for update with Ansible
#Warning, it built Naxsi by default

# exit when any command fails
set -e

#Cleaning old sources
cd /usr/src
rm -rf nginx*
rm -rf openssl*
rm -rf naxsi*
rm -rf ngx_brotli

#Download Latest nginx, nasxsi & OpenSSL, then extract.
latest_nginx=$(curl -L http://nginx.org/en/download.html | egrep -o "nginx\-[0-9.]+\.tar[.a-z]*" | head -n 1)
git clone https://github.com/openssl/openssl.git --branch OpenSSL_1_1_1-stable
(curl -fLRO "http://nginx.org/download/${latest_nginx}" && tar -xaf "${latest_nginx}") &
(curl -fLRO "https://github.com/openresty/headers-more-nginx-module/archive/v0.33.tar.gz" && tar -xaf "v0.33.tar.gz") &
git clone https://github.com/nbs-system/naxsi.git --branch master


#Download Brotli
git clone https://github.com/google/ngx_brotli
cd ngx_brotli
git submodule update --init

#Cleaning
rm /usr/src/*.tar.gz

#Configure NGINX & make & install
cd /usr/src/nginx-*
./configure --with-openssl=/usr/src/openssl --with-openssl-opt=enable-tls1_3 --with-ld-opt=-lrt \
--add-module=../naxsi/naxsi_src/ \
--http-client-body-temp-path=/usr/local/etc/nginx/body \
--http-fastcgi-temp-path=/usr/local/etc/nginx/fastcgi \
--http-proxy-temp-path=/usr/local/etc/nginx/proxy \
--http-scgi-temp-path=/usr/local/etc/nginx/scgi \
--http-uwsgi-temp-path=/usr/local/etc/nginx/uwsgi \
--user=www-data \
--group=www-data \
--prefix=/etc/nginx \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
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
--add-module=../headers-more-nginx-module-0.33 \
--add-module=../ngx_brotli

make -j $(nproc)
make install

service nginx stop
service nginx start
