#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://redmine.org/

APP="Redmine"
var_tags="${var_tags:-dev-tools}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
    if [[ ! -d /opt/redmine ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="24" NODE_MODULE="corepack,yarn" setup_nodejs
  ensure_dependencies f3d
  
  if check_for_gh_release "redmine" "redmine/redmine"; then
    msg_info "Stopping Services"
    systemctl stop redmine
    msg_ok "Stopped Services"

    msg_info "Backing up Data"
    CURRENT_VERSION=$(grep -oP 'APP_VERSION=\K[^ ]+' /opt/redmine/.env || echo "unknown")
    $STD tar -czf "/opt/redmine_${CURRENT_VERSION}_backup.tar.gz" -C /opt/redmine app
    msg_ok "Backed up Data"

    create_backup /opt/redmine/config/database.yml /opt/redmine/config/configuration.yml

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "redmine" "redmine/redmine" "tarball" "latest" "/opt/redmine"

    restore_backup

    msg_info "Configuring Redmine"
    $STD bundle config set --local without 'development test' 
    $STD bundle install
    $STD bundle exec rake generate_secret_token
    mkdir -p tmp tmp/pdf public/assets
    sudo chown -R redmine:redmine files log tmp public/assets
    sudo chmod -R 755 files log tmp public/assets
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"