#!/usr/bin/env bash

workspaceRoot="$1"
workspaceFolderBasename="$2"
relativeFile="$3"
fileBasename="$4"
relativeFileDirname="$(dirname "$relativeFile")"

SSH="ssh -Ss -k -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

SYSTEM_VAR=$(uname -s)
if [ "$SYSTEM_VAR" != "OS400" ]; then
    echo "Sync..."
    rsync -azv \
    --rsync-path="/QOpenSys/pkgs/bin/rsync" \
    --exclude .git/ \
    --exclude .gitignore \
    --exclude .gitattributes \
    --exclude .vscode/ \
    --exclude quar/ \
    -e "$SSH" \
    "${workspaceRoot}/" \
    MY_IBM_I:"/prj/${workspaceFolderBasename}/"
else
    echo "Running on IBM i (OS400) directly - skipping sync."
fi

echo "Compile..."
$SSH -t MY_IBM_I "PATH=/QOpenSys/pkgs/bin:\$PATH; cd '/prj/${workspaceFolderBasename}/${relativeFileDirname}/'; gmake compile SRC='${fileBasename}'"
