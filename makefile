
#-----------------------------------------------------------
# User-defined part start
#

# NOTE - UTF is not allowed for ILE source (yet) - so convert to WIN-1208

# BIN_LIB is the destination library for the service program.
# the rpg modules and the binder source file are also created in BIN_LIB.
# binder source file and rpg module can be remove with the clean step (make clean)
BIN_LIB=NOXDB2
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

all: clean $(BIN_LIB).lib noxdb.srvpgm hdr

noxdb.srvpgm: noxdb.c sqlio.c csv.c xmlparser.c jsonparser.c serializer.c reader.c iterator.c http.c generic.c runqsh.clle trace.clle ext/memUtil.c ext/parms.c ext/sndpgmmsg.c ext/stream.c ext/timestamp.c ext/trycatch.c ext/strUtil.c ext/varchar.c ext/xlate.c ext/e2aa2e.c noxdb.bnddir

noxdb.bnddir: noxdb.entry

#-----------------------------------------------------------

%.lib:
	-system -qi "CRTLIB $* TYPE(*TEST)"

%.bnddir:
	-system -qi "CRTBNDDIR BNDDIR($(BIN_LIB)/$*)"
	-system -qi "ADDBNDDIRE BNDDIR($(BIN_LIB)/$*) OBJ($(patsubst %.entry,($(BIN_LIB)/% *SRVPGM *IMMED),$^))"

%.entry:
	# Basically do nothing..
	@echo "Adding binding entry $*"

%.c:
	system -i "CHGATR OBJ('src/$*.c') ATR(*CCSID) VALUE(1208)"
	system "CRTCMOD MODULE($(BIN_LIB)/$(notdir $*)) SRCSTMF('src/$*.c') $(CCFLAGS)"

%.clle:
	system -i "CHGATR OBJ('src/$*.clle') ATR(*CCSID) VALUE(1208)"
	-system -qi "CRTSRCPF FILE($(BIN_LIB)/QCLLESRC) RCDLEN(132)"
	system "CPYFRMSTMF FROMSTMF('src/$*.clle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QCLLESRC.file/$(notdir $*).mbr') MBROPT(*ADD)"
	system "CRTCLMOD MODULE($(BIN_LIB)/$(notdir $*)) SRCFILE($(BIN_LIB)/QCLLESRC) DBGVIEW($(DBGVIEW))"

%.srvpgm:
	-system -qi "CRTSRCPF FILE($(BIN_LIB)/QSRVSRC) RCDLEN(132)"
	system "CPYFRMSTMF FROMSTMF('headers/$*.binder') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QSRVSRC.file/$*.mbr') MBROPT(*replace)"
	
	# You may be wondering what this ugly string is. It's a list of objects created from the dep list that end with .c or .clle.
	$(eval modules := $(patsubst %,$(BIN_LIB)/%,$(basename $(filter %.c %.clle,$(notdir $^)))))
	
	system -i -kpieb "CRTSRVPGM SRVPGM($(BIN_LIB)/$*) MODULE($(modules)) SRCFILE($(BIN_LIB)/QSRVSRC) ACTGRP(QILE) ALWLIBUPD(*YES) TGTRLS(*current)"

hdr:
	sed "s/ nox_/ json_/g; s/ NOX_/ json_/g" headers/noxDB.rpgle > headers/noxdbJSON.rpgle
	sed "s/ nox_/ xml_/g; s/ NOX_/ xml_/g" headers/noxDB.rpgle > headers/noxdbXML.rpgle

	system -i "CRTSRCPF FILE($(BIN_LIB)/QRPGLEREF) RCDLEN(132)"
	system -i "CRTSRCPF FILE($(BIN_LIB)/QCREF) RCDLEN(132)"
  
	system "CPYFRMSTMF FROMSTMF('headers/noxdbJSON.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/NOXDBJSON.mbr') MBROPT(*REPLACE)"
	system "CPYFRMSTMF FROMSTMF('headers/noxdbXML.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/NOXDBXML.mbr') MBROPT(*REPLACE)"
	system "CPYFRMSTMF FROMSTMF('headers/noxdb.h') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QCREF.file/NOXDB.mbr') MBROPT(*REPLACE)"

all:
	@echo Build success!

clean:
	-system -qi "DLTOBJ OBJ($(BIN_LIB)/*ALL) OBJTYPE(*FILE)"
	-system -qi "DLTOBJ OBJ($(BIN_LIB)/*ALL) OBJTYPE(*MODULE)"

# For vsCode / single file then i.e.: gmake current sqlio.c  
current: 
	system "CRTCMOD MODULE($(BIN_LIB)/$(MOD)) SRCSTMF('$(SRC)') $(CCFLAGS2) "

example: 
	system "CRTBNDRPG PGM($(BIN_LIB)/$(MOD)) SRCSTMF('$(SRC)') DBGVIEW(*ALL)" 