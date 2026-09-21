#!/QOpenSys/pkgs/bin/bash
#
# Bash replacement for the old compile.py (Python 2 / QOpenSys python is gone).
# Same calling convention as compile.py:
#   compile.sh --stmf=<path> --lib=<lib> --liblist=<liblist> --flags=<flags> --include=<include>
#
# Dispatches CRTxxx by file extension, honours a "CMD:<command>" annotation on
# the first source line (or second, if the first is **FREE) to override the
# default compile command per file - e.g. "// CMD:CRTCMOD" forces a *MODULE
# build instead of the default *PGM build - and prints compiler diagnostics
# from the EVFEVENT member in a "file:line:col:severity:code:message" shape
# that matches the "c" problem matcher in tasks.json / the makefile.
set -u

stmf=""; lib=""; liblist=""; flags=""; include=""

for arg in "$@"; do
    case "$arg" in
        --stmf=*)    stmf="${arg#--stmf=}" ;;
        --lib=*)     lib="${arg#--lib=}" ;;
        --liblist=*) liblist="${arg#--liblist=}" ;;
        --flags=*)   flags="${arg#--flags=}" ;;
        --include=*) include="${arg#--include=}" ;;
    esac
done

filename="${stmf##*/}"
obj="${filename%.*}"
ext="${filename##*.}"

STDERR_TMP="/tmp/.nox_compile_stderr.$$"
EVFEVENT_TMP="/tmp/.nox_compile_evfevent.$$"

cleanup() {
    rm -f "$STDERR_TMP" "$EVFEVENT_TMP"
}
trap cleanup EXIT

# ------------------------------------------------------------------------
# Pick up an optional "CMD:<command>(<extra flags>)" annotation from the
# first non-**FREE line of the source. Source-supplied flags win over the
# makefile's, except for .cmd sources where they are merged.
# ------------------------------------------------------------------------
pick_up_flags() {
    firstline=$(sed -n '1p' "$stmf" 2>/dev/null)
    case "$firstline" in
        '**FREE'*) firstline=$(sed -n '2p' "$stmf" 2>/dev/null) ;;
    esac
    cmd=$(printf '%s\n' "$firstline" | sed -n 's/.*CMD:\([^[:space:]]*\).*/\1/p')
    extflags=$(printf '%s\n' "$firstline" | sed -n 's/.*CMD:[^[:space:]]*[[:space:]]*\((.*)\).*/\1/p')
}

cmd=""; extflags=""
pick_up_flags

if [ "$ext" = "cmd" ]; then
    flags="$flags $extflags"
elif [ -n "$extflags" ]; then
    flags="$extflags"
fi

# ------------------------------------------------------------------------
# Diagnostics: filtered stderr (informational noise from "system") and the
# structured EVFEVENT member (real compiler errors/warnings).
# ------------------------------------------------------------------------
print_stderr_info() {
    i=0
    while IFS= read -r line || [ -n "$line" ]; do
        msgid="${line:0:7}"
        case "$msgid" in
            CPC2206|CZM1003|CPD4090|CZS2117|CPFB414|CPF5813|CPF7302|CPCA081|CPC0904|CPC7301|CPI2126) ;;
            *)
                i=$((i + 1))
                printf '%s:0:%d:info:%s\n' "$stmf" "$i" "$line"
                ;;
        esac
    done < "$STDERR_TMP"
}

show_event_file() {
    system -q "CPYTOSTMF FROMMBR('/QSYS.LIB/${lib}.LIB/EVFEVENT.FILE/${obj}.MBR') TOSTMF('$EVFEVENT_TMP') STMFOPT(*REPLACE) STMFCCSID(1252)" 2>/dev/null
    [ -f "$EVFEVENT_TMP" ] || return 0
    while IFS= read -r line || [ -n "$line" ]; do
        lntype="${line:0:5}"
        [ "$lntype" = "ERROR" ] || continue
        msgid="${line:48:7}"
        severity="${line:56:1}"
        lineno="${line:37:6}"
        colno="${line:44:3}"
        msgtext="${line:65:9999}"
        case "$msgid" in
            RNF7031|RNF7534|RNF5409) continue ;;
        esac
        sev="error"
        case "$severity" in I|W) sev="info" ;; esac
        printf '%s:%s:%s:%s:%s:%s\n' "$stmf" "$lineno" "$colno" "$sev" "$msgid" "$msgtext"
    done < "$EVFEVENT_TMP"
}

# Run $1 (a function name), capturing its stderr for the filtered print above.
run_with_stderr_report() {
    { "$1"; } 2>"$STDERR_TMP"
    print_stderr_info
}

# ------------------------------------------------------------------------
# Build scripts - one per target type, mirroring compile.py's build_* functions
# ------------------------------------------------------------------------
build_cmod() {
    liblist -a "$liblist"
    setccsid 1252 "$stmf"
    local_cmd="${cmd:-CRTBNDC}"
    echo_and_run() { echo "$1"; touch postlist.txt; setccsid 1252 postlist.txt; system -vK "$1" >postlist.txt; }
    if [ "$local_cmd" = "CRTBNDC" ]; then
        echo_and_run "$local_cmd SRCSTMF('$stmf') PGM($lib/$obj) $flags INCDIR($include)"
    else
        echo_and_run "$local_cmd SRCSTMF('$stmf') MODULE($lib/$obj) $flags INCDIR($include)"
    fi
}

build_cppmod() {
    flags="$flags OPTION(*EVENTF) OUTPUT(*PRINT)"
    liblist -a "$liblist"
    setccsid 1252 "$stmf"
    local_cmd="${cmd:-CRTBNDCPP}"
    echo_and_run() { echo "$1"; touch postlist.txt; setccsid 1252 postlist.txt; system -vK "$1" >postlist.txt; }
    if [ "$local_cmd" = "CRTBNDCPP" ]; then
        echo_and_run "$local_cmd SRCSTMF('$stmf') PGM($lib/$obj) $flags INCDIR($include)"
    else
        echo_and_run "$local_cmd SRCSTMF('$stmf') MODULE($lib/$obj) $flags INCDIR($include)"
    fi
}

build_rpgmod() {
    flags="$flags OPTION(*NOUNREF *EVENTF)"
    liblist -a "$liblist"
    setccsid 1252 "$stmf"
    local_cmd="${cmd:-CRTBNDRPG}"
    echo_and_run() { echo "$1"; touch postlist.txt; setccsid 1252 postlist.txt; system -vK "$1" >postlist.txt; }
    if [ "$local_cmd" = "CRTBNDRPG" ]; then
        echo_and_run "$local_cmd SRCSTMF('$stmf') PGM($lib/$obj) $flags INCDIR($include)"
    else
        echo_and_run "$local_cmd SRCSTMF('$stmf') MODULE($lib/$obj) $flags INCDIR($include)"
    fi
}

build_sqlrpgmod() {
    flags="$flags OPTION(*EVENTF)"
    liblist -a "$liblist"
    setccsid 1252 "$stmf"
    echo "CRTSQLRPGI SRCSTMF('$stmf') OBJ($lib/$obj) $flags INCDIR($include)"
    touch postlist.txt; setccsid 1252 postlist.txt
    system -vK "CRTSQLRPGI SRCSTMF('$stmf') OBJ($lib/$obj) $flags INCDIR($include)" >postlist.txt
}

build_clmod() {
    flags="$flags OPTION(*EVENTF)"
    liblist -a "$liblist"
    setccsid 1252 "$stmf"
    system -vK "CRTSRCPF FILE($lib/QCLLESRC) RCDLEN(112)"
    system -vK "CPYFRMSTMF FROMSTMF('$stmf') TOMBR('/QSYS.lib/$lib.lib/QCLLESRC.file/$obj.mbr') MBROPT(*replace)"
    local_cmd="${cmd:-CRTBNDCL}"
    echo_and_run() { echo "$1"; touch postlist.txt; setccsid 1252 postlist.txt; system -vK "$1" >postlist.txt; }
    if [ "$local_cmd" = "CRTBNDCL" ]; then
        echo_and_run "$local_cmd SRCFILE($lib/QCLLESRC) PGM($lib/$obj) $flags INCFILE($include)"
    else
        echo_and_run "$local_cmd SRCFILE($lib/QCLLESRC) MODULE($lib/$obj) $flags INCFILE($include)"
    fi
}

build_srvpgm() {
    liblist -a "$liblist"
    system -vK "CHGATR OBJ('$stmf') ATR(*CCSID) VALUE(1252)"
    system -vK "CRTSRCPF FILE($lib/QSRVSRC) RCDLEN(132)"
    system -vK "CPYFRMSTMF FROMSTMF('$stmf') TOMBR('/QSYS.lib/$lib.lib/QSRVSRC.file/$obj.mbr') MBROPT(*REPLACE)"
    system -vK "CRTSRVPGM SRVPGM($lib/$obj) $flags"
}

build_cmd_obj() {
    liblist -a "$liblist"
    setccsid 1252 "$stmf"
    system -vK "CRTSRCPF FILE($lib/QCMDSRC) RCDLEN(132)"
    system -vK "CPYFRMSTMF FROMSTMF('$stmf') TOMBR('/QSYS.lib/$lib.lib/QCMDSRC.file/$obj.mbr') MBROPT(*REPLACE)"
    echo "CRTCMD CMD($lib/$obj) SRCFILE($lib/QCMDSRC) $flags"
    touch postlist.txt; setccsid 1252 postlist.txt
    system -vK "CRTCMD CMD($lib/$obj) SRCFILE($lib/QCMDSRC) $flags" >postlist.txt
}

build_dspf() {
    flags="$flags OPTION(*EVENTF)"
    liblist -a "$liblist"
    setccsid 1252 "$stmf"
    system -vK "CRTSRCPF FILE($lib/QDDSSRC) RCDLEN(132)"
    system -vK "CPYFRMSTMF FROMSTMF('$stmf') TOMBR('/QSYS.lib/$lib.lib/QDDSSRC.file/$obj.mbr') MBROPT(*REPLACE)"
    echo "CRTDSPF FILE($lib/$obj) SRCFILE($lib/QDDSSRC) $flags"
    touch postlist.txt; setccsid 1252 postlist.txt
    system -vK "CRTDSPF FILE($lib/$obj) SRCFILE($lib/QDDSSRC) $flags" >postlist.txt
}

build_menu() {
    flags="$flags OPTION(*EVENTF)"
    liblist -a "$liblist"
    setccsid 1252 "$stmf"
    system -vK "CRTSRCPF FILE($lib/QUIMSRC) RCDLEN(132)"
    system -vK "CPYFRMSTMF FROMSTMF('$stmf') TOMBR('/QSYS.lib/$lib.lib/QUIMSRC.file/$obj.mbr') MBROPT(*REPLACE)"
    echo "CRTMNU TYPE(*UIM) MENU($lib/$obj) SRCFILE($lib/QUIMSRC) $flags"
    touch postlist.txt; setccsid 1252 postlist.txt
    system -vK "CRTMNU TYPE(*UIM) MENU($lib/$obj) SRCFILE($lib/QUIMSRC) $flags" >postlist.txt
}

build_pnlgrp() {
    flags="$flags OPTION(*EVENTF)"
    liblist -a "$liblist"
    setccsid 1252 "$stmf"
    system -vK "CRTSRCPF FILE($lib/QUIMSRC) RCDLEN(132)"
    system -vK "CPYFRMSTMF FROMSTMF('$stmf') TOMBR('/QSYS.lib/$lib.lib/QUIMSRC.file/$obj.mbr') MBROPT(*REPLACE)"
    echo "CRTPNLGRP PNLGRP($lib/$obj) SRCFILE($lib/QUIMSRC) $flags"
    touch postlist.txt; setccsid 1252 postlist.txt
    system -vK "CRTPNLGRP PNLGRP($lib/$obj) SRCFILE($lib/QUIMSRC) $flags" >postlist.txt
}

build_sql() {
    liblist -a "$liblist"
    setccsid 1252 "$stmf"
    db2 -f "$stmf"
}

# ------------------------------------------------------------------------
# Main line
# ------------------------------------------------------------------------
case "$ext" in
    c)        run_with_stderr_report build_cmod;      show_event_file ;;
    cpp)      run_with_stderr_report build_cppmod;    show_event_file ;;
    rpgle)    run_with_stderr_report build_rpgmod;    show_event_file ;;
    sqlrpgle) run_with_stderr_report build_sqlrpgmod; show_event_file ;;
    clle)     run_with_stderr_report build_clmod;     show_event_file ;;
    srvpgm)   build_srvpgm ;;
    cmd)      run_with_stderr_report build_cmd_obj ;;
    dspf)     run_with_stderr_report build_dspf;      show_event_file ;;
    menu)     run_with_stderr_report build_menu;      show_event_file ;;
    pnlgrp)   run_with_stderr_report build_pnlgrp;    show_event_file ;;
    sql)      build_sql ;;
    *)        echo "no compiler for $ext" ;;
esac
