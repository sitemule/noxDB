
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
DEPS_LIST=$(BIN_LIB)/RTVSYSVAL $(BIN_LIB)/UTL100 $(BIN_LIB)/VARCHAR $(BIN_LIB)/MEM001 $(BIN_LIB)/XLATE $(BIN_LIB)/STREAM $(BIN_LIB)/TIMESTAMP $(BIN_LIB)/SNDPGMMSG $(BIN_LIB)/TRYCATCH

CCFLAGS=OPTIMIZE(10) ENUM(*INT) TERASPACE(*YES) STGMDL(*INHERIT) SYSIFCOPT(*IFSIO) INCDIR($(INCLUDE)) DBGVIEW($(DBGVIEW)) TGTCCSID($(TARGET_CCSID))

# For current compile:
CCFLAGS2=OPTION(*STDLOGMSG) OUTPUT(*NONE) OPTIMIZE(10) ENUM(*INT) TERASPACE(*YES) STGMDL(*INHERIT) SYSIFCOPT(*IFSIO) DBGVIEW(*ALL) INCDIR($(INCLUDE)) 

#
# User-defined part end
#-----------------------------------------------------------


all: $(BIN_LIB).lib jsonxml.srvpgm hdr

%.lib:
	-system -q "CRTLIB $* TYPE(*TEST)"

jsonxml.srvpgm: noxdb.c sqlio.c xmlparser.c jsonparser.c serializer.c reader.c segments.c iterator.c http.c generic.c runqsh.clle trace.clle ext/mem001.c ext/parms.c ext/sndpgmmsg.c ext/stream.c ext/timestamp.c ext/trycatch.c ext/utl100.c ext/varchar.c ext/xlate.c ext/rtvsysval.c jsonxml.bnddir noxdb.bnddir

jsonxml.bnddir: jsonxml.entry
noxdb.bnddir: jsonxml.entry

%.bnddir:
	-system -q "CRTBNDDIR BNDDIR($(BIN_LIB)/$*)"
	-system -q "ADDBNDDIRE BNDDIR($(BIN_LIB)/$*) OBJ($(patsubst %.entry,($(BIN_LIB)/% *SRVPGM *IMMED),$^))"

%.entry:
	# Basically do nothing..
	@echo "Adding binding entry $*"

%.c:
	system "CHGATR OBJ('src/$*.c') ATR(*CCSID) VALUE(1252)"
	system "CRTCMOD MODULE($(BIN_LIB)/$(notdir $*)) SRCSTMF('src/$*.c') $(CCFLAGS)"

%.clle:
	system "CHGATR OBJ('src/$*.clle') ATR(*CCSID) VALUE(1252)"
	-system -q "CRTSRCPF FILE($(BIN_LIB)/QCLLESRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('src/$*.clle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QCLLESRC.file/$(notdir $*).mbr') MBROPT(*ADD)"
	system "CRTCLMOD MODULE($(BIN_LIB)/$(notdir $*)) SRCFILE($(BIN_LIB)/QCLLESRC) DBGVIEW($(DBGVIEW))"

%.srvpgm:
	-system -q "CRTSRCPF FILE($(BIN_LIB)/QSRVSRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('headers/$*.binder') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QSRVSRC.file/$*.mbr') MBROPT(*replace)"
	system -kpieb "CRTSRVPGM SRVPGM($(BIN_LIB)/$*) MODULE($(BIN_LIB)/JXM* $(DEPS_LIST)) SRCFILE($(BIN_LIB)/QSRVSRC) ACTGRP(QILE) ALWLIBUPD(*YES) TGTRLS(*current)"


hdr:
	sed "s/ jx_/ json_/g; s/ JX_/ json_/g" headers/JSONXML.rpgle > headers/JSONPARSER.rpgle
	sed "s/ jx_/ xml_/g; s/ JX_/ xml_/g" headers/JSONXML.rpgle > headers/XMLPARSER.rpgle

	system "CRTSRCPF FILE($(BIN_LIB)/QRPGLEREF) RCDLEN(112)"
	system "CRTSRCPF FILE($(BIN_LIB)/QCREF) RCDLEN(112)"
  
	system "CPYFRMSTMF FROMSTMF('headers/JSONPARSER.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/JSONPARSER.mbr') MBROPT(*ADD)"
	system "CPYFRMSTMF FROMSTMF('headers/XMLPARSER.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/XMLPARSER.mbr') MBROPT(*ADD)"
	system "CPYFRMSTMF FROMSTMF('headers/jsonxml.h') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QCREF.file/JSONXML.mbr') MBROPT(*ADD)"

all:
	@echo Build success!

clean:
	-system -q "DLTOBJ OBJ($(BIN_LIB)/QCLLESRC) OBJTYPE(*FILE)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/QSRVSRC) OBJTYPE(*FILE)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/QRPGLEREF) OBJTYPE(*FILE)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/QCREF) OBJTYPE(*FILE)"

# For vsCode / single file then i.e.: gmake current sqlio.c  
current: env
	system "CRTCMOD MODULE($(BIN_LIB)/$(SRC)) SRCSTMF('src/$(SRC).c') $(CCFLAGS2) "

# For vsCode / single file then i.e.: gmake current sqlio.c  
example: 
	system "CRTBNDRPG PGM($(BIN_LIB)/$(SRC)) SRCSTMF('examples/$(SRC).rpgle') DBGVIEW(*ALL)" > error.txt