#!/usr/bin/env bash
set -e

CMD_FILE="$1"
shift 1

ENV_VARS=""
while IFS='=' read -u9 -r key value; do
    if [[ "$key" == FILE_* ]] || [[ "$key" == FOLDER_* ]]; then
        ENV_VARS="$ENV_VARS $key='$value'"
    fi
done 9< <(printenv | sort)

if [ -d "$FOLDER_ROOT/.git" ]; then
	GIT_SHORT=$(git rev-parse --short HEAD)
	GIT_HASH=$(git rev-parse --verify HEAD)

    ENV_VARS="$ENV_VARS GIT_SHORT=$GIT_SHORT GIT_HASH=$GIT_HASH"
fi

echo "Remote run $CMD_FILE..."
ssh MY_IBM_I "/QOpenSys/usr/bin/env $ENV_VARS bash -s" -- <"$CMD_FILE" "$@"
