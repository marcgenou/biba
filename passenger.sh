#! /usr/bin/env bash

# Variables
DBNAME=biba
DBPASSWD=biba

echo -e "\n--- Mkay, installing now... ---\n"

echo -e "\n--- Add some repos to update our distro ---\n"
apt-add-repository -y ppa:brightbox/ruby-ng > /dev/null 2>&1
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7 > /dev/null 2>&1
echo 'deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main' | sudo tee /etc/apt/sources.list.d/passenger.list > /dev/null 2>&1
chown root: /etc/apt/sources.list.d/passenger.list > /dev/null 2>&1
chmod 600 /etc/apt/sources.list.d/passenger.list > /dev/null 2>&1

echo -e "\n--- Updating packages list ---\n"
apt-get -qq update

echo -e "\n--- Setting MySQL specific parameters ---\n"
echo "mysql-server mysql-server/root_password password $DBPASSWD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | debconf-set-selections

echo -e "\n--- Installing packages ---\n"
apt-get install -y build-essential libssl-dev libyaml-dev libreadline-dev openssl curl git-core zlib1g-dev bison libxml2-dev libxslt1-dev libcurl4-openssl-dev libsqlite3-dev ruby2.2 ruby2.2-dev curl git libmysqlclient-dev mysql-server nodejs apache2 libapache2-mod-passenger phpmyadmin > /dev/null 2>&1

echo -e "\n--- Setting up our MySQL user and db ---\n"
mysql -uroot -p$DBPASSWD -e "CREATE DATABASE \$DBNAME_development CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -uroot -p$DBPASSWD -e "CREATE DATABASE \$DBNAME_test CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -uroot -p$DBPASSWD -e "CREATE DATABASE \$DBNAME_production CHARACTER SET utf8 COLLATE utf8_general_ci;"

echo -e "\n--- Configure Apache to use phpmyadmin ---\n"
cat > /etc/apache2/conf-available/phpmyadmin.conf << "EOF"
# phpMyAdmin default Apache configuration

Alias /phpmyadmin /usr/share/phpmyadmin

<Directory /usr/share/phpmyadmin>
	Options FollowSymLinks
	DirectoryIndex index.php

	<IfModule mod_php5.c>
		AddType application/x-httpd-php .php

		php_flag magic_quotes_gpc Off
		php_flag track_vars On
		php_flag register_globals Off
		php_admin_flag allow_url_fopen Off
		php_value include_path .
		php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp
		php_admin_value open_basedir /usr/share/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/php-gettext/:/usr/share/javascript/
	</IfModule>

</Directory>

# Authorize for setup
<Directory /usr/share/phpmyadmin/setup>
    <IfModule mod_authn_file.c>
    AuthType Basic
    AuthName "phpMyAdmin Setup"
    AuthUserFile /etc/phpmyadmin/htpasswd.setup
    </IfModule>
    Require valid-user
</Directory>

# Disallow web access to directories that don't need it
<Directory /usr/share/phpmyadmin/libraries>
    Order Deny,Allow
    Deny from All
</Directory>
<Directory /usr/share/phpmyadmin/setup/lib>
    Order Deny,Allow
    Deny from All
</Directory>
EOF

echo -e "\n--- Add environment variables to Apache ---\n"
cat > /etc/apache2/sites-available/testapp.conf <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /vagrant/biba/public
    <Directory /usr/share/phpmyadmin>
        PassengerEnabled off
        AllowOverride all
    </Directory>
    RailsEnv development
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    <Directory /vagrant/biba/public>
        Allow from all
        Options -MultiViews
        Require all granted
    </Directory>
</VirtualHost>
EOF

a2dissite 000-default > /dev/null 2>&1
a2ensite testapp > /dev/null 2>&1
php5enmod mcrypt > /dev/null 2>&1

echo -e "\n--- Restarting Apache ---\n"
service apache2 restart > /dev/null 2>&1

echo -e "\n--- Installing Rails 4.2.0 ---\n"
gem install rails --version 4.2.0 --no-ri --no-rdoc > /dev/null 2>&1

echo -e "\n--- Running bundle install ---\n"
cd /vagrant/biba
bundle install > /dev/null 2>&1

echo -e "\n--- Running db:setup ---\n"
rake db:setup > /dev/null 2>&1

