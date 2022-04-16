#!/bin/bash

DOMAIN='ldap.tuimac.com'
SUFFIX='dc=tuimac,dc=com'
SUFFIX_DOMAIN='tuimac.com'
INSTANCE='ldap'
ROOT_PASSWORD='P@ssw0rd'

function server-install(){
    [[ $USER != 'root' ]] && { echo 'Must be root!'; exit 1; }

    dnf module enable 389-ds* -y
    dnf install 389-ds* -y

    cat <<EOF > instance.inf
[general]
config_version = 2
defaults = 999999999
full_machine_name = $DOMAIN
selinux = False
start = True
strict_host_checking = True
backup_dir = /var/lib/dirsrv/slapd-{instance_name}/backup
bin_dir = /usr/bin
cert_dir = /etc/dirsrv/slapd-{instance_name}
config_dir = /etc/dirsrv/slapd-{instance_name}
db_dir = /var/lib/dirsrv/slapd-{instance_name}/database
log_dir = /var/log/dirsrv/slapd-{instance_name}

[slapd]
instance_name = $INSTANCE
port = 389
root_dn = cn=Directory Manager
root_password = $ROOT_PASSWORD
secure_port = 636
self_sign_cert = True
self_sign_cert_valid_months = 1200

[backend-userroot]
create_suffix_entry = True
require_index = False
suffix = $SUFFIX
EOF
    dscreate from-file instance.inf
    dsctl ldap status
    rm instance.inf
    echo 'TLS_REQCERT never' >> /etc/openldap/ldap.conf
    list
    systemctl status dirsrv@${INSTANCE}
}

function client-install(){
    [[ $USER != 'root' ]] && { echo 'Must be root!'; exit 1; }
    dnf install oddjob-mkhomedir sssd -y
    cat <<EOF > /etc/sssd/sssd.conf
[sssd]
debug_level = 6
config_file_version = 2
services = nss, sudo, pam, ssh
domains = default

[domain/default]
id_provider = ldap
auth_provider = ldap
chpass_provider = ldap
sudo_provider = ldap
ldap_sudo_search_base = ou=SUDOers,$SUFFIX
ldap_uri = ldaps://$DOMAIN
ldap_search_base = $SUFFIX
ldap_id_use_start_tls = True
cache_credentials = True
ldap_tls_reqcert = never

[nss]
homedir_substring = /home
entry_negative_timeout = 20
entry_cache_nowait_percentage = 50

[pam]

[sudo]

[autofs]

[ssh]

[pac]
EOF
    chmod 600 /etc/sssd/sssd.conf
    systemctl restart sssd
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
    systemctl status sssd
}

function list(){
    ldapsearch -x -H ldaps://${INSTANCE}.${SUFFIX_DOMAIN} -D "cn=Directory Manager" -w ${ROOT_PASSWORD} -b ${SUFFIX}
}

function apply(){
    [[ -z $1 ]] && { echo 'Need argument!'; exit 1; }
    ldapadd -x -D "cn=Directory Manager" -w ${ROOT_PASSWORD} -f $1
}


function create-base(){
   cat <<EOF > base.ldif
dn: ou=group,$SUFFIX
objectClass: organizationalUnit
ou: group

-

dn: ou=user,$SUFFIX
objectClass: organizationalUnit
ou: user

-

dn: cn=admin,ou=group,$SUFFIX
objectClass: posixGroup
objectClass: top
cn: admin
gidNumber: 2000

-

dn: uid=admin,ou=user,$SUFFIX
uid: admin
cn: admin
objectClass: account
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
userPassword: P@ssw0rd
loginShell: /bin/bash
uidNumber: 2000
gidNumber: 2000
homeDirectory: /home/admin

-

dn: ou=SUDOers,$SUFFIX
objectClass: top
objectClass: organizationalUnit
ou: SUDOers

-

dn: cn=admin,ou=SUDOers,$SUFFIX
objectClass: sudoRole
objectClass: top
cn: admin
sudoUser: admin
sudoHost: ALL
sudoCommand: ALL
EOF
    cat base.ldif
    apply base.ldif
    rm base.ldif
}

function userguide(){
    echo -e "usage: ./run.sh [help]"
    echo -e "
optional arguments:
create-base              Create Base User and Group.
    "
}

function main(){
    [[ -z $1 ]] && { userguide; exit 1; }
    if [ $1 == "server-install" ]; then
        server-install
    elif [ $1 == "client-install" ]; then
        client-install
    elif [ $1 == "list" ]; then
        list
    elif [ $1 == "create-base" ]; then
        create-base
    elif [ $1 == "apply" ]; then
        apply $2
    elif [ $1 == "help" ]; then
        userguide
    else
        { userguide; exit 1; }
    fi
}

main $1
