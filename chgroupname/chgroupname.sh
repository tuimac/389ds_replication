#!/bin/bash

SUFFIX='dc=tuimac,dc=com'
MGR_PW='P@ssw0rd'
GID='2000'
TMP_GID='2001'
USER_LIST=(
    'test01'
    'test02'
)
USER_OU='People'
GROUP_OU='Groups'
OLD_GROUP_NAME='test'
NEW_GROUP_NAME='testadm'

function create_new_group(){
    local ldif='create_group.ldif'
    cat << EOF > $ldif
dn: cn=$NEW_GROUP_NAME,ou=$GROUP_OU,$SUFFIX
objectClass: posixGroup
objectClass: top
cn: $NEW_GROUP_NAME
gidNumber: $TMP_GID
EOF
    ldapadd -x -D "cn=Directory Manager" -w ${MGR_PW} -f $ldif
    rm $ldif
}

function change_belongs(){
    local ldif='modify_user_belongs.ldif'
    local gid=$1
    for user in ${USER_LIST[@]}; do
        cat << EOF >> $ldif
dn: cn=$user,ou=$USER_OU,$SUFFIX
changetype: modify
replace: gidNumber
gidNumber: $gid
EOF
        echo -en '\n-\n' >> $ldif
    done
    ldapmodify -x -D "cn=Directory Manager" -w ${MGR_PW} -f $ldif
    rm $ldif
}

function delete_former_group(){
    local ldif='delete_group.ldif'
    ldapdelete -x -D "cn=Directory Manager" -w $MGR_PW 'cn='$OLD_GROUP_NAME',ou='$GROUP_OU','$SUFFIX
}

function chenge_gid(){
    local ldif='chenge_gid.ldif'
    cat << EOF > $ldif
dn: cn=$NEW_GROUP_NAME,ou=$GROUP_OU,$SUFFIX
changetype: modify
replace: gidNumber
gidNumber: $GID
EOF
    ldapmodify -x -D "cn=Directory Manager" -w ${MGR_PW} -f $ldif
    rm $ldif
}

function main(){
    create_new_group
    change_belongs $TMP_GID
    delete_former_group
    chenge_gid
    change_belongs $GID
}

main
