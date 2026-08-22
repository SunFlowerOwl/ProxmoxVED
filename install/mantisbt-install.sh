#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: SunFlowerOwl
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://mantisbt.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PG_VERSION="16" setup_postgresql
PG_DB_NAME="mantisbt" PG_DB_USER="mantisbt" setup_postgresql_db
PHP_VERSION="8.4" PHP_MODULE="curl,xml,mbstring,intl,zip,pgsql,gmp,gd,fileinfo,ldap,soap" PHP_APACHE="YES" setup_php
setup_composer

fetch_and_deploy_gh_tag "mantisbt" "mantisbt/mantisbt" "latest" "/var/www/html/mantisbt"

msg_info "Configuring MantisBT"
cd "/var/www/html/mantisbt"
$STD composer install --no-dev
chown -R www-data:www-data "/var/www/html/mantisbt"
chmod -R 755 "/var/www/html/mantisbt"
cat <<EOF > /etc/apache2/sites-available/mantisbt.conf
<VirtualHost *:80>
    DocumentRoot /var/www/html/mantisbt
    <Directory /var/www/html/mantisbt>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
$STD a2ensite mantisbt.conf
$STD a2enmod rewrite
$STD systemctl reload apache2
msg_ok "Configured MantisBT"

motd_ssh
customize
cleanup_lxc
