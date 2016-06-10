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
        #Installing Nginx to get the init.d and systemd unit scripts ###only the first time
        apt-get update
        apt-get install curl libgeoip-dev nginx-full nginx nginx-common libxslt-dev libpcre3 libpcre3-dev build-essential zlib1g-dev libbz2-dev libssl-dev tar unzip curl git  -y
        
        #Removing
        apt-get remove nginx-full nginx nginx-common -y
fi

#Registering vars for NGINX modules
if [ $naxsi = "n" ]
then
	http2="--with-http_v2_module "
else
	http2=""
fi
		
if [ $naxsi = "y" ]
then
	naxsi="--add-module=../naxsi-0.55rc2/naxsi_src/ "
else
	naxsi=""
fi


#Cleaning old sources
cd /usr/src
rm -rf nginx*
rm -rf openssl*


#Download Latest nginx, nasxsi & OpenSSL, then extract.
latest_nginx=$(curl -L http://nginx.org/en/download.html | egrep -o "nginx\-[0-9.]+\.tar[.a-z]*" | head -n 1)

(curl -fLRO "https://www.openssl.org/source/openssl-1.0.2h.tar.gz" && tar -xaf "openssl-1.0.2h.tar.gz") &
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
latest_openssl=$(echo openssl-1.0.2*)
cd "${latest_openssl}"

#CHACHA20_POLY1305
wget https://raw.githubusercontent.com/cloudflare/sslconfig/master/patches/openssl__chacha20_poly1305_draft_and_rfc_ossl102g.patch
patch -p1 < openssl__chacha20_poly1305_draft_and_rfc_ossl102g.patch
./config

#Dynamic TLS Records
cd /usr/src
cd "${latest_nginx//.tar*}"
wget https://raw.githubusercontent.com/cloudflare/sslconfig/master/patches/nginx__dynamic_tls_records.patch
patch -p1 < nginx__dynamic_tls_records.patch
./config

#Configure NGINX & make & install
./configure \
$naxsi \
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
$http2 \
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
--with-ld-opt=-lrt

make
make install

#Add Naxsi core rules from sources
if [ $naxsi = "y" ]
then
	cp /usr/src/naxsi-0.55rc2/naxsi_config/naxsi_core.rules /etc/nginx/naxsi_core.rules
fi  

if [ $ft = "n" ]
then
        #Configure Nginx service
        systemctl unmask nginx.service
        mkdir /usr/local/etc/nginx
        mkdir /usr/local/etc/nginx/body
        service nginx stop
        service nginx start
        echo " You should reboot your server now"
fi

if [ $ft = "y" ]
then
        service nginx stop
        service nginx start
fi

#Auto delete the script at end
rm /tmp/build.sh
