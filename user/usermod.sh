#!/bin/bash

SUFFIX='dc=tuimac,dc=com'
MGR_PW='P@ssw0rd'
TMP_LDIF='tmp-'${RANDOM}'.ldif'
USER_OU='People'
GID='2000'

function userUnlock(){
    local username=$1
    cat << EOF > $TMP_LDIF
dn: cn=$username,ou=$USER_OU,$SUFFIX
changetype: modify
delete: accountUnlockTime

-

delete: retryCountResetTime
EOF
    ldapmodify -D "cn=Directory Manager" -w $MGR_PW -f $TMP_LDIF
    rm $TMP_LDIF
}

function createLdif(){
    local username=$1
    local uid=$2
    cat <<EOF >> $TMP_LDIF
dn: cn=$username,ou=$USER_OU,$SUFFIX
cn: $username
objectClass: top
objectClass: account
objectClass: posixAccount
uid: $username
uidNumber: $uid
gidNumber: $GID
userPassword: P@ssw0rd
homeDirectory: /home/$username
loginShell: /bin/bash
EOF
    echo -en '\n-\n' >> $TMP_LDIF
}

function bulkCreateUsers(){
    local userList=$1
    while read line; do
        local username=`echo $line | awk '{print $1}'`
        local uid=`echo $line | awk '{print $2}'`
        createLdif $username $uid
    done < $userList
    ldapadd -x -D "cn=Directory Manager" -w $MGR_PW -f $TMP_LDIF
    if [ $? -ne 0 ]; then
        echo 'Add user was failed!'
        rm $TMP_LDIF
        exit 1
    else
        echo 'Add user was successed!'
        rm $TMP_LDIF
    fi
}

function bulkDeleteUsers(){
    local userList=$1
    while read line; do
        local username=`echo $line | awk '{print $1}'`
        ldapdelete -x -D "cn=Directory Manager" -w $MGR_PW 'uid='${username}',ou='${USER_OU}','${SUFFIX}
        if [ $? -ne 0 ]; then
            echo 'Delete '$username' was failed!'
            exit 1
        else
            echo 'Delete '$username' was successed!'
        fi
    done < $userList
}

function listUser(){
    ldapsearch -x -D "cn=Directory Manager" -w ${MGR_PW} -b ${SUFFIX} uid | grep uid: | awk '{print $2}'
}

function userguide(){
    echo -e "usage: ./usermod [help | add | delete | bulkadd | bulkdelete | unlock]"
    echo -e "
optional arguments:

add <User name>                 Add single LDAP user on 389 Directory server.
delete <User name>              Delete single LDAP user on 389 Directory Server.
bulkadd <User LIST file>        Add LDAP users on 389 Directory Server.
bulkdelete <User LIST file>     Delete LDAP users on 389 Directory Server.
unlock <User name>              Unlock the locked user.
    "
}

function main(){
    [[ -z $1 ]] && { userguide; exit 1; }
    if [ $1 == 'bulkadd' ]; then
        [[ -z $2 ]] && { userguide; exit 1; }
        bulkCreateUsers $2
    elif [ $1 == 'bulkdelete' ]; then
        [[ -z $2 ]] && { userguide; exit 1; }
        bulkDeleteUsers $2
    elif [ $1 == 'add' ]; then
        [[ -z $2 ]] && { userguide; exit 1; }
        createUser $2
    elif [ $1 == 'delete' ]; then
        [[ -z $2 ]] && { userguide; exit 1; }
        deleteUser $2
    elif [ $1 == 'unlock' ]; then
        [[ -z $2 ]] && { userguide; exit 1; }
        userUnlock $2
    elif [ $1 == 'list' ]; then
        listUser
    elif [ $1 == 'help' ]; then
        userguide
    else
        userguide
        exit 1
    fi
}

main $1 $2
