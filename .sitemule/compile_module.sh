#!/usr/bin/env bash

workspaceRoot="$1"
workspaceFolderBasename="$2"
relativeFile="$3"
moduleName="$4"

SSH="ssh -Ss -k -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SYSTEM_VAR=$(uname -s)
if [ "$SYSTEM_VAR" != "OS400" ]; then
    FOLDER_ROOT="$workspaceRoot" FOLDER_BASE_NAME="$workspaceFolderBasename" "$SCRIPT_DIR/rsync.sh"
else
    echo "Running on IBM i (OS400) directly - skipping sync."
fi

echo "Compile..."
$SSH -t MY_IBM_I "PATH=/QOpenSys/pkgs/bin:\$PATH; cd ~/projects/'${workspaceFolderBasename}'/; gmake '${relativeFile}' --always-make; gmake update OBJ='${moduleName}'"
