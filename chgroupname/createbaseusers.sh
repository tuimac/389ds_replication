#!/bin/bash

SUFFIX='dc=tuimac,dc=com'

cat <<EOF > password.ldif
dn: cn=config
changetype: modify
add: passwordExp
passwordExp: on
-
dn: cn=config
changetype: modify
add: passwordMaxAge
passwordMaxAge: 300
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
add: passwordMinCategories
passwordMinCategories: 5
EOF

ldapadd -x -D "cn=Directory Manager" -w P@ssw0rd -f password.ldif
rm password.ldif

cat <<EOF > base.ldif
dn: cn=test,ou=Groups,$SUFFIX
objectClass: posixGroup
objectClass: top
cn: admin
gidNumber: 2000
-
dn: uid=test01,ou=People,$SUFFIX
uid: test01
cn: test01
objectClass: account
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
userPassword: P@ssw0rd
loginShell: /bin/bash
uidNumber: 2000
gidNumber: 2000
homeDirectory: /home/test01
-
dn: uid=test02,ou=People,$SUFFIX
uid: test02
cn: test02
objectClass: account
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
userPassword: P@ssw0rd
loginShell: /bin/bash
uidNumber: 2001
gidNumber: 2000
homeDirectory: /home/test02
EOF
    
ldapadd -x -D "cn=Directory Manager" -w P@ssw0rd -f base.ldif
rm base.ldif
