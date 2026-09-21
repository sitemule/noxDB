#!/usr/bin/env bash
set -e

if [ -d "$FOLDER_ROOT" ] && [ -n "$FOLDER_BASE_NAME" ];  then
    echo "Synchronizing files in \"$FOLDER_ROOT\" with MY_IBM_I:\"~/projects/$FOLDER_BASE_NAME\"..."

    # --mkpath is a GNU-rsync-only flag; the local client (e.g. macOS's
    # bundled openrsync) may not support it, so create the remote directory
    # ourselves instead of relying on it.
    ssh MY_IBM_I "mkdir -p ~/projects/$FOLDER_BASE_NAME"

    rsync -azv \
    --exclude .git/ \
    --exclude .gitignore \
    --exclude .gitattributes \
    --exclude .vscode/ \
    --exclude quar/ \
    --rsync-path="/QOpenSys/pkgs/bin/rsync" \
    "$FOLDER_ROOT/" \
    MY_IBM_I:"~/projects/$FOLDER_BASE_NAME/"
fi