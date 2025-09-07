#-----------------------------------------------------------
# User-defined part start
#
# The shell we use
SHELL=/QOpenSys/pkgs/bin/bash
# NOTE - UTF is not allowed for ILE source (yet) - so convert to WIN-1252
# NOTE!! gmake is case sensitive for targets !!


# BIN_LIB is the destination library for the service program.
# the rpg modules and the binder source file are also created in BIN_LIB.
# binder source file and rpg module can be remove with the clean step (make clean)
.PHONY=all
BIN_LIB=NOXDBUTF8
LIBLIST=$(BIN_LIB) 
TARGET_CCSID=*JOB
TARGET_RELEASE=V7R3M0

# CL - settings
CLLE_FLAGS=DBGVIEW(*ALL) TGTRLS($(TARGET_RELEASE))
CLLE_INCLUDE=*SRCFILE


# C - Settings
C_FLAGS=OPTIMIZE(10) ENUM(*INT) TERASPACE(*YES) STGMDL(*INHERIT) SYSIFCOPT(*IFSIO) DBGVIEW(*ALL) TGTRLS($(TARGET_RELEASE))
#DEBUG C_FLAGS=OPTIMIZE(10) ENUM(*INT) TERASPACE(*YES) STGMDL(*INHERIT) SYSIFCOPT(*IFSIO)  TGTRLS($(TARGET_RELEASE))
C_INCLUDE='/QIBM/include' 'include' 'ext/include'

# CPP - Settings
CPP_FLAGS=OPTIMIZE(10) ENUM(*INT) TERASPACE(*YES) STGMDL(*INHERIT) SYSIFCOPT(*IFSIO) DBGVIEW(*ALL) TGTRLS($(TARGET_RELEASE))
#DEBUG C_FLAGS=OPTIMIZE(10) ENUM(*INT) TERASPACE(*YES) STGMDL(*INHERIT) SYSIFCOPT(*IFSIO)  TGTRLS($(TARGET_RELEASE))
CPP_INCLUDE='/QIBM/include' 'include' 'ext/include'

# RPG - Settings
RPGLE_INCLUDE='./..'
RPGLE_FLAGS=DBGVIEW(*LIST)

# SQLRPG - Settings
SQLRPG_INCLUDE='./..'
SQLRPG_FLAGS=DBGVIEW(*LIST) RPGPPOPT(*LVL2)


# CMD - Settings
CMD_FLAGS=PRDLIB($(BIN_LIB)) REPLACE(*YES)
CMD_INCLUDE=

# DSPF - Settings
DSPF_FLAGS=REPLACE(*YES)
DSPF_INCLUDE=

# SQL - Settings
SQL_FLAGS=COMMIT(*NONE)
SQL_INCLUDE=

#
# User-defined part end
#-----------------------------------------------------------

#-----------------------------------------------------------
# Compile macro
#-----------------------------------------------------------
UC = $(shell echo '$1' | tr '[:lower:]' '[:upper:]')
CC = $(eval FILEEXT = $(call UC,$(subst .,,$(suffix $@)))) \
	$(eval FLAGS   = $(FILEEXT)_FLAGS) \
	$(eval INCLUDE = $(FILEEXT)_INCLUDE) \
	@compile.py --stmf="$@" --lib="$(BIN_LIB)" --liblist="$(LIBLIST)" --flags="$($(FLAGS))" --include="$($(INCLUDE))"
#-----------------------------------------------------------

# Dependency list ---  list all
EXTERNALS := $(shell find ext -name "*.c" -o -name  "*.clle" )
SOURCE  := $(shell find src -name "*.cpp" -o -name "*.c" -o -name "*.clle" )



all:  $(BIN_LIB).lib link hdr $(EXTERNALS) $(SOURCE) noxDbUtf8.srvpgm noxDbUtf8.bnddir


%.lib:
	-system -q "CRTLIB $* TYPE(*TEST)"

# QOAR are for unknow reasons not in /QIBM/include
# We make link to them for copyright reasons - no copy
link:
	-mkdir -p ./ext/include/qoar/h
	-ln -s /QSYS.LIB/QOAR.LIB/H.file/QRNTYPES.MBR ./ext/include/qoar/h/qrntypes
	-ln -s /QSYS.LIB/QOAR.LIB/H.file/QRNDTAGEN.MBR ./ext/include/qoar/h/qrndtagen
	-ln -s /QSYS.LIB/QOAR.LIB/H.file/QRNDTAINTO.MBR ./ext/include/qoar/h/qrndtainto


$(EXTERNALS) $(SOURCE): FORCE
	$(CC)

noxDbUtf8.srvpgm: hdr src/initialize.cpp src/noxDbUtf8.c src/sqlio.c src/csv.c src/xmlparser.c \
						src/jsonparser.c src/jsonserial.c src/xmlserial.c src/tostream.c src/reader.c \
						src/iterator.c src/http.c src/generic.c src/trace.clle src/datagen.c\
						ext/src/memUtil.c ext/src/parms.c ext/src/sndpgmmsg.c ext/src/stream.c ext/src/timestamp.c \
						ext/src/trycatch.c \
						ext/src/strUtil.c ext/src/varchar.c ext/src/xlate.c ext/src/e2aa2e.c 
	@# You may be wondering what this ugly string is. It's a list of objects created from the dep list that end with .c or .clle.
	$(eval MODULES = $(notdir $(basename $(filter %.c %.clle %.cpp, $^))))
	compile.py --stmf="src/$@" --lib="$(BIN_LIB)" --liblist="$(LIBLIST)" \
		--flags="MODULE($(MODULES)) ALWLIBUPD(*YES) TGTRLS($(TARGET_RELEASE)) DETAIL(*BASIC)"

noxDbUtf8.bnddir: 
	-system "DLTBNDDIR  BNDDIR($(BIN_LIB)/$(BIN_LIB))"
	-system "CRTBNDDIR  BNDDIR($(BIN_LIB)/$(BIN_LIB))"
	-system "ADDBNDDIRE BNDDIR($(BIN_LIB)/$(BIN_LIB)) OBJ(($(BIN_LIB)/$(BIN_LIB) *SRVPGM))"


hdr:
#	sed "s/ nox_/ json_/g; s/ NOX_/ JSON_/g" headers/noxDbUtf8.rpgle > headers/noxDbUtf8JSON.rpgle
#	sed "s/ nox_/ xml_/g; s/ NOX_/ XML_/g" headers/noxDbUtf8.rpgle > headers/noxDbUtf8XML.rpgle

	-system -i "CRTSRCPF FILE($(BIN_LIB)/QRPGLEREF) RCDLEN(132)"
	-system -i "CRTSRCPF FILE($(BIN_LIB)/H) RCDLEN(132)"
  
	system "CPYFRMSTMF FROMSTMF('headers/noxDbUtf8.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/noxDbUtf8.mbr') MBROPT(*REPLACE)"
#	system "CPYFRMSTMF FROMSTMF('headers/noxDbUtf8JSON.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/noxDbUtf8JSON.mbr') MBROPT(*REPLACE)"
#	system "CPYFRMSTMF FROMSTMF('headers/noxDbUtf8XML.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/noxDbUtf8XML.mbr') MBROPT(*REPLACE)"
	system "CPYFRMSTMF FROMSTMF('include/noxDbUtf8.h') TOMBR('/QSYS.lib/$(BIN_LIB).lib/H.file/noxDbUtf8.mbr') MBROPT(*REPLACE)"

all:
	@echo Done - Check list above for errors!

.PHONY: update
update: 
	-system -q "UPDSRVPGM ($(BIN_LIB)/NOXDBUTF8) MODULE(*ALL)"

cleanup:
	-system -q "DLTOBJ OBJ($(BIN_LIB)/*ALL)     OBJTYPE(*MODULE)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/QSRVSRC)  OBJTYPE(*FILE)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/EVFEVENT) OBJTYPE(*FILE)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/RELEASE) OBJTYPE(*FILE)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/TS*)      OBJTYPE(*PGM)"

release: cleanup 
	@echo " -- Creating noxDbUtf8 release. --"
	@echo " -- Creating save file. --"
	system "CRTSAVF FILE($(BIN_LIB)/RELEASE)"
	system "SAVLIB LIB($(BIN_LIB)) DEV(*SAVF) SAVF($(BIN_LIB)/RELEASE) DTACPR(*HIGH) OMITOBJ((RELEASE *FILE))"
	-rm -r release
	-mkdir release
	system "CPYTOSTMF FROMMBR('/QSYS.lib/$(BIN_LIB).lib/RELEASE.FILE') TOSTMF('./release/release-noxDbUtf8.savf') STMFOPT(*REPLACE) STMFCCSID(1252) CVTDTA(*NONE)"
	@echo " -- Cleaning up... --"
	system "DLTOBJ OBJ($(BIN_LIB)/RELEASE) OBJTYPE(*FILE)"
	@echo " -- Release created! --"
	@echo ""
	@echo "To install the release, run:"
	@echo "  > CRTLIB $(BIN_LIB)"
	@echo "  > CPYFRMSTMF FROMSTMF('./release/release-noxDbUtf8.savf') TOMBR('/QSYS.lib/$(BIN_LIB).lib/RELEASE.FILE') MBROPT(*REPLACE) CVTDTA(*NONE)"
	@echo "  > RSTLIB SAVLIB($(BIN_LIB)) DEV(*SAVF) SAVF($(BIN_LIB)/RELEASE)"
	@echo ""
	@echo "Or restore into existing application library"
	@echo "  > RSTOBJ OBJ(*ALL) SAVLIB($(BIN_LIB)) DEV(*SAVF) SAVF($(BIN_LIB)/RELEASE) MBROPT(*ALL) ALWOBJDIF(*FILELVL) RSTLIB(yourlib)     

FORCE:



