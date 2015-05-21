echo "Corin is up and running!"

echo "Mounting conan's nfs pkg cache"
mkdir -p /mnt/cache/pkg
mount -v 10.0.0.2:/var/cache/pkg /mnt/cache/pkg

sed -i '' -e 's/^#PKG_CACHEDIR/PKG_CACHEDIR/g' /usr/local/etc/pkg.conf
sed -i '' -e 's$/var/cache/pkg$/mnt/cache/pkg$g' /usr/local/etc/pkg.conf

cp /vagrant/config/satis/composer.json .
cp /vagrant/config/private-bower/bower.json .
cp /vagrant/config/private-bower/.bowerrc .
cp /vagrant/config/sinopia/package.json .
cp /vagrant/config/sinopia/.npmrc /root
cp /vagrant/config/sinopia/.npmrc .

#echo "Setting npm registry"
#npm set registry "http://10.0.0.2:4873"

chown -R vagrant .
route del default
