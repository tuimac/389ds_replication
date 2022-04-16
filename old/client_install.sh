#!/bin/bash

LDAP='ldap.tuimac.com'
BASE='dc=tuimac,dc=com'

# Install modules
yum install oddjob-mkhomedir sssd -y

# Set SSSD configuration
cat <<EOF > /etc/sssd/sssd.conf
[sssd]
debug_level = 3
config_file_version = 2
services = nss, sudo, pam, ssh
domains = default

[domain/default]
id_provider = ldap
auth_provider = ldap
chpass_provider = ldap
sudo_provider = ldap
ldap_sudo_search_base = ou=SUDOers,$BASE
ldap_uri = ldaps://$LDAP
ldap_search_base = $BASE
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

# Reflect changes to SSSD daemon
chmod 600 /etc/sssd/sssd.conf
systemctl restart sssd

# Set up auto creation of home directory
authconfig --enablemkhomedir --update
authconfig --enableldap --update
authconfig --enableldapauth --update
authconfig --enableshadow --update
authconfig --enablelocauthorize --update

# Activate SSH Password Authentication
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
