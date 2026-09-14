#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
SOURCE_APP=${PROJECT_DIR}/dist/ClickShift.app
DESTINATION_APP=/Applications/ClickShift.app

if [[ ! -d "${SOURCE_APP}" ]]; then
  "${SCRIPT_DIR}/build-app.sh"
fi

ditto "${SOURCE_APP}" "${DESTINATION_APP}"
open "${DESTINATION_APP}"
echo "Installed and opened ${DESTINATION_APP}"
