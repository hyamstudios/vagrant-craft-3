#!/usr/bin/env bash

DATABASE='craft'
DATABASE_PASSWORD='password'

# Create temporary memory swap file
if ! [ "$IS_LOCAL" = true ] ; then
	/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024
	/sbin/mkswap /var/swap.1
	/sbin/swapon /var/swap.1
fi

# Make sure linux stuff is up-to-date
sudo apt-get update

# Install Apache and PHP
sudo apt-get install -y apache2 libapache2-mod-php
sudo apt-get install -y php imagemagick php-imagick php-curl php-zip php-intl

# Install MySQL
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $DATABASE_PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DATABASE_PASSWORD"
sudo apt-get -y install mysql-server php-mysql
sudo apt-get -y install php-xdebug

# Install PHPMyAdmin
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $DATABASE_PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $DATABASE_PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $DATABASE_PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
sudo apt-get -y install phpmyadmin

# Create database and changed settings for craft
sudo mysql -u root -p$DATABASE_PASSWORD -e "CREATE DATABASE $DATABASE;"
sudo mysql -u root -p$DATABASE_PASSWORD -e "ALTER DATABASE $DATABASE CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
sudo mysql -u root -p$DATABASE_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION; FLUSH PRIVILEGES;"

# Turn on PHP errors and increase upload file size limit
sudo cp /etc/php/7.2/apache2/php.ini /etc/php/7.2/apache2/php.ini.bak
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.2/apache2/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.2/apache2/php.ini
sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 16M/" /etc/php/7.2/apache2/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 256M/" /etc/php/7.2/apache2/php.ini
sudo sed -i "s/max_execution_time = .*/max_execution_time = 120/" /etc/php/7.2/apache2/php.ini

# Do not enable it on production server
# # Enable PHP Xdebug, log file is initially commented out
# sudo sed -i "$ a\ \n[Xdebug]\nxdebug.remote_enable = 1\nxdebug.remote_autostart = 1\nxdebug.remote_connect_back = 1\n; xdebug.remote_log = /vagrant/xdebug.log" /etc/php/7.0/apache2/php.ini
# echo "Edited php.ini"

# AllowOverride in apache
sudo cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.bak
sudo sed -i "s/\tAllowOverride None/\tAllowOverride All/g" /etc/apache2/apache2.conf
echo "Edited apache2.conf"

# Enable mod_rewrite/mcrypt and restart Apache
sudo a2enmod rewrite
# sudo phpenmod mcrypt CraftCMS 3 does not need mcrypt anymore
sudo service apache2 restart

# Install composer and install global (v1.6.2)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/bin/composer

# Install Craft CMS (if not already installed)
if ! [ -f /vagrant/craft/web/index.php ]; then
  composer create-project -s RC craftcms/craft /vagrant/craft

  # Set up database
	sudo sed -i "s/DB_PASSWORD=\"\"/DB_PASSWORD=\"$DATABASE_PASSWORD\"/" /vagrant/craft/.env
	sudo sed -i "s/DB_DATABASE=\"\"/DB_DATABASE=\"$DATABASE\"/" /vagrant/craft/.env

	# Install CraftCMS Plugins
	cd /vagrant/craft
	composer require craftcms/webhooks
	composer require craftcms/redactor
	composer require markhuot/craftql
	composer require verbb/cp-nav
	composer require verbb/field-manager
	cd /
	sudo php /vagrant/craft/craft install/plugin webhooks
	sudo php /vagrant/craft/craft install/plugin redactor
	sudo php /vagrant/craft/craft install/plugin craftql
	sudo php /vagrant/craft/craft install/plugin cp-nav
	sudo php /vagrant/craft/craft install/plugin field-manager

	# Set up base url
	sudo echo "DEFAULT_SITE_URL=$SITE_DOMAIN" >> /vagrant/craft/.env

	# Craft adjustments, these are all optional
	# First back up general config
	sudo cp /vagrant/craft/config/general.php /vagrant/craft/config/general.php.bak
	# Use email as username
	sudo sed -i "s/'securityKey' => getenv('SECURITY_KEY'),/'securityKey' => getenv('SECURITY_KEY'),\n        'useEmailAsUsername' => true,/" /vagrant/craft/config/general.php

	echo "Customized Craft CMS"
fi

# Set apache to use craft "web" folder
if ! [ -L /var/www/html ]; then
	sudo rm -rf /var/www/html
	sudo ln -fs /vagrant/craft/web /var/www/html
	echo "Symlinked craft/web folder"
fi

# Setup File Permission
sudo chown -R root:www-data /vagrant/craft
sudo chmod -R 774 /vagrant/craft
sudo chown -R root:www-data /var/www/html/cpresources
sudo chmod -R 774 /var/www/html/cpresources

# LetsEncrypt
if ! [ "$IS_LOCAL" = true ] ; then
	sudo apt-get install -y python-certbot-apache
	sudo certbot --apache -n -d $SITE_DOMAIN -m development@hyam.de
fi
