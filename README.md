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
This script build the latest release of Nginx with the latest release of OpenSSL

- GeoIP
- IPV6
- HTTP2 and NAXSI HTTP2 dev branch
- Threads AIO
- CHACHA20_POLY1305 support
- x25519 support
- TLS 1.3 support
- [Headers More](https://github.com/openresty/headers-more-nginx-module)

## Compatible configuration file

See https://github.com/stylersnico/nginx-secure-config

## Dependencies
Build tools (included in the script)

Thanks to https://github.com/hakasenyang/openssl-patch/blob/master/README.md

## Designed for
Debian 8 and Debian 9

## Installation
<code>cd /tmp && wget --no-check-certificate https://raw.githubusercontent.com/stylersnico/nginx-openssl-chacha/master/build.sh && sh build.sh</code>
