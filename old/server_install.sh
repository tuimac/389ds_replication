#!/bin/bash

PASSWORD='P@ssw0rd'
DSID='ldap'
DOMAIN='tuimac.com'
BASE='dc=tuimac,dc=com'
GROUP='test'

# Confirm exec user is root or not
[[ $USER != 'root' ]] && { echo -n 'Must be root!'; exit 1; }

# Basic OS setting
timedatectl set-timezone Asia/Tokyo

# Install 389 Directory Service
dnf module enable 389-ds -y
dnf install 389-ds-base 389-ds-base-legacy-tools -y

# Set up 389 Directory Service
setup-ds.pl

# Add Base OU
cat <<EOF > base.ldif
dn: ou=group,$BASE
objectClass: organizationalUnit
ou: group

-

dn: ou=user,$BASE
objectClass: organizationalUnit
ou: user

-

dn: cn=$GROUP,ou=group,$BASE
cn: $GROUP
gidNumber: 2000
objectClass: posixGroup
objectClass: top
EOF

ldapadd -x -D "cn=Directory Manager" -w ${PASSWORD} -f base.ldif

# Set up SSL/TLS communication
systemctl stop dirsrv@${DSID}
echo $PASSWORD > /etc/dirsrv/slapd-${DSID}/password.txt
chown dirsrv.dirsrv /etc/dirsrv/slapd-${DSID}/password.txt
chmod 400 /etc/dirsrv/slapd-${DSID}/password.txt
echo -n 'Internal (Software) Token:'${PASSWORD} > /etc/dirsrv/slapd-${DSID}/pin.txt
chown dirsrv.dirsrv /etc/dirsrv/slapd-${DSID}/pin.txt
chmod 400 /etc/dirsrv/slapd-${DSID}/pin.txt
certutil -W -d /etc/dirsrv/slapd-${DSID}/ -f /etc/dirsrv/slapd-${DSID}/password.txt
cd /etc/dirsrv/slapd-${DSID}/
openssl rand -out noise.bin 2048
certutil -S -x -d . -f password.txt -z noise.bin -n "Server-Cert" -s "CN=${DSID}.${DOMAIN}" -t "CT,C,C" -m $RANDOM -k rsa -g 2048 -Z SHA256 --keyUsage certSigning,keyEncipherment
certutil -L -d /etc/dirsrv/slapd-${DSID}
certutil -L -d /etc/dirsrv/slapd-${DSID} -n "Server-Cert" -a > ds.crt
certutil -L -d /etc/dirsrv/slapd-${DSID} -n "Server-Cert"
sed -i 46i'\nsslapd-security: on' /etc/dirsrv/slapd-${DSID}/dse.ldif
sed -i 47i'\nsslapd-secureport: 636' /etc/dirsrv/slapd-${DSID}/dse.ldif
systemctl start dirsrv@${DSID}
systemctl enable dirsrv@${DSID}
cp ds.crt /etc/openldap/
cat <<EOF >> /etc/openldap/ldap.conf
TLS_CACERT /etc/openldap/ds.crt
TLS_REQCERT never
EOF

ldapsearch -x -H ldaps://${DSID}.${DOMAIN} -D "cn=Directory Manager" -w ${PASSWORD} -b ${BASE}

# Set SUDO
echo '%'${GROUP}' ALL=(ALL)       ALL' >> /etc/sudoers
cat <<EOF > sudoersOU.ldif
dn: ou=SUDOers,dc=tuimac,dc=me
description: SUDOers
objectClass: organizationalUnit
objectClass: top
ou: SUDOers
EOF

ldapadd -x -D "cn=Directory Manager" -w ${PASSWORD} -f sudoersOU.ldif

export SUDOERS_BASE='ou=SUDOers,'${BASE}
cat /etc/sudoers | cvtsudoers > sudoers.ldif

ldapadd -x -D "cn=Directory Manager" -w ${PASSWORD} -f sudoers.ldif

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

cat <<EOF > password.ldif
dn: cn=config
changetype: modify
add: passwordChange
passwordChange: on

-

dn: cn=config
changetype: modify
add: passwordExp
passwordExp: on

-

dn: cn=config
changetype: modify
add: passwordMaxAge
passwordMaxAge: 6480000

-

dn: cn=config
changetype: modify
add: passwordCheckSyntax
passwordCheckSyntax: on

-

dn: cn=config
changetype: modify
add: passwordMaxFailure
passwordMaxFailure: 3

-

dn: cn=config
changetype: modify
add: passwordMustChange
passwordMustChange: on

-

dn: cn=config
changetype: modify
add: passwordLockout
passwordLockout: on

-

dn: cn=config
changetype: modify
add: passwordMinLength
passwordMinLength: 8

-

dn: cn=config
changetype: modify
add: passwordMinDigits
passwordMinDigits: 1

-

dn: cn=config
changetype: modify
add: passwordMinLowers
passwordMinLowers: 1

-

dn: cn=config
changetype: modify
add: passwordMinUppers
passwordMinUppers: 1

-

dn: cn=config
changetype: modify
add: passwordMinSpecials
passwordMinSpecials: 1
EOF

ldapmodify -x -D "cn=Directory Manager" -w ${PASSWORD} -f password.ldif
