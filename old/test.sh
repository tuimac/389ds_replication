#!/bin/bash

DOMAIN='ldap.tuimac.com'
PASSWORD='P@ssw0rd'

[[ $USER != 'root' ]] && { echo -n 'Must be root!'; exit 1; }

dnf module enable 389-ds -y
dnf install 389-ds-base 389-ds-base-legacy-tools expect -y

expect -c '
set timeout 5
spawn setup-ds.pl
expect \"Would you like to continue with set up? \[yes\]:\"
send \"yes\n\"
expect \"Choose a setup type \[2\]:\"
send \"3\n\"
expect \"Computer name \[*\"
send \"${DOMAIN}\n\"
expect \"System User \[dirsrv\]:\"
send \"\r\n\"
expect \"System Group \[dirsrv\]:\"
send \"\r\n\"
expect \"Directory server network port \[*\]:\"
send \"\r\n\"
expect \"Directory server identifier \[*\"
send \"\r\n\"
expect \"Suffix \[dc=*\"
send \"\r\n\"
expect \"Directory Manager DN \[cn=Directory Manager\]:\"
send \"\r\n\"
expect \"Password:\"
send \"${PASSWORD}\n\"
expect \"Password (confirm):\"
send \"${PASSWORD}\n\"
expect \"Do you want to install the sample entries? \[no\]:\"
send \"\r\n\"
expect \"Type the full path and filename, the word suggest, or the word none \[suggest\]:\"
send \"\r\n\"
expect \"Log file is*\"
exit 0
'

systemctl status dirsrv@ldap
