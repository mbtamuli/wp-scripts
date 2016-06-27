#!/bin/bash
#************************************************#
#                   setup.sh                     #
#           written by Mriyam Tamuli             #
#                June 26, 2016                   #
#                                                #
#         Web Server Setup for WordPress.        #
#************************************************#

ROOT_UID=0
MYSQL_USER=root
MYSQL_PASSWORD=toor
LOGFILE=script.log
ERRORFILE=script.err

if [[ "$EUID" -ne "$ROOT_UID" ]]; then
   echo "This script must be run as root" 
   exit 1
fi

RCol='\e[0m'    # Text Reset

# Regular           Bold                Underline           High Intensity  
Bla='\e[0;30m';     BBla='\e[1;30m';    UBla='\e[4;30m';    IBla='\e[0;90m';
Red='\e[0;31m';     BRed='\e[1;31m';    URed='\e[4;31m';    IRed='\e[0;91m';
Gre='\e[0;32m';     BGre='\e[1;32m';    UGre='\e[4;32m';    IGre='\e[0;92m';
Yel='\e[0;33m';     BYel='\e[1;33m';    UYel='\e[4;33m';    IYel='\e[0;93m';
Blu='\e[0;34m';     BBlu='\e[1;34m';    UBlu='\e[4;34m';    IBlu='\e[0;94m';
Pur='\e[0;35m';     BPur='\e[1;35m';    UPur='\e[4;35m';    IPur='\e[0;95m';
Cya='\e[0;36m';     BCya='\e[1;36m';    UCya='\e[4;36m';    ICya='\e[0;96m';
Whi='\e[0;37m';     BWhi='\e[1;37m';    UWhi='\e[4;37m';    IWhi='\e[0;97m';

#BoldHigh Intens     Background          High Intensity Backgrounds
BIBla='\e[1;90m';   On_Bla='\e[40m';    On_IBla='\e[0;100m';
BIRed='\e[1;91m';   On_Red='\e[41m';    On_IRed='\e[0;101m';
BIGre='\e[1;92m';   On_Gre='\e[42m';    On_IGre='\e[0;102m';
BIYel='\e[1;93m';   On_Yel='\e[43m';    On_IYel='\e[0;103m';
BIBlu='\e[1;94m';   On_Blu='\e[44m';    On_IBlu='\e[0;104m';
BIPur='\e[1;95m';   On_Pur='\e[45m';    On_IPur='\e[0;105m';
BICya='\e[1;96m';   On_Cya='\e[46m';    On_ICya='\e[0;106m';
BIWhi='\e[1;97m';   On_Whi='\e[47m';    On_IWhi='\e[0;107m';



# #################################################################################
# add_ppa() {                                                                     #
#   grep -h "^deb.*$1" /etc/apt/sources.list.d/*                                  #
#   if [ $? -ne 0 ]                                                               #   Remove
#   then                                                                          #
#     echo "Adding ppa:$1"                                                        #
#     add-apt-repository -y ppa:$1 > /dev/null 2>&1                               #   this
#     return 0                                                                    #
#   fi                                                                            #
#                                                                                 #   section
#   echo "ppa:$1 already exists"                                                  #
#   return 1                                                                      #
# }                                                                               #   later
# add_ppa saiarcot895/myppa                                                       #
# apt-get update                                                                  #
# echo "apt-fast apt-fast/maxdownloads string 10" | debconf-set-selections        #
# echo "apt-fast apt-fast/aptmanager select apt-get" | debconf-set-selections     #
# echo "apt-fast apt-fast/dlflag boolean true" | debconf-set-selections           #
# apt-get install apt-fast -y                                                     #
# #################################################################################

export DEBIAN_FRONTEND=noninteractive

check_install() {
    echo
    echo -e "[${Blu}ACTION${RCol}]  Checking if ${BBla}${On_Whi}$1${RCol} already installed"
    INSTALLED=$(dpkg -l | grep $1)
    if [ "$INSTALLED" != "" ]; then
        # installed
        return 0
    else
        # not installed
        return 1
    fi
}

install_package() {
    echo -e "[${Blu}ACTION${RCol}]  Installing ${BBla}${On_Whi}$1${RCol}..."
    apt-get install $1 -y  >>$LOGFILE 2>>$ERRORFILE
    echo -e "[${Gre}NOTICE${RCol}]  $1 installed"
}

mysql_secure_installation() {
    echo -e "[${Blu}ACTION${RCol}]  Removing insecure details from MySQL"
    mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e "DELETE FROM mysql.user WHERE User='';"
    mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e "DROP DATABASE test;"
    mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
    mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e "FLUSH PRIVILEGES;"
} >>$LOGFILE 2>>$ERRORFILE

install_mysql() {
    echo
    echo -e "[${Blu}ACTION${RCol}]  Installing ${BBla}${On_Whi}MySQL server${RCol}"

    echo "mysql-community-server mysql-community-server/root-pass password $MYSQL_PASSWORD" | debconf-set-selections
    echo "mysql-community-server mysql-community-server/re-root-pass password $MYSQL_PASSWORD" | debconf-set-selections

    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 5072E1F5 
    if [ -f /etc/apt/sources.list.d/mysql.list ]; then
        echo -e "[${Blu}ACTION${RCol}]  mysql repo already exists."
        echo -e "[${Blu}ACTION${RCol}]  Removing old repo and creating new one."
        rm -f /etc/apt/sources.list.d/mysql.list
        echo "deb http://repo.mysql.com/apt/ubuntu trusty mysql-5.7" | tee /etc/apt/sources.list.d/mysql.list
    else
        echo -e "[${Blu}ACTION${RCol}]  Creating mysql repo."
        echo "deb http://repo.mysql.com/apt/ubuntu trusty mysql-5.7" | tee /etc/apt/sources.list.d/mysql.list
    fi
    apt-get update >>$LOGFILE 2>>$ERRORFILE
    apt-get install mysql-server -y >>$LOGFILE 2>>$ERRORFILE
    echo -e "[${Gre}NOTICE${RCol}]  mysql-community-server installed"
    mysql_secure_installation
}

configure_php_nginx() {
    sed -i 's/^;cgi.fix_pathinfo=1$/cgi.fix_pathinfo=0/' /etc/php5/fpm/php.ini
    service php5-fpm restart

cat > /etc/nginx/sites-available/default <<EOL
server {
    listen 80 default_server;
    listen [::]:80 default_server ipv6only=on;

    root /usr/share/nginx/html;
    index index.php index.html index.htm;

    server_name localhost;

    location / {
        try_files \$uri \$uri/ =404;
    }

    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }

    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOL
service nginx restart
}

#################################################################################
#                                                                               #
#                           MAIN SCRIPT STARTS HERE                             #
#                                                                               #
#################################################################################

clear
echo -e "[${Blu}ACTION${RCol}]  Starting script"
echo -e "[${Gre}NOTICE${RCol}]  Hello, $SUDO_USER.  This script will set up a WordPress site for you."
echo -e -n "[${Gre}NOTICE${RCol}]  Enter the domain name and press [ENTER]: "
read domain
echo -e -n "[${URed}INPUT${RCol}]  ${Yel}Do you need to setup new MySQL database? (y/n)${RCol} "
read -e setupmysql
if [ "$setupmysql" == y ] ; then
    echo -e -n "[${URed}INPUT${RCol}]  MySQL Admin User: "
    read -e MYSQL_USER
    echo -e -n "[${URed}INPUT${RCol}]  MySQL Admin Password: "
    read -s MYSQL_PASSWORD
    echo
    echo -e -n "[${URed}INPUT${RCol}]  MySQL Host (Enter for default 'localhost'): "
    read -e mysqlhost
    mysqlhost=${mysqlhost:-localhost}
fi
dbname=${domain//.}_db;
dbuser="wp_user"
dbpass="wp_pass"
echo -e -n "[${URed}INPUT${RCol}]  WP Database Table Prefix [numbers, letters, and underscores only] (Enter for default 'wp_'): "
read -e dbtable
    dbtable=${dbtable:-wp_}


if check_install pv; then echo -e "[${Gre}NOTICE${RCol}]  pv already installed"; else install_package pv; fi
if check_install nginx; then echo -e "[${Gre}NOTICE${RCol}]  Nginx already installed"; else install_package nginx; fi
echo
if check_install mysql-community-server; then echo -e "[${Gre}NOTICE${RCol}]  MySQL Server already installed"; else install_mysql; fi

apt-get update >>$LOGFILE 2>>$ERRORFILE

for i in php5-fpm php5-mysql php5-gd libssh2-php; do
    if check_install $i; then 
        echo -e "[${Gre}NOTICE${RCol}]  $i already installed"
    else
        install_package $i
    fi
done
echo -e "[${Blu}ACTION${RCol}]  Setting configuration options for PHP and Nginx"
configure_php_nginx
if [ "$setupmysql" == y ] ; then
    echo -e "[${Blu}ACTION${RCol}]  Setting up the database."
    dbsetup="create database $dbname;GRANT ALL PRIVILEGES ON $dbname.* TO $dbuser@$mysqlhost IDENTIFIED BY '$dbpass';FLUSH PRIVILEGES;"
    mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -e "$dbsetup"
    if [ $? != "0" ]; then
        echo -e "[${Red}${On_Whi}ERROR${RCol}]  ${URed}Database creation failed. Aborting.${RCol}"
        exit 1
    fi
fi
sed -i "s/^\(127.0.0.1.*\)$/\1 $domain/" /etc/hosts
su - $SUDO_USER -c "wget http://wordpress.org/latest.tar.gz"
su - $SUDO_USER -c "tar xzf latest.tar.gz -C ~/"
echo -e "[${Blu}ACTION${RCol}]  Configuring wordpress..."
mkdir -p /var/www/html
rsync -avP ~/wordpress/ /var/www/html/
cd /var/www/html/
wget https://api.wordpress.org/secret-key/1.1/salt/ -O salt.txt
cp wp-config-sample.php wp-config.php
chown -R "$SUDO_USER":www-data /var/www/html/*
mkdir wp-content/uploads
chown -R :www-data /var/www/html/wp-content/uploads
chmod 775 wp-content/uploads
sed -i "s#database_name_here#$dbname#g" wp-config.php
sed -i "s#username_here#$dbuser#g" wp-config.php
sed -i "s#password_here#$dbpass#g" wp-config.php
sed -i "s#wp_#$dbtable#g" wp-config.php
sed -i '49,56d;57r salt.txt' wp-config.php

rm -f /etc/nginx/sites-available/wordpress
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/wordpress
sed -i "s#root /usr/share/nginx/html;#root /var/www/html;#g" /etc/nginx/sites-available/wordpress
sed -i "s#server_name localhost;#server_name $domain;#g" /etc/nginx/sites-available/wordpress
sed -i 's#^try_files \$uri \$uri/ =404;$#try_files \$uri \$uri/ /index.php?q=\$uri&\$args;#g' /etc/nginx/sites-available/wordpress
rm -f /etc/nginx/sites-enabled/wordpress
ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
service nginx restart
service php5-fpm restart

echo
echo
echo -e "[${Gre}NOTICE${RCol}]  WordPress installed and configured."
echo -e "[${Gre}NOTICE${RCol}]  Visit the site at $domain"
echo -e "[${Gre}NOTICE${RCol}]  WordPress Database name: ${BBla}${On_Whi}$dbname${RCol}"
echo -e "[${Gre}NOTICE${RCol}]  WordPress Database user: ${BBla}${On_Whi}$dbuser${RCol}"
echo -e "[${Gre}NOTICE${RCol}]  WordPress Database password: ${BBla}${On_Whi}$dbpass${RCol}"
echo
echo