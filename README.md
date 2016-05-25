Build Nginx & OpenSSL
=====================

##License
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

##About this script
This script build the latest release of Nginx with the latest release of OpenSSL

- GeoIP
- IPV6
- HTTP2
- Threads AIO
- CHACHA20_POLY1305 support

##Dependencies
Build tools (included in the script)

##Designed for
Debian 8

##Installation
<code>cd /tmp && wget --no-check-certificate https://raw.githubusercontent.com/stylersnico/nginx-openssl-chacha/master/build.sh && chmod +x build.sh && ./build.sh</code>
