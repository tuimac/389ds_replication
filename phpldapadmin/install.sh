#!/bin/bash

[[ $USER == 'root' ]] && { echo 'Must be root!!'; exit 1; }

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum -y install phpldapadmin

sed -i 's/\$servers->setValue('login','attr','uid');/\/\/ \$servers->setValue('login','attr','uid');/' /etc/phpldapadmin/config.php
sed -i 's/\/\/\$servers->setValue('login','attr','dn');/\$servers->setValue('login','attr','dn');/' /etc/phpldapadmin/config.php

sed -i 's/Require local/Require all granted/' /etc/httpd/conf.d/phpldapadmin.conf

systemctl start httpd
systemctl enable httpd
