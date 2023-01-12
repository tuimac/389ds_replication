#!/bin/bash

BASE_DN='dc=tuimac,dc=com'
ROOT_PASSWORD='P@ssw0rd'
DOMAIN='primary.tuimac.com'

LDAP_USERS=$(ldapsearch -x -H ldaps://${DOMAIN} -D "cn=Directory Manager" -w $ROOT_PASSWORD -b $BASE_DN uid | grep uid: | awk '{print $2}')

echo -en 'Username\t\tUID\t\tGID\t\tLoginShell\n'
for LDAP_USER in ${LDAP_USERS[@]}; do
    username=$(ldapsearch -x -H ldaps://${DOMAIN} -D "cn=Directory Manager" -w $ROOT_PASSWORD -b $BASE_DN 'uid='${LDAP_USER} uid | grep uid: | awk '{print $2}')
    uid=$(ldapsearch -x -H ldaps://${DOMAIN} -D "cn=Directory Manager" -w $ROOT_PASSWORD -b $BASE_DN 'uid='${LDAP_USER} uidNumber | grep uidNumber: | awk '{print $2}')
    gid=$(ldapsearch -x -H ldaps://${DOMAIN} -D "cn=Directory Manager" -w $ROOT_PASSWORD -b $BASE_DN 'uid='${LDAP_USER} gidNumber | grep gidNumber: | awk '{print $2}')
    login_shell=$(ldapsearch -x -H ldaps://${DOMAIN} -D "cn=Directory Manager" -w $ROOT_PASSWORD -b $BASE_DN 'uid='${LDAP_USER} loginShell | grep loginShell: | awk '{print $2}')
    echo -en $username'\t\t'$uid'\t\t'$gid'\t\t'$login_shell'\n'
    echo $result
done
