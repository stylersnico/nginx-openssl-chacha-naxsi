#!/bin/bash
# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi

clear && clear

#Asking user for modules
echo "Did you run this script before? (y/n)"
read ft

echo "Do you want NAXSI WAF (this disable HTTP2 support)? (y/n)"
read naxsi


#Asking if the script was launched once
if [ $ft = "n" ]
then
        #Installing building tools
        apt-get update
        apt-get install curl libgeoip-dev libxslt-dev libpcre3 libpcre3-dev build-essential zlib1g-dev libbz2-dev libssl-dev tar unzip curl git  -y
fi

#Registering vars for NGINX modules
if [ $naxsi = "n" ]
then
	ngx_http2="--with-http_v2_module "
	ngx_spdy="--with-http_spdy_module "
else
	ngx_http2=""
	ngx_spdy=""
fi

if [ $naxsi = "y" ]
then
	ngx_naxsi="--add-module=../naxsi-0.55rc2/naxsi_src/ "
else
	ngx_naxsi=""
fi


#Cleaning old sources
cd /usr/src
rm -rf nginx*
rm -rf openssl*


#Download Latest nginx, nasxsi & OpenSSL, then extract.
latest_nginx=$(curl -L http://nginx.org/en/download.html | egrep -o "nginx\-[0-9.]+\.tar[.a-z]*" | head -n 1)
(curl -fLRO "https://www.openssl.org/source/openssl-1.1.0.tar.gz" && tar -xaf "openssl-1.1.0.tar.gz") &
(curl -fLRO "http://nginx.org/download/${latest_nginx}" && tar -xaf "${latest_nginx}") &


#Download Naxsi if wanted
if [ $naxsi = "y" ]
then
	rm -rf naxsi*
	wget https://github.com/nbs-system/naxsi/archive/0.55rc2.tar.gz && tar -xaf 0.55rc2.tar.gz
fi
wait

#Cleaning
rm /usr/src/*.tar.gz

#Patch OpenSSL
latest_openssl=$(echo openssl-1.1.0*)
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
if [ $naxsi = "n" ]
then
	wget https://raw.githubusercontent.com/felixbuenemann/sslconfig/updated-nginx-1.9.15-spdy-patch/patches/nginx_1_9_15_http2_spdy.patch
	patch -p1 < nginx_1_9_15_http2_spdy.patch
fi


#Configure NGINX & make & install
./config
./configure \
$ngx_naxsi \
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
$ngx_http2 \
$ngx_spdy \
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

#Add Naxsi core rules from sources
if [ $naxsi = "y" ]
then
	cp /usr/src/naxsi-0.55rc2/naxsi_config/naxsi_core.rules /etc/nginx/naxsi_core.rules
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

#Auto delete the script at end
rm /tmp/build.sh
