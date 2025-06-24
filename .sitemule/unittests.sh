#!/usr/bin/env bash

fileBasename="$4"
relativeFile="$3"
workspaceFolderBasename="$2"
workspaceRoot="$1"

SSH="ssh -Ss -k -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

SYSTEM_VAR=$(uname -s)
if ! [ "$SYSTEM_VAR" == "OS400" ]; then
    echo "Sync..."
    rsync -azv \
    --mkpath \
    --rsync-path="/QOpenSys/pkgs/bin/rsync" \
    --exclude .git/ \
    --exclude .gitignore \
    --exclude .gitattributes \
    --exclude .vscode/ \
    --exclude quar/ \
    -e "$SSH" \
    "${workspaceRoot}/" \
    MY_IBM_I:"/tmp/sletmig/${workspaceFolderBasename}/"
fi

echo "Compile..."
$SSH -t MY_IBM_I "PATH=/QOpenSys/pkgs/bin:$PATH; cd '/tmp/sletmig/${workspaceFolderBasename}/unittests/'; gmake -f Makefile.unittests compile SRC='${fileBasename}'"