# vim: ft=sh

echo "Adding users and groups"
pw group show operators >& /dev/null || pw groupadd operators
pw usermod vagrant -G operators

echo "Installing misc packages"
pkg install -y vim curl wget git php56 rsync
pkg install -y openssl php56-json php56-phar php56-filter php56-hash php56-openssl php56-ctype php56-dom php56-tokenizer php56-simplexml php56-curl
pkg install -y gmake lang/gcc48
test -f /usr/local/bin/gcc || ln -s /usr/local/bin/gcc48 /usr/local/bin/gcc
test -f /usr/local/bin/g++ || ln -s /usr/local/bin/g++48 /usr/local/bin/g++

cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
sed -r -i ' ' "s/^;date\.timezone =.*/date\.timezone = America\/Vancouver/" /usr/local/etc/php.ini

if [ -e /tmp/nginx-1.6.3.tar.gz ]; then
  echo "Nginx is already installed"
else
  echo "Installing nginx"

  cd /tmp
  wget --no-check-certificate http://zlib.net/zlib-1.2.8.tar.gz >& /dev/null
  tar xzf zlib-1.2.8.tar.gz
  wget --no-check-certificate http://nginx.org/download/nginx-1.6.3.tar.gz >& /dev/null
  tar xzf nginx-1.6.3.tar.gz
  cd nginx-1.6.3
  ./configure --prefix=/usr/local/etc/nginx --with-cc-opt='-I /usr/local/include' \
  --with-ld-opt='-L /usr/local/lib' --conf-path=/usr/local/etc/nginx/nginx.conf \
  --sbin-path=/usr/local/sbin/nginx --pid-path=/var/run/nginx.pid \
  --error-log-path=/var/log/nginx-error.log --user=www --group=www --with-ipv6 \
  --http-client-body-temp-path=/var/tmp/nginx/client_body_temp \
  --http-fastcgi-temp-path=/var/tmp/nginx/fastcgi_temp --http-proxy-temp-path=/var/tmp/nginx/proxy_temp \
  --http-scgi-temp-path=/var/tmp/nginx/scgi_temp --http-uwsgi-temp-path=/var/tmp/nginx/uwsgi_temp \
  --http-log-path=/var/log/nginx-access.log --with-http_stub_status_module --with-pcre \
  --with-http_ssl_module --with-http_spdy_module --without-mail_smtp_module \
  --with-zlib=../zlib-1.2.8 > /dev/null
  make > /dev/null
  make install clean > /dev/null
  mkdir -p /var/log/nginx
  chmod 755 /var/log/nginx
  chown root:operators /var/log/nginx

  cp /vagrant/config/nginx.conf /usr/local/etc/nginx/nginx.conf
  cp /vagrant/config/nginx /usr/local/etc/rc.d/
  chmod 770 /usr/local/etc/rc.d/nginx

fi

grep -q -F 'nginx_enable="YES"' /etc/rc.conf || cat <<'EOF'>> /etc/rc.conf
nginx_enable="YES"
php_fpm_enable="YES"
EOF

echo "Installing php composer"
cd /tmp
test -f /tmp/composer.phar || curl -sS https://getcomposer.org/installer | php

if [ -e /var/www/vagrant ]; then
  echo "Vagrant catalog already in place"
else
  echo "Cloning vagrant catalog"
  mkdir -p /var/www
  cd /var/www
  git clone https://github.com/vube/vagrant-catalog vagrant
  cd vagrant
  cp config.php.dist config.php
  mkdir files
  chmod 775 files
  chgrp operators files
  mkdir /var/log/vagrant
  /tmp/composer.phar update
fi

service php-fpm status || service php-fpm start
service nginx status || service nginx start

