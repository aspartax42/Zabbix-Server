#!/bin/bash -e

if [ "$UID" -ne 0 ]; then
  echo "Merci d'exécuter en root"
  exit 1
fi

# Principaux paramètres
tput setaf 7; read -p "Entrer le mot de passe root de la base de données: " ROOT_DB_PASS
tput setaf 7; read -p "Entrer le mot de passe zabbix de la base de données: " ZABBIX_DB_PASS

tput setaf 2; echo ""

# Installation apache2 et php
apt install apache2 php php-mysql php-mysqlnd php-ldap php-bcmath php-mbstring php-gd php-pdo php-xml libapache2-mod-php
systemctl restart apache2

# Installation MariaDB
apt install mariadb-server mariadb-client

# Ajout de la variable PATH qui peux poser problème
export PATH=$PATH:/usr/local/sbin
export PATH=$PATH:/usr/sbin
export PATH=$PATH:/sbin

# Changement du mdp de la base de données MySQL
mysql_secure_installation <<EOF
y
ROOT_DB_PASS
ROOT_DB_PASS
y
y
y
y
EOF


# Configuration de la base de données
mysql -uroot -p'$ROOT_DB_PASS' -e "drop database if exists zabbix;"
mysql -uroot -p'$ROOT_DB_PASS' -e "drop user if exists zabbix@localhost;"
mysql -uroot -p'$ROOT_DB_PASS' -e "create database zabbix character set utf8 collate utf8_bin;"
mysql -uroot -p'$ROOT_DB_PASS' -e "grant all on zabbix.* to 'zabbix'@'%' identified by '"$ZABBIX_DB_PASS"' with grant option;"


# Récupération de la dernière version de Zabbix

cd /tmp
wget https://repo.zabbix.com/zabbix/5.0/debian/pool/main/z/zabbix-release/zabbix-release_5.0-1%2Bbuster_all.deb
dpkg -i zabbix-release_5.0-1+buster_all.deb


# Installation du serveur Zabbix, agent, interface web

apt -y install zabbix-server-mysql zabbix-frontend-php zabbix-agent


# Ajout de la table SQL dans notre DB zabbix_proxy

mysql -uroot -p'$ROOT_DB_PASS' -D zabbix -e "set global innodb_strict_mode='OFF';"
zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz |  mysql -u zabbix --password=$ZABBIX_DB_PASS zabbix
mysql -uroot -p'$ROOT_DB_PASS' -D zabbix -e "set global innodb_strict_mode='ON';"
