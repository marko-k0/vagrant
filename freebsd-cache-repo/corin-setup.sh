echo "Corin is up and running!"

mkdir proj
cd proj
cp /vagrant/config/composer/composer.json .
cp /vagrant/config/private-bower/bower.json .
cp /vagrant/config/sinopia/package.json .
cp /vagrant/config/private-bower/.bowerrc .

echo "Setting npm registry"
npm set registry "http://10.0.0.2:4873"

chown -R vagrant .


