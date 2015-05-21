echo "Conan is up and running!"

echo "Adding user conan"

pw user show conan >& /dev/null || pw useradd -n conan -g operators -s /bin/csh -m

echo "Installing required packages"

pkg install -y gmake lang/gcc48 
pkg install -y subversion
test -f /usr/local/bin/gcc || ln -s /usr/local/bin/gcc48 /usr/local/bin/gcc
test -f /usr/local/bin/g++ || ln -s /usr/local/bin/g++48 /usr/local/bin/g++

echo "Enabling NFS"

grep -q -F 'nfs_server_enable="YES"' /etc/rc.conf || cat <<'EOF'>> /etc/rc.conf
nfs_server_enable="YES"
nfs_server_flags="-u -t -n 6"
rpcbind_enable="YES"
mountd_flags="-r"
mountd_enable="YES"
EOF

grep -q -F '/var/cache/pkg' /etc/exports &> /dev/null || cat <<'EOF'>> /etc/exports
/var/cache/pkg -maproot=0 -network 10.0.0.0/24
EOF

service nfsd status || service nfsd start
service mountd status || service mountd start
service rpcbind status || service rpcbind start

echo "Installing php composer"

cd /usr/home/conan
test -f /usr/home/conan/composer.phar || sudo -u conan curl -sS https://getcomposer.org/installer | php >& /dev/null
chown -R conan /usr/home/conan/composer.phar

echo "Setting up composer mirror (satis)"

test -f /usr/home/conan/satis || sudo -u conan \
	php composer.phar create-project composer/satis --stability=dev --keep-vcs >& /dev/null

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
  ./configure --prefix=/usr/local/etc/nginx --with-cc-opt='-I /usr/local/include' --with-ld-opt='-L /usr/local/lib' \
    --conf-path=/usr/local/etc/nginx/nginx.conf --sbin-path=/usr/local/sbin/nginx --pid-path=/var/run/nginx.pid \
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
  cp /vagrant/config/satis/mirrored-packages.json /home/conan/
  mkdir -p /home/conan/satis-mirrored-packages
  chown -R conan /home/conan

  cp /vagrant/config/satis/nginx.conf /usr/local/etc/nginx/nginx.conf
  cp /vagrant/config/satis/nginx /usr/local/etc/rc.d/
  chmod 770 /usr/local/etc/rc.d/nginx
fi

grep -q -F 'nginx_enable="YES"' /etc/rc.conf || cat <<'EOF'>> /etc/rc.conf
nginx_enable="YES"
EOF

service nginx status || service nginx start

echo "Setting up npm mirror (sinopia)"

test -f /usr/local/bin/sinopia || npm install -g sinopia
test -f /usr/bin/node || ln -s /usr/local/bin/node /usr/bin/node
mkdir -p /usr/home/conan/sinopia/storage
cp /vagrant/config/sinopia/config.yaml /usr/home/conan/sinopia
chown -R conan /usr/home/conan/sinopia
chmod 764 /usr/home/conan/sinopia

#https://github.com/rlidwka/sinopia
#https://blog.dylants.com/2014/05/10/creating-a-private-npm-registry-with-sinopia/
#http://thejackalofjavascript.com/maintaining-a-private-npm-registry/

echo "Setting up bower mirror (private-bower)"

test -f /usr/local/bin/private-bower || npm install -g private-bower
mkdir -p /usr/home/conan/private-bower
cp /vagran    t/config/private-bower/private-bower-config.json /usr/home/conan/private-bower
chown -R conan /usr/home/conan/private-bower
chmod 764 /usr/home/conan/private-bower

#https://www.npmjs.com/package/private-bower

echo "Configuring sinopia and private-bower to run forever"

test -f /usr/local/bin/forever || npm install -g forever
touch /var/log/sinopia.log
touch /var/log/private-bower.log
chown daemon:daemon /var/log/sinopia.log
chown daemon:daemon /var/log/private-bower.log

forever list | grep sinopia >& /dev/null || forever start \
	-l /var/log/sinopia.log -a --pidFile /var/run/sinopia.pid --uid "daemon" \
	/usr/local/bin/sinopia -c /home/conan/sinopia/config.yaml

forever list | grep private-bower >& /dev/null || forever start \
	-l /var/log/private-bower.log -a --pidFile /var/run/private-bower.pid --uid "daemon" \
	/usr/bin/private-bower --config /usr/home/conan/private-bower/private-bower-config.json

echo "All done"
echo "Run 'php /usr/home/conan/satis/bin/satis build /usr/home/conan/mirrored-packages.json /usr/home/conan/satis-mirrored-packages/' as conan'"
