#!/bin/bash
# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi
# exit when any command fails
set -e

clear

#Set modules
echo "Did you run this script before? (y/n)"
read ft

echo "Do you want NAXSI WAF (still experimental)? (y/n)"
read naxsi


#Asking if the script was launched once
if [ $ft = "n" ]
then
        #Installing building tools
        apt-get update
        apt-get install libgeoip-dev libxslt-dev libpcre3 libpcre3-dev build-essential zlib1g-dev libbz2-dev libssl-dev tar unzip curl git  -y
fi


if [ $naxsi = "y" ]
then
	ngx_naxsi="--add-module=../naxsi/naxsi_src/ "
else
	ngx_naxsi=""
fi


#Cleaning old sources
cd /usr/src
rm -rf nginx*
rm -rf openssl*
rm -rf ngx_brotli

#Download Latest nginx, nasxsi & OpenSSL, then extract.
latest_nginx=$(curl -L http://nginx.org/en/download.html | egrep -o "nginx\-[0-9.]+\.tar[.a-z]*" | head -n 1)
git clone https://github.com/openssl/openssl.git --branch OpenSSL_1_1_1-stable
(curl -fLRO "http://nginx.org/download/${latest_nginx}" && tar -xaf "${latest_nginx}") &
(curl -fLRO "https://github.com/openresty/headers-more-nginx-module/archive/v0.33.tar.gz" && tar -xaf "v0.33.tar.gz") &


#Download Naxsi if wanted
if [ $naxsi = "y" ]
then
	rm -rf naxsi*
	git clone https://github.com/nbs-system/naxsi.git --branch master
fi
wait

#Download Brotli
git clone https://github.com/google/ngx_brotli
cd ngx_brotli
git submodule update --init


#Cleaning
rm /usr/src/*.tar.gz

#Configure NGINX & make & install
cd /usr/src
cd nginx-*
./configure --with-openssl=/usr/src/openssl --with-openssl-opt=enable-tls1_3 --with-ld-opt=-lrt \
$ngx_naxsi \
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

#Add Naxsi core rules from sources
if [ $naxsi = "y" ]
then
	cp /usr/src/naxsi/naxsi_config/naxsi_core.rules /etc/nginx/naxsi_core.rules
fi

if [ $ft = "n" ]
then
	# Installing init.d scripts
	cd /etc/init.d/
	rm nginx && nginx-debug -f
	wget https://raw.githubusercontent.com/stylersnico/nginx-openssl-chacha-naxsi/master/misc/init.d/nginx
	wget https://raw.githubusercontent.com/stylersnico/nginx-openssl-chacha-naxsi/master/misc/init.d/nginx-debug
	chmod +x nginx && chmod +x nginx-debug

	# Installing systemd unit
	cd /lib/systemd/system/
	rm nginx.service -f
	wget https://raw.githubusercontent.com/stylersnico/nginx-openssl-chacha-naxsi/master/misc/systemd/system/nginx.service
	chmod +x nginx.service
	systemctl enable nginx

	# Installing logrotate configuration
	cd /etc/logrotate.d/
	rm nginx -f
	wget https://raw.githubusercontent.com/stylersnico/nginx-openssl-chacha-naxsi/master/misc/logrotate.d/nginx

	# Nginx's cache directory case of
	mkdir -p /usr/local/etc/nginx/

	#NGINX Configuration
	cd /etc/nginx/
	rm nginx.conf
	wget https://raw.githubusercontent.com/stylersnico/nginx-secure-config/master/nginx.conf

	service nginx stop
    service nginx start
fi

if [ $ft = "y" ]
then
        service nginx stop
        service nginx start
fi
