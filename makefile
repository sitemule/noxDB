
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

all: clean $(BIN_LIB).lib jsonxml.srvpgm hdr

jsonxml.srvpgm: noxdb.c sqlio.c xmlparser.c jsonparser.c serializer.c reader.c segments.c iterator.c http.c generic.c runqsh.clle trace.clle ext/mem001.c ext/parms.c ext/sndpgmmsg.c ext/stream.c ext/timestamp.c ext/trycatch.c ext/utl100.c ext/varchar.c ext/xlate.c ext/rtvsysval.c jsonxml.bnddir noxdb.bnddir

jsonxml.bnddir: jsonxml.entry
noxdb.bnddir: jsonxml.entry

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
	system -i "CHGATR OBJ('src/$*.c') ATR(*CCSID) VALUE(1252)"
	system "CRTCMOD MODULE($(BIN_LIB)/$(notdir $*)) SRCSTMF('src/$*.c') $(CCFLAGS)"

%.clle:
	system -i "CHGATR OBJ('src/$*.clle') ATR(*CCSID) VALUE(1252)"
	-system -qi "CRTSRCPF FILE($(BIN_LIB)/QCLLESRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('src/$*.clle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QCLLESRC.file/$(notdir $*).mbr') MBROPT(*ADD)"
	system "CRTCLMOD MODULE($(BIN_LIB)/$(notdir $*)) SRCFILE($(BIN_LIB)/QCLLESRC) DBGVIEW($(DBGVIEW))"

%.srvpgm:
	-system -qi "CRTSRCPF FILE($(BIN_LIB)/QSRVSRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('headers/$*.binder') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QSRVSRC.file/$*.mbr') MBROPT(*replace)"
	
	# You may be wondering what this ugly string is. It's a list of objects created from the dep list that end with .c or .clle.
	$(eval modules := $(patsubst %,$(BIN_LIB)/%,$(basename $(filter %.c %.clle,$(notdir $^)))))
	
	system -i -kpieb "CRTSRVPGM SRVPGM($(BIN_LIB)/$*) MODULE($(modules)) SRCFILE($(BIN_LIB)/QSRVSRC) ACTGRP(QILE) ALWLIBUPD(*YES) TGTRLS(*current)"

hdr:
	sed "s/ jx_/ json_/g; s/ JX_/ json_/g" headers/JSONXML.rpgle > headers/JSONPARSER.rpgle
	sed "s/ jx_/ xml_/g; s/ JX_/ xml_/g" headers/JSONXML.rpgle > headers/XMLPARSER.rpgle

	system -i "CRTSRCPF FILE($(BIN_LIB)/QRPGLEREF) RCDLEN(112)"
	system -i "CRTSRCPF FILE($(BIN_LIB)/QCREF) RCDLEN(112)"
  
	system "CPYFRMSTMF FROMSTMF('headers/JSONPARSER.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/JSONPARSER.mbr') MBROPT(*REPLACE)"
	system "CPYFRMSTMF FROMSTMF('headers/XMLPARSER.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/XMLPARSER.mbr') MBROPT(*REPLACE)"
	system "CPYFRMSTMF FROMSTMF('headers/jsonxml.h') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QCREF.file/JSONXML.mbr') MBROPT(*REPLACE)"

all:
	@echo Build success!

clean:
	-system -qi "DLTOBJ OBJ($(BIN_LIB)/*ALL) OBJTYPE(*FILE)"
	-system -qi "DLTOBJ OBJ($(BIN_LIB)/*ALL) OBJTYPE(*MODULE)"

# For vsCode / single file then i.e.: gmake current sqlio.c  
current: 
	system -i "CRTCMOD MODULE($(BIN_LIB)/$(SRC)) SRCSTMF('src/$(SRC).c') $(CCFLAGS2) "

# For vsCode / single file then i.e.: gmake current sqlio.c  
example: 
	system -i "CRTBNDRPG PGM($(BIN_LIB)/$(SRC)) SRCSTMF('examples/$(SRC).rpgle') DBGVIEW(*ALL)" > error.txt
