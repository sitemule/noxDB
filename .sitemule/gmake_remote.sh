#!/usr/bin/env bash
#
# Runs a gmake target directly on the IBM i host (no rsync - the caller is
# expected to already be in sync, e.g. via a prior compile/sync task).
#
# githash.c embeds the git commit via the makefile's `githash` target, which
# normally runs `git rev-parse` - but the remote checkout has no .git/ (it's
# excluded from rsync.sh), so that fails there. We compute GIT_SHORT/GIT_HASH
# here instead, on the PC where the real repo lives, and pass them through as
# make variables; the makefile only falls back to running git itself when
# they're not already set.

workspaceRoot="$1"
workspaceFolderBasename="$2"
target="$3"

SSH="ssh -Ss -k -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

GIT_VARS=""
if [ -d "$workspaceRoot/.git" ]; then
    GIT_SHORT=$(git -C "$workspaceRoot" rev-parse --short HEAD)
    GIT_HASH=$(git -C "$workspaceRoot" rev-parse --verify HEAD)
    GIT_VARS="GIT_SHORT='$GIT_SHORT' GIT_HASH='$GIT_HASH'"
fi

$SSH -t MY_IBM_I "PATH=/QOpenSys/pkgs/bin:\$PATH; cd ~/projects/'${workspaceFolderBasename}'/; gmake ${target} ${GIT_VARS}"
