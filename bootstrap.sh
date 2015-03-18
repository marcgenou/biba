#!/usr/bin/env bash

apt-add-repository -y ppa:brightbox/ruby-ng
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
'deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main' | sudo tee /etc/apt/sources.list.d/passenger.list
chown root: /etc/apt/sources.list.d/passenger.list
chmod 600 /etc/apt/sources.list.d/passenger.list
apt-get update
debconf-set-selections <<< 'mysql-server mysql-server/root_password password biba'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password biba'
apt-get install -y build-essential libssl-dev libyaml-dev libreadline-dev openssl curl git-core zlib1g-dev bison libxml2-dev libxslt1-dev libcurl4-openssl-dev libsqlite3-dev ruby2.2 ruby2.2-dev curl git libmysqlclient-dev mysql-server nodejs apache2 libapache2-mod-passenger
echo "<VirtualHost *:80>" > /etc/apache2/sites-available/testapp.conf
echo "    ServerAdmin webmaster@localhost" >> /etc/apache2/sites-available/testapp.conf
echo "    DocumentRoot /vagrant/biba/public" >> /etc/apache2/sites-available/testapp.conf
echo "    RailsEnv development" >> /etc/apache2/sites-available/testapp.conf
echo "    ErrorLog ${APACHE_LOG_DIR}/error.log" >> /etc/apache2/sites-available/testapp.conf
echo "    CustomLog ${APACHE_LOG_DIR}/access.log combined" >> /etc/apache2/sites-available/testapp.conf
echo "    <Directory "/vagrant/biba/public">" >> /etc/apache2/sites-available/testapp.conf
echo "        Options FollowSymLinks" >> /etc/apache2/sites-available/testapp.conf
echo "        Require all granted" >> /etc/apache2/sites-available/testapp.conf
echo "    </Directory>" >> /etc/apache2/sites-available/testapp.conf
echo "</VirtualHost>" >> /etc/apache2/sites-available/testapp.conf
a2dissite 000-default
a2ensite testapp
service apache2 restart
mysql -u root -pbiba -e "create database biba_development CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -u root -pbiba -e "create database biba_test CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -u root -pbiba -e "create database biba_production CHARACTER SET utf8 COLLATE utf8_general_ci;"
gem install rails --version 4.2.0 --no-ri --no-rdoc
cd /vagrant/biba
bundle install
rake db:setup
