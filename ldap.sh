#!/bin/bash

INSTANCE='primary'
SUFFIX_DOMAIN='tuimac.com'
DOMAIN=${INSTANCE}'.'${SUFFIX_DOMAIN}
SECONDARY_HOST='secondary.tuimac.com'
SUFFIX='dc=tuimac,dc=com'
ROOT_PASSWORD='P@ssw0rd'
REP_PASSWORD='P@ssw0rd'
REP_NAME='test'
PORT='389'
PASS_FILE='pwdfile.txt'

function server-install(){
    [[ $USER != 'root' ]] && { echo 'Must be root!'; exit 1; }

    dnf module enable 389-ds -y
    dnf install expect 389-ds-base 389-ds-base-legacy-tools -y

    expect -c "
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
    expect \"*Password:*\"
    send \"${ROOT_PASSWORD}\n\"
    expect \"*Password (confirm):*\"
    send \"${ROOT_PASSWORD}\n\"
    expect \"Do you want to install the sample entries? \[no\]:\"
    send \"\r\n\"
    expect \"Type the full path and filename, the word suggest, or the word none \[suggest\]:\"
    send \"\r\n\"
    expect \"Log file is*\"
    exit 0"

    cd /etc/dirsrv/slapd-${INSTANCE}/
    echo $ROOT_PASSWORD > ${PASS_FILE}
    chown dirsrv.dirsrv ${PASS_FILE}
    chmod 400 ${PASS_FILE}
    echo -n 'Internal (Software) Token:'${ROOT_PASSWORD} > pin.txt
    chown dirsrv.dirsrv pin.txt
    chmod 400 pin.txt
    certutil -W -d /etc/dirsrv/slapd-${INSTANCE}/ -f ${PASS_FILE}
    openssl rand -out noise.bin 4096
    certutil -S -x -d . -f ${PASS_FILE} -z noise.bin -n "Server-Cert" -s "CN=${DOMAIN}" -t "CT,C,C" -m $RANDOM -k rsa -g 4096 -Z SHA256 --keyUsage digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment
    certutil -L -d /etc/dirsrv/slapd-${INSTANCE}
    certutil -L -d /etc/dirsrv/slapd-${INSTANCE} -n "Server-Cert" -a > ds.crt
    certutil -L -d /etc/dirsrv/slapd-${INSTANCE} -n "Server-Cert"
    dsconf -D "cn=Directory Manager" -w ${ROOT_PASSWORD} ldap://${DOMAIN} config replace nsslapd-securePort=636 nsslapd-security=on
    systemctl enable dirsrv@${INSTANCE}
    mkdir /etc/openldap/${INSTANCE}
    cp ds.crt /etc/openldap/${INSTANCE}
    cat <<EOF >> /etc/openldap/ldap.conf
TLS_CACERT /etc/openldap/$INSTANCE/ds.crt
TLS_REQCERT never
EOF
    systemctl stop dirsrv@${INSTANCE}
    mkdir /usr/sbin/dirsrv
    mv /usr/sbin/ns-slapd /usr/sbin/dirsrv/ns-slapd
    cat /etc/systemd/system/dirsrv.target.wants/dirsrv@${INSTANCE}.service
    sed -i 's/ExecStart=\/usr\/sbin\/ns-slapd/ExecStart=\/usr\/sbin\/dirsrv\/ns-slapd/' /etc/systemd/system/multi-user.target.wants/dirsrv@${INSTANCE}.service
    sed -i 's/ExecStart=\/usr\/sbin\/ns-slapd/ExecStart=\/usr\/sbin\/dirsrv\/ns-slapd/' /etc/systemd/system/dirsrv.target.wants/dirsrv@${INSTANCE}.service
    sed -i 's/ExecStart=\/usr\/sbin\/ns-slapd/ExecStart=\/usr\/sbin\/dirsrv\/ns-slapd/' /usr/lib/systemd/system/dirsrv@.service
    systemctl daemon-reload
    systemctl start dirsrv@${INSTANCE}
    ldapsearch -x -H ldaps://${DOMAIN} -D "cn=Directory Manager" -w ${ROOT_PASSWORD} -b ${SUFFIX}
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
cache_credentials = False
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
    authconfig --enablemkhomedir --update
    authconfig --enableldap --update
    authconfig --enableldapauth --update
    authconfig --enableshadow --update
    authconfig --enablelocauthorize --update
    systemctl restart sshd
    systemctl status sssd
}

function list(){
    ldapsearch -x -H ldaps://${DOMAIN} -D "cn=Directory Manager" -w ${ROOT_PASSWORD} -b ${SUFFIX}
}

function logs(){
    [[ $USER != 'root' ]] && { echo 'Must be root!'; exit 1; }
    echo -en '\n################# Access Log #################\n\n'
    tail -n 50 /var/log/dirsrv/slapd-primary/access
    echo -en '\n################# Error Log #################\n\n'
    tail -n 50 /var/log/dirsrv/slapd-primary/errors
}

function apply(){
    [[ -z $1 ]] && { echo 'Need argument!'; exit 1; }
    ldapadd -x -D "cn=Directory Manager" -w ${ROOT_PASSWORD} -f $1
}


function create-base(){
   cat <<EOF > base.ldif
dn: cn=test,ou=Groups,$SUFFIX
objectClass: posixGroup
objectClass: top
cn: admin
gidNumber: 2000

-

dn: uid=test,ou=People,$SUFFIX
uid: test
cn: test
objectClass: account
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
userPassword: P@ssw0rd
loginShell: /bin/bash
uidNumber: 2000
gidNumber: 2000
homeDirectory: /home/test

-

dn: ou=SUDOers,$SUFFIX
objectClass: top
objectClass: organizationalUnit
ou: SUDOers

-

dn: cn=defaults,ou=SUDOers,$SUFFIX
objectClass: top
objectClass: sudoRole
cn: defaults
description: Default sudoOption's go here
sudoOption: env_keep+=SSH_AUTH_SOCK

-

dn: cn=%wheel,ou=SUDOers,$SUFFIX
objectClass: top
objectClass: sudoRole
cn: %wheel
sudoUser: %wheel
sudoHost: ALL
sudoCommand: ALL

-

dn: uid=admin,ou=People,$SUFFIX
uid: admin
cn: admin
objectClass: account
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
userPassword: P@ssw0rd
loginShell: /bin/bash
uidNumber: 3000
gidNumber: 10
homeDirectory: /home/admin
EOF
    cat base.ldif
    apply base.ldif
    rm base.ldif
}

function primary(){
    [[ $USER != 'root' ]] && { echo 'Must be root!'; exit 1; }
    dsconf -D 'cn=Directory Manager' ldaps://${DOMAIN} replication create-manager
    dsconf -D 'cn=Directory Manager' ldaps://${DOMAIN} replication enable \
        --suffix ${SUFFIX} \
        --role supplier \
        --replica-id 2 \
        --bind-dn="cn=replication manager,cn=config" \
        --bind-passwd ${REP_PASSWORD}
    dsconf -D 'cn=Directory Manager' ldaps://${DOMAIN} repl-agmt create \
        --suffix ${SUFFIX} \
        --host ${SECONDARY_HOST} \
        --port 389 \
        --conn-protocol LDAP \
        --bind-dn="cn=replication manager,cn=config" \
        --bind-passwd ${REP_PASSWORD} \
        --bind-method=SIMPLE \
        --init ${REP_NAME}
}

function secondary(){
    [[ $USER != 'root' ]] && { echo 'Must be root!'; exit 1; }
    dsconf -D 'cn=Directory Manager' ldaps://${DOMAIN} replication create-manager
    dsconf -D 'cn=Directory Manager' ldaps://${DOMAIN} replication enable \
        --suffix ${SUFFIX} \
        --role consumer \
        --replica-id 1 \
        --bind-dn="cn=replication manager,cn=config" \
        --bind-passwd ${REP_PASSWORD}
}

function rep-delete(){
    dsconf -D 'cn=Directory Manager' ldaps://${DOMAIN} repl-agmt delete \
        --suffix ${SUFFIX} \
        ${REP_NAME}
    dsconf -D 'cn=Directory Manager' ldaps://${DOMAIN} replication disable \
        --suffix ${SUFFIX}
}

function rep-monitor(){
    dsconf -j -D 'cn=Directory Manager' -w ${ROOT_PASSWORD} ldaps://${DOMAIN} replication status \
        --suffix ${SUFFIX} \
        --bind-dn="cn=replication manager,cn=config" \
        --bind-passwd ${REP_PASSWORD}
}

function userguide(){
    echo -e "usage: ./run.sh [server-install | client-intsall | ...]"
    echo -e "
optional arguments:

server-install          Install 389 Directory Service into your server.
client-install          Install SSSD into your server.
list                    List all objects whthin base suffix.
logs                    Tail each log file with last 50 records .
create-base             Create Default User and Group.
apply                   Add objects followed by LDIF file. Need the argument for LDIF file path.
primary                 Configure the replication for Primary server.
secondary               Configure the replication for Secondary server.
rep-monitor             Return the result of monitoring with the replication.
rep-delete              Delete the replication configuration on Primary server.
help                    Show the easy guide of the utility tool.
    "
}

function main(){
    [[ -z $1 ]] && { userguide; exit 1; }
    case $1 in
        'server-install')
            server-install;;
        'client-install')
            client-install;;
        'list')
            list;;
        'logs')
            logs;;
        'create-base')
            create-base;;
        'apply')
            apply $2;;
        'primary')
            primary;;
        'secondary')
            secondary;;
        'rep-monitor')
            rep-monitor;;
        'rep-delete')
            rep-delete;;
        'help')
            userguide;;
        *)
            userguide
            exit 1;;
    esac
}

main $1
