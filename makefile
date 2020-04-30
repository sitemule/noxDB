
#-----------------------------------------------------------
# User-defined part start
#

# NOTE - UTF is not allowed for ILE source (yet) - so convert to WIN-1252

# BIN_LIB is the destination library for the service program.
# the rpg modules and the binder source file are also created in BIN_LIB.
# binder source file and rpg module can be remove with the clean step (make clean)
BIN_LIB=NOXDB
DBGVIEW=*ALL
TARGET_CCSID=*JOB

# Do not touch below
INCLUDE='/QIBM/include' 'headers/' 'headers/ext/'

CCFLAGS=OPTIMIZE(10) ENUM(*INT) TERASPACE(*YES) STGMDL(*INHERIT) SYSIFCOPT(*IFSIO) INCDIR($(INCLUDE)) DBGVIEW($(DBGVIEW)) TGTCCSID($(TARGET_CCSID))

# For current compile:
CCFLAGS2=OPTION(*STDLOGMSG) OUTPUT(*NONE) OPTIMIZE(10) ENUM(*INT) TERASPACE(*YES) STGMDL(*INHERIT) SYSIFCOPT(*IFSIO) DBGVIEW(*ALL) INCDIR($(INCLUDE)) 

#
# User-defined part end
#-----------------------------------------------------------

# Dependency list

all:  $(BIN_LIB).lib jsonxml.srvpgm hdr

jsonxml.srvpgm: noxdb.c sqlio.c xmlparser.c jsonparser.c serializer.c reader.c segments.c iterator.c http.c generic.c runqsh.clle trace.clle ext/mem001.c ext/parms.c ext/sndpgmmsg.c ext/stream.c ext/timestamp.c ext/trycatch.c ext/utl100.c ext/varchar.c ext/xlate.c ext/rtvsysval.c jsonxml.bnddir noxdb.bnddir

jsonxml.bnddir: jsonxml.entry
noxdb.bnddir: jsonxml.entry

#-----------------------------------------------------------

%.lib:
	-system -q "CRTLIB $* TYPE(*TEST)"

%.bnddir:
	-system -q "DLTBNDDIR BNDDIR($(BIN_LIB)/$*)"
	-system -q "CRTBNDDIR BNDDIR($(BIN_LIB)/$*)"
	-system -q "ADDBNDDIRE BNDDIR($(BIN_LIB)/$*) OBJ($(patsubst %.entry,(*LIBL/% *SRVPGM *IMMED),$^))"

%.entry:
	# Basically do nothing..
	@echo "Adding binding entry $*"

%.c:
	system -q "CHGATR OBJ('src/$*.c') ATR(*CCSID) VALUE(1252)"
	system "CRTCMOD MODULE($(BIN_LIB)/$(notdir $*)) SRCSTMF('src/$*.c') $(CCFLAGS)"

%.clle:
	system -q "CHGATR OBJ('src/$*.clle') ATR(*CCSID) VALUE(1252)"
	-system -q "CRTSRCPF FILE($(BIN_LIB)/QCLLESRC) RCDLEN(132)"
	system "CPYFRMSTMF FROMSTMF('src/$*.clle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QCLLESRC.file/$(notdir $*).mbr') MBROPT(*ADD)"
	system "CRTCLMOD MODULE($(BIN_LIB)/$(notdir $*)) SRCFILE($(BIN_LIB)/QCLLESRC) DBGVIEW($(DBGVIEW))"

%.srvpgm:
	-system -q "CRTSRCPF FILE($(BIN_LIB)/QSRVSRC) RCDLEN(132)"
	system "CPYFRMSTMF FROMSTMF('headers/$*.binder') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QSRVSRC.file/$*.mbr') MBROPT(*replace)"
	
	# You may be wondering what this ugly string is. It's a list of objects created from the dep list that end with .c or .clle.
	$(eval modules := $(patsubst %,$(BIN_LIB)/%,$(basename $(filter %.c %.clle,$(notdir $^)))))
	
	system -q -kpieb "CRTSRVPGM SRVPGM($(BIN_LIB)/$*) MODULE($(modules)) SRCFILE($(BIN_LIB)/QSRVSRC) ACTGRP(QILE) ALWLIBUPD(*YES) TGTRLS(*current)"

hdr:
	sed "s/ jx_/ json_/g; s/ JX_/ json_/g" headers/JSONXML.rpgle > headers/JSONPARSER.rpgle
	sed "s/ jx_/ xml_/g; s/ JX_/ xml_/g" headers/JSONXML.rpgle > headers/XMLPARSER.rpgle

	-system -q "CRTSRCPF FILE($(BIN_LIB)/QRPGLEREF) RCDLEN(132)"
	-system -q "CRTSRCPF FILE($(BIN_LIB)/H) RCDLEN(132)"
  
	system "CPYFRMSTMF FROMSTMF('headers/JSONPARSER.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/JSONPARSER.mbr') MBROPT(*REPLACE)"
	system "CPYFRMSTMF FROMSTMF('headers/XMLPARSER.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/XMLPARSER.mbr') MBROPT(*REPLACE)"
	system "CPYFRMSTMF FROMSTMF('headers/jsonxml.h') TOMBR('/QSYS.lib/$(BIN_LIB).lib/H.file/JSONXML.mbr') MBROPT(*REPLACE)"

all:
	@echo Build success!

clean:
	-system -q "DLTOBJ OBJ($(BIN_LIB)/*ALL) OBJTYPE(*FILE)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/*ALL) OBJTYPE(*MODULE)"
	
release: clean
	@echo " -- Creating noxdb release. --"
	@echo " -- Creating save file. --"
	system "CRTSAVF FILE($(BIN_LIB)/RELEASE)"
	system "SAVLIB LIB($(BIN_LIB)) DEV(*SAVF) SAVF($(BIN_LIB)/RELEASE) OMITOBJ((RELEASE *FILE))"
	-rm -r release
	-mkdir release
	system "CPYTOSTMF FROMMBR('/QSYS.lib/$(BIN_LIB).lib/RELEASE.FILE') TOSTMF('./release/release.savf') STMFOPT(*REPLACE) STMFCCSID(1252) CVTDTA(*NONE)"
	@echo " -- Cleaning up... --"
	system "DLTOBJ OBJ($(BIN_LIB)/RELEASE) OBJTYPE(*FILE)"
	@echo " -- Release created! --"
	@echo ""
	@echo "To install the release, run:"
	@echo "  > CRTLIB $(BIN_LIB)"
	@echo "  > CPYFRMSTMF FROMSTMF('./release/release.savf') TOMBR('/QSYS.lib/$(BIN_LIB).lib/RELEASE.FILE') MBROPT(*REPLACE) CVTDTA(*NONE)"
	@echo "  > RSTLIB SAVLIB($(BIN_LIB)) DEV(*SAVF) SAVF($(BIN_LIB)/RELEASE)"
	@echo ""

# For vsCode / single file then i.e.: gmake current sqlio.c  
current: 
	system -i "CRTCMOD MODULE($(BIN_LIB)/$(SRC)) SRCSTMF('src/$(SRC).c') $(CCFLAGS2) "

# For vsCode / single file then i.e.: gmake current sqlio.c  
example: 
	system -i "CRTBNDRPG PGM($(BIN_LIB)/$(SRC)) SRCSTMF('examples/$(SRC).rpgle') DBGVIEW(*ALL)" > error.txt
