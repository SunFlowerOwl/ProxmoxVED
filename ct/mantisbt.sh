#!/usr/bin/env bash
# Engine comes from community-scripts/core; this repo only ships the scripts.
# A local core checkout wins (COMMUNITY_SCRIPTS_CORE_DIR, else a sibling ../core),
# so a fork or branch of core can be tested without editing this file.
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Copyright (c) 2021-2025 community-scripts ORG
# Author: SunFlowerOwl
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://mantisbt.org/

APP="MantisBT"
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

  if check_for_gh_release "manyfold" "manyfold3d/manyfold"; then
    msg_info "Stopping Service"
    cp /var/www/html/mantisbt/mantis_offline.php.sample /var/www/html/mantisbt/mantis_offline.php
    systemctl stop apache2
    msg_ok "Stopped Service"

    dirs=$(find "/var/www/html/mantisbt/plugins" -maxdepth 1 ! -path "/var/www/html/mantisbt/plugins" \( -type d -o -type l \) | grep -Pv "(Gravatar|MantisCoreFormatting|MantisGraph|XmlImportExport)" || true)
    create_backup /var/www/html/mantisbt/config_inc.php \
      /var/www/html/mantisbt/custom_strings_inc.php \
      /var/www/html/mantisbt/custom_constants_inc.php \
      /var/www/html/mantisbt/mantis_offline.php \
      /var/www/html/mantisbt/custom_functions_inc.php \
      $dirs

    CLEAN_INSTALL=1 fetch_and_deploy_gh_tag "mantisbt" "mantisbt/mantisbt" "latest" "/var/www/html/mantisbt"
    cd "/var/www/html/mantisbt"
    $STD composer install --no-dev
    restore_backup

    msg_info "Restoring ${APP}"
    chown -R www-data:www-data "/var/www/html/mantisbt"
    chmod -R 755 "/var/www/html/mantisbt"
    systemctl start apache2
    msg_ok "Restored Service ${APP}"
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