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
BIN_LIB=NOXDB2
LIBLIST=$(BIN_LIB) 
TARGET_CCSID=*JOB
TARGET_RELEASE=*CURRENT

# CL - settings
CL_FLAGS=DBGVIEW(*ALL)
CL_INCLUDE=*SRCFILE


# C - Settings
C_FLAGS=OPTIMIZE(10) ENUM(*INT) TERASPACE(*YES) STGMDL(*INHERIT) SYSIFCOPT(*IFSIO) DBGVIEW(*ALL)
C_INCLUDE='/QIBM/include' 'include' 'ext/include'

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
EXTERNALS := $(shell find ext -name "*.c" -o -name   "*.clle" )
SOURCE  := $(shell find src -name "*.c" -o -name   "*.clle" )




all:  $(BIN_LIB).lib hdr $(EXTERNALS) $(SOURCE) noxdb2.srvpgm noxdb2.bnddir release


%.lib:
	-system -q "CRTLIB $* TYPE(*TEST)"

$(EXTERNALS) $(SOURCE): FORCE
	$(CC)

noxdb2.srvpgm: hdr src/noxDB2.c src/sqlio.c src/csv.c src/xmlparser.c src/jsonparser.c src/serializer.c src/reader.c src/iterator.c src/http.c src/generic.c src/trace.clle ext/src/memUtil.c ext/src/parms.c ext/src/sndpgmmsg.c ext/src/stream.c ext/src/timestamp.c ext/src/trycatch.c ext/src/strUtil.c ext/src/varchar.c ext/src/xlate.c ext/src/e2aa2e.c 
	@# You may be wondering what this ugly string is. It's a list of objects created from the dep list that end with .c or .clle.
	$(eval MODULES = $(notdir $(basename $(filter %.c %.clle , $^))))
	compile.py --stmf="src/$@" --lib="$(BIN_LIB)" --liblist="$(LIBLIST)" \
		--flags="MODULE($(MODULES)) ALWLIBUPD(*YES) TGTRLS($(TARGET_RELEASE)) DETAIL(*BASIC)"

noxdb2.bnddir: 
	-system "DLTBNDDIR  BNDDIR($(BIN_LIB)/$(BIN_LIB))"
	-system "CRTBNDDIR  BNDDIR($(BIN_LIB)/$(BIN_LIB))"
	-system "ADDBNDDIRE BNDDIR($(BIN_LIB)/$(BIN_LIB)) OBJ(($(BIN_LIB)/$(BIN_LIB) *SRVPGM))"


hdr:
	sed "s/ nox_/ json_/g; s/ NOX_/ JSON_/g" headers/noxDB2.rpgle > headers/noxDB2JSON.rpgle
	sed "s/ nox_/ xml_/g; s/ NOX_/ XML_/g" headers/noxDB2.rpgle > headers/noxDB2XML.rpgle

	-system -i "CRTSRCPF FILE($(BIN_LIB)/QRPGLEREF) RCDLEN(132)"
	-system -i "CRTSRCPF FILE($(BIN_LIB)/H) RCDLEN(132)"
  
	system "CPYFRMSTMF FROMSTMF('headers/noxDB2JSON.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/noxDB2JSON.mbr') MBROPT(*REPLACE)"
	system "CPYFRMSTMF FROMSTMF('headers/noxDB2XML.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/noxDB2XML.mbr') MBROPT(*REPLACE)"
	system "CPYFRMSTMF FROMSTMF('include/noxDB2.h') TOMBR('/QSYS.lib/$(BIN_LIB).lib/H.file/noxDB2.mbr') MBROPT(*REPLACE)"

all:
	@echo Build success!

cleanup:
	-system -q "DLTOBJ OBJ($(BIN_LIB)/*ALL)     OBJTYPE(*MODULE)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/QSRVSRC)  OBJTYPE(*FILE)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/EVFEVENT) OBJTYPE(*FILE)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/RELEASE) OBJTYPE(*FILE)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/TS*)      OBJTYPE(*PGM)"

release: cleanup 
	@echo " -- Creating noxdb2 release. --"
	@echo " -- Creating save file. --"
	system "CRTSAVF FILE($(BIN_LIB)/RELEASE)"
	system "SAVLIB LIB($(BIN_LIB)) DEV(*SAVF) SAVF($(BIN_LIB)/RELEASE) OMITOBJ((RELEASE *FILE))"
	-rm -r release
	-mkdir release
	system "CPYTOSTMF FROMMBR('/QSYS.lib/$(BIN_LIB).lib/RELEASE.FILE') TOSTMF('./release/release-noxDB2.savf') STMFOPT(*REPLACE) STMFCCSID(1252) CVTDTA(*NONE)"
	@echo " -- Cleaning up... --"
	system "DLTOBJ OBJ($(BIN_LIB)/RELEASE) OBJTYPE(*FILE)"
	@echo " -- Release created! --"
	@echo ""
	@echo "To install the release, run:"
	@echo "  > CRTLIB $(BIN_LIB)"
	@echo "  > CPYFRMSTMF FROMSTMF('./release/release.savf') TOMBR('/QSYS.lib/$(BIN_LIB).lib/RELEASE.FILE') MBROPT(*REPLACE) CVTDTA(*NONE)"
	@echo "  > RSTLIB SAVLIB($(BIN_LIB)) DEV(*SAVF) SAVF($(BIN_LIB)/RELEASE)"
	@echo ""
	@echo "Or restore into existing application library"
	@echo "  > RSTOBJ OBJ(*ALL) SAVLIB($(BIN_LIB)) DEV(*SAVF) SAVF($(BIN_LIB)/RELEASE) MBROPT(*ALL) ALWOBJDIF(*FILELVL) RSTLIB(yourlib)     

FORCE:



