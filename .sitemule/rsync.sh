#!/usr/bin/env bash
set -e

#  --mkpath \

if [ -d "$FOLDER_ROOT" ] && [ -n "$FOLDER_BASE_NAME" ];  then
    echo "Synchronizing files in \"$FOLDER_ROOT\" with MY_IBM_I:\"~/projects/$FOLDER_BASE_NAME\"..."

    rsync -azv \
    --exclude .git/ \
    --exclude .gitignore \
    --exclude .gitattributes \
    --exclude .vscode/ \
    --exclude quar/ \
    --rsync-path="/QOpenSys/pkgs/bin/rsync" \
    "$FOLDER_ROOT/" \
    MY_IBM_I:"~/projects/$FOLDER_BASE_NAME/"
    # Leave a note on the IFS: this folder is a copy of the git repo, edits here are lost
    "$(dirname "$0")/git_managed_note.sh" MY_IBM_I "~/projects/$FOLDER_BASE_NAME"
fi