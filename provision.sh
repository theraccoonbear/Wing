# Used to provision!

set -euo pipefail


#### Install some packages needed by later steps

apt-get update -y

# Variables
APPENV=local
DBHOST=localhost
DBNAME=wing
DBUSER=winguser
DBPASSWD=p4s5w0rD
GROUP=nobody
USERNAME=nobody

echo -e "\n--- Updating packages list ---\n"
apt-get -qq update

echo -e "\n--- Install MySQL specific packages and settings ---\n"
echo "mysql-server mysql-server/root_password password $DBPASSWD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | debconf-set-selections
apt-get -y install mysql-server-5.5 > /dev/null 2>&1

if ! mysql --user=$DBUSER --password=$DBPASSWD -e "use $DBNAME"; then
	echo -e "\n--- Setting up our MySQL user and db ---\n"
	mysql -uroot -p$DBPASSWD -e "CREATE DATABASE $DBNAME"
	mysql -uroot -p$DBPASSWD -e "grant all privileges on $DBNAME.* to '$DBUSER'@'localhost' identified by '$DBPASSWD'"
else
	echo -e "\n--- Database setup ---\n"
fi


apt-get install -y libgnome2-perl build-essential git curl ncurses-dev glib2.0 libexpat1-dev libxml2 libxml2-dev libssl-dev libpng12-dev libjpeg-dev libmysqlclient-dev

if grep -q $GROUP /etc/group
then
	echo -e "\n--- Group $GROUP already exits ---\n"
else
	echo -e "\n--- Adding group $GROUP ---\n"
	addgroup $GROUP
fi


ret=false
getent passwd $USERNAME >/dev/null 2>&1 && ret=true

if $ret; then
  echo -e "\n--- User $USERNAME already exits ---\n"
else
  echo -e "\n--- Adding user $USERNAME---\n"
	adduser $USERNAME $GROUP
fi

#/usr/bin/mysql_secure_installation

/data/Wing/bin/setup/setup.sh

source /data/Wing/bin/dataapps.sh

cd /data/Wing/bin
export WING_HOME=/data/Wing
perl wing_init_app.pl --app=MyApp