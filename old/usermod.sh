#!/bin/bash

DN='dc=tuimac,dc=com'
LDAPPW='P@ssw0rd'

function createLdif(){
    local ldifFileName=$ldif
    local username=$1
    local uid=$2
    cat <<EOF >> $ldifFileName
dn: cn=$username,ou=user,$DN
cn: $username
objectClass: top
objectClass: account
objectClass: posixAccount
uid: $username
uidNumber: $uid
gidNumber: 2000
userPassword: P@ssw0rd
homeDirectory: /home/$username
loginShell: /bin/bash
EOF
    echo -en '\n-\n' >> $ldifFileName
}

function createUser(){
    [[ -z $1 ]] && { echo 'Need user list file for this argument.'; exit 1; }
    local userList=$1
    ldif=userAdd-$(date '+%Y%m%d%H%M%S').ldif
    # Add user to LDIF file
    while read line; do
        local username=`echo $line | awk '{print $1}'`
        local uid=`echo $line | awk '{print $2}'`
        createLdif $username $uid
    done < $userList
    # Execute add user to LDAP
    ldapadd -x -D "cn=Directory Manager" -w ${LDAPPW} -f $ldif
    if [ $? -ne 0 ]; then
        echo 'Add user was failed!'
        exit 1
    else
        echo 'Add user was successed!'
        rm $ldif
    fi
}

function deleteUser(){
    local userList=$1
    while read line; do
        local username=`echo $line | awk '{print $1}'`
        ldapdelete -x -D "cn=Directory Manager" -w ${LDAPPW} "cn=${username},ou=user,${DN}"
        if [ $? -ne 0 ]; then
            echo 'Delete user was failed!'
            exit 1
        else
            echo 'Delete '$username' was successed!'
        fi
    done < $userList
}

function listUser(){
    ldapsearch -x -D "cn=Directory Manager" -w ${LDAPPW} -b ${DN} uid | grep uid: | awk '{print $2}'
}

function userguide(){
    echo -e "usage: ./usermod [help | add | delete]"
    echo -e "
optional arguments:

add <User LIST file>        Add LDAP user on 389 Directory Server.
delete <User LIST file>     Delete LDAP user on 389 Directory Server.
    "
}

function main(){
    [[ -z $1 ]] && { userguide; exit 1; }
    if [ $1 == 'add' ]; then
        createUser $2
    elif [ $1 == 'delete' ]; then
        deleteUser $2
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
