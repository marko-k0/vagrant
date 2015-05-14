echo "Tamara is up and running!"

echo "Mounting conan's nfs pkg cache"
mkdir -p /mnt/cache/pkg
mount -v 10.0.0.2:/var/cache/pkg /mnt/cache/pkg

sed -i '' -e 's/^#PKG_CACHEDIR/PKG_CACHEDIR/g' /usr/local/etc/pkg.conf
sed -i '' -e 's$/var/cache/pkg$/mnt/cache/pkg$g' /usr/local/etc/pkg.conf

mkdir -p /usr/home/vagrant/proj
cd /usr/home/vagrant/proj
cp /vagrant/config/composer/composer.json /usr/home/vagrant/proj
cp /vagrant/config/private-bower/bower.json /usr/home/vagrant/proj
cp /vagrant/config/private-bower/.bowerrc /usr/home/vagrant/proj
cp /vagrant/config/sinopia/package.json /usr/home/vagrant/proj
cp /vagrant/config/sinopia/.npmrc /usr/home/vagrant/
chown -R vagrant /usr/home/vagrant

echo "Setting npm registry"
npm set registry "http://10.0.0.2:4873"

