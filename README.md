Build Nginx, Naxsi & OpenSSL
============================

## License

Script for building the latest release of Nginx with the latest release of OpenSSL patched for CHACHA support
Copyleft (C) Nicolas Simond - 2016

This script is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This script is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this script.  If not, see <http://www.gnu.org/licenses/gpl.txt>

## About this script

This script build the latest release of Nginx with the latest release of OpenSSL 1.1.1 branch

- GeoIP
- IPV6
- HTTP2 and NAXSI (HTTP2) master branch
- Threads AIO
- CHACHA20_POLY1305 support
- x25519 support
- TLS 1.3 support
- [Headers More](https://github.com/openresty/headers-more-nginx-module)
- Brotli and Gzip compression
- Tweaks for FastCGI (PHP)

## Compatible configuration file

See https://github.com/stylersnico/nginx-secure-config

## Dependencies

Build tools (included in the script) like GCC, Git and misc lib


## Designed for
Debian 8,9 and 10

## Note about GCC, NAXSI and Debian 10

NAXSI need to be builded with GCC 8 in Debian 10, install with :

`apt install gcc g++`

If needed, you can switch between gcc7 (if it's already installed) and gcc8 :

```
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 1 --slave /usr/bin/g++ g++ /usr/bin/g++-8
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 2 --slave /usr/bin/g++ g++ /usr/bin/g++-7
update-alternatives --config gcc
```


## Installation

```
wget --no-check-certificate https://raw.githubusercontent.com/stylersnico/nginx-openssl-chacha/master/build.sh && sh build.sh
```
