#!/usr/bin/env bash
set -e

if [ -d "$FOLDER_ROOT" ] && [ -n "$FOLDER_BASE_NAME" ];  then
    echo "Synchronizing files in \"$FOLDER_ROOT\" with MY_IBM_I:\"$HOME/$FOLDER_BASE_NAME\"..."

    rsync -azv \
    --exclude .git/ \
    --exclude .gitignore \
    --exclude .gitattributes \
    --exclude .vscode/ \
    --exclude quar/ \
    --mkpath \
    --rsync-path="/QOpenSys/pkgs/bin/rsync" \
    "$FOLDER_ROOT/" \
    MY_IBM_I:"$HOME/$FOLDER_BASE_NAME/"
fi