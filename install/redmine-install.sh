#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: SunFlowerOwl
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://redmine.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
		bash \
		breezy \
		ca-certificates \
		findutils \
		ghostscript \
		ghostscript-fonts \
		git \
		imagemagick \
		mercurial \
		openssh-client \
		subversion \
		tini \
		tzdata \
		wget \
    	.build-deps \
		cargo \
		clang19-dev \
		coreutils \
		freetds-dev \
		gcc \
		make \
		mariadb-dev \
		musl-dev \
		patch \
		postgresql-dev \
		yaml-dev \
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "redmine" "redmine/redmine" "tarball" "latest" "/opt/redmine"

RUBY_INSTALL_VERSION=3.4
RUBY_VERSION=${RUBY_INSTALL_VERSION} RUBY_INSTALL_RAILS="true" setup_ruby

msg_info "Configuring gem"
$STD bundle config set --local without 'development test' 
$STD bundle install
msg_ok "Configured gem"

msg_info "Setting up Rails"
$STD bundle exec rake generate_secret_token
msg_ok "Set up Rails"

msg_info "Adding redmine user"
addgroup -S -g 1000 redmine && adduser -S -H -G redmine -u 999 redmine
msg_ok "Added redmine user"

msg_info "Configuring Redmine"
mkdir -p tmp tmp/pdf public/assets
sudo chown -R redmine:redmine files log tmp public/assets
sudo chmod -R 755 files log tmp public/assets
msg_ok "Configured Redmine"

msg_info "Creating Default Configuration Files"
cp /opt/redmine/config/database.yml.example /opt/redmine/config/database.yml
msg_ok "Created Default Configuration Files"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/redmine.service
[Unit]
Description=Redmine
Requires=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/redmine
ExecStart=/opt/redmine/bin/rails server -b 127.0.0.1 --port 3000 --environment production
TimeoutSec=30
RestartSec=15s
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now redmine
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
