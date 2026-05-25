#!/bin/bash

cd "$(dirname "$0")" || exit

echo ">>> 初始化 Kodi MariaDB..."
ansible-playbook site_mariadb.yml "$@"
