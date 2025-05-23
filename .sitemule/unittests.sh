#!/QOpenSys/usr/bin/qsh

echo "Compile ..."

PATH=/QOpenSys/pkgs/bin:$PATH

cd "$HOME/$FOLDER_BASE_NAME/unittests" \
&& gmake -f Makefile.unittests compile \
    BIN_LIB="$FOLDER_BASE_NAME" \
    SRC="$FILE_BASE_NAME"