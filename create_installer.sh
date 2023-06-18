#!/bin/bash
SDIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
cd "${SDIR}/payload"
tar czf ../payload.tar.gz *
cd $SDIR
cat install_script.sh payload.tar.gz > fcplus_installer.sh
chmod +x fcplus_installer.sh

