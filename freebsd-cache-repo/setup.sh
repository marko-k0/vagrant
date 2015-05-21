echo "Adding users and groups"
pw group show operators >& /dev/null || pw groupadd operators 

echo "Installing misc packages"
pkg install -y vim curl wget git mercurial
pkg install -y curl wget
pkg install -y openssl php56-json php56-phar php56-filter php56-hash php56-openssl php56-ctype php56-dom php56-tokenizer
pkg install -y npm
npm install -g bower

test -f /etc/ssl/cert.pem || ln -s /usr/local/etc/ssl/cert.pem /etc/ssl/cert.pem
cp /usr/share/zoneinfo/America/Vancouver /etc/localtime

echo "Installing php composer"
test -f /usr/home/vagrant/composer.phar || curl -sS https://getcomposer.org/installer | php

cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
sed -r -i ' ' "s/^;date\.timezone =.*/date\.timezone = America\/Vancouver/" /usr/local/etc/php.ini

