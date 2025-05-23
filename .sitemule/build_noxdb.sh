#!/QOpenSys/usr/bin/qsh

echo "Build ${DIR_NAME}..."

PATH=/QOpenSys/pkgs/bin:$PATH \
&& cd "$HOME/$FOLDER_BASE_NAME" \
&& gmake -f Makefile all \
    BIN_LIB="$FOLDER_BASE_NAME" \