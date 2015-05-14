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
/var/cache/pkg	-network 10.0.0.0/24
EOF

service nfsd status || service nfsd start
service mountd status || service mountd start
service rpcbind status || service rpcbind start

echo "Installing php composer"

cd /usr/home/conan
test -f /usr/home/conan/composer.phar || sudo -u conan curl -sS https://getcomposer.org/installer | php
chown -R conan /usr/home/conan/composer.phar

echo "Setting up composer mirror"

test -f /usr/home/conan/satis || sudo -u conan \
	php composer.phar create-project composer/satis --stability=dev --keep-vcs

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
cp /vagrant/config/private-bower/private-bower-config.json /usr/home/conan/private-bower
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

