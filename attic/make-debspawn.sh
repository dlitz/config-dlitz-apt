#!/bin/bash
# dlitz 2023
set -eux

apt-get download config-dlitz-keyrings=0.0.4
debspawn_image_name=reconstruct-config-dlitz-apt-bookworm-amd64
debspawn create --arch=amd64 --suite=bookworm "$debspawn_image_name"
./debspawn-add-package "$debspawn_image_name" ./config-dlitz-keyrings_0.0.4_all.deb
./debspawn-apt-install-package "$debspawn_image_name" gnupg
echo "$debspawn_image_name"
