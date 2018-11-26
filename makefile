
#-----------------------------------------------------------
# User-defined part start
#
# NOTE - UTF is only alowed for C 

# The shell we use
XXSHELL=/QOpenSys/usr/bin/qsh

# BIN_LIB is the destination library for the service program.
# the rpg modules and the binder source file are also created in BIN_LIB.
# binder source file and rpg module can be remove with the clean step (make clean)
BIN_LIB=NOXDB
DBGVIEW=*ALL
TARGET_CCSID=*JOB

# Do not touch below
INCLUDE='/QIBM/include' './headers/' './headers/ext/'

CCFLAGS=OPTIMIZE(10) ENUM(*INT) TERASPACE(*YES) STGMDL(*INHERIT) SYSIFCOPT(*IFSIO) INCDIR($(INCLUDE)) DBGVIEW($(DBGVIEW)) TGTCCSID($(TARGET_CCSID))

# For current compile:
CCFLAGS2=OPTION(*STDLOGMSG) OUTPUT(*NONE) OPTIMIZE(10) ENUM(*INT) TERASPACE(*YES) STGMDL(*INHERIT) SYSIFCOPT(*IFSIO) DBGVIEW(*ALL) INCDIR($(INCLUDE)) 
MODS=$(BIN_LIB)/NOXDB $(BIN_LIB)/SQLIO $(BIN_LIB)/XMLPARSER $(BIN_LIB)/JSONPARSER $(BIN_LIB)/SERIALIZER $(BIN_LIB)/READER $(BIN_LIB)/ITERATOR $(BIN_LIB)/HTTP $(BIN_LIB)/CSV $(BIN_LIB)/GENERIC
DEPS_LIST=$(BIN_LIB)/MEMUTIL $(BIN_LIB)/PARMS $(BIN_LIB)/SNDPGMMSG $(BIN_LIB)/STREAM $(BIN_LIB)/TIMESTAMP $(BIN_LIB)/TRYCATCH $(BIN_LIB)/STRUTIL $(BIN_LIB)/VARCHAR $(BIN_LIB)/XLATE $(BIN_LIB)/E2AA2E $(BIN_LIB)/RUNQSH $(BIN_LIB)/TRACE

#
# User-defined part end
#-----------------------------------------------------------

all: clean env compile ext bind hdr

env:
	-system -q "CRTLIB $(BIN_LIB) TYPE(*TEST) TEXT('Nox.DB build library')"
	-system -q "CRTBNDDIR BNDDIR($(BIN_LIB)/NOXDB)"
	-system -q "ADDBNDDIRE BNDDIR($(BIN_LIB)/NOXDB) OBJ((NOXDB))"
	-system -q "CRTBNDDIR BNDDIR($(BIN_LIB)/NOXDB)"
	-system -q "ADDBNDDIRE BNDDIR($(BIN_LIB)/NOXDB) OBJ((NOXDB))"


compile:
	system "CHGATR OBJ('src/*') ATR(*CCSID) VALUE(1208)"
	system "CHGATR OBJ('src/ext/*') ATR(*CCSID) VALUE(1208)"
	system "CHGATR OBJ('headers/*') ATR(*CCSID) VALUE(1208)"
	system "CHGATR OBJ('headers/ext/*') ATR(*CCSID) VALUE(1208)"
	system "CRTCMOD MODULE($(BIN_LIB)/NOXDB) SRCSTMF('src/noxdb.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/SQLIO) SRCSTMF('src/sqlio.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/XMLPARSER) SRCSTMF('src/xmlparser.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JSONPARSER) SRCSTMF('src/jsonparser.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/SERIALIZER) SRCSTMF('src/serializer.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/READER) SRCSTMF('src/reader.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/ITERATOR) SRCSTMF('src/iterator.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/HTTP) SRCSTMF('src/http.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/CSV) SRCSTMF('src/csv.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/GENERIC) SRCSTMF('src/generic.c') $(CCFLAGS)"

	system "CRTSRCPF FILE($(BIN_LIB)/QCLLESRC) RCDLEN(132)"
	system "CPYFRMSTMF FROMSTMF('src/runqsh.clle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QCLLESRC.file/RUNQSH.mbr') MBROPT(*ADD)"
	system "CPYFRMSTMF FROMSTMF('src/trace.clle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QCLLESRC.file/TRACE.mbr') MBROPT(*ADD)"
	system -s "CRTCLMOD MODULE($(BIN_LIB)/RUNQSH) SRCFILE($(BIN_LIB)/QCLLESRC) DBGVIEW($(DBGVIEW))"
	system -s "CRTCLMOD MODULE($(BIN_LIB)/TRACE) SRCFILE($(BIN_LIB)/QCLLESRC) DBGVIEW($(DBGVIEW))"
	

ext:
	system "CRTCMOD MODULE($(BIN_LIB)/MEMUTIL) SRCSTMF('src/ext/memUtil.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/PARMS) SRCSTMF('src/ext/parms.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/SNDPGMMSG) SRCSTMF('src/ext/sndpgmmsg.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/STREAM) SRCSTMF('src/ext/stream.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/TIMESTAMP) SRCSTMF('src/ext/timestamp.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/TRYCATCH) SRCSTMF('src/ext/trycatch.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/STRUTIL) SRCSTMF('src/ext/strUtil.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/VARCHAR) SRCSTMF('src/ext/varchar.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/XLATE) SRCSTMF('src/ext/xlate.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/E2AA2E) SRCSTMF('src/ext/e2aa2e.c') $(CCFLAGS)"
	#system "CRTCMOD MODULE($(BIN_LIB)/RTVSYSVAL) SRCSTMF('src/ext/rtvsysval.c') $(CCFLAGS)"

bind:
	-system -q "CRTSRCPF FILE($(BIN_LIB)/QSRVSRC) RCDLEN(132)"
	system "CPYFRMSTMF FROMSTMF('headers/NOXDB.binder') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QSRVSRC.file/NOXDB.mbr') MBROPT(*replace)"
	system -kpieb "CRTSRVPGM SRVPGM($(BIN_LIB)/NOXDB) MODULE($(MODS) $(DEPS_LIST)) SRCFILE($(BIN_LIB)/QSRVSRC) OPTION(*GEN) ACTGRP(QILE) ALWLIBUPD(*YES) TGTRLS(*current)"

hdr:
	sed "s/ nox_/ json_/g; s/ NOX_/ json_/g" headers/NOXDB.rpgle > headers/JSONPARSER.rpgle
	sed "s/ nox_/ xml_/g; s/ NOX_/ xml_/g" headers/NOXDB.rpgle > headers/XMLPARSER.rpgle

	system "CRTSRCPF FILE($(BIN_LIB)/QRPGLEREF) RCDLEN(132)"
	system "CRTSRCPF FILE($(BIN_LIB)/QCREF) RCDLEN(132)"
  
	system "CPYFRMSTMF FROMSTMF('headers/JSONPARSER.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/JSONPARSER.mbr') MBROPT(*ADD)"
	system "CPYFRMSTMF FROMSTMF('headers/XMLPARSER.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/XMLPARSER.mbr') MBROPT(*ADD)"
	system "CPYFRMSTMF FROMSTMF('headers/noxdb.h') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QCREF.file/NOXDB.mbr') MBROPT(*ADD)"

clean:
	-system -q "DLTOBJ OBJ($(BIN_LIB)/QCLLESRC) OBJTYPE(*FILE)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/QSRVSRC) OBJTYPE(*FILE)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/QRPGLEREF) OBJTYPE(*FILE)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/QCREF) OBJTYPE(*FILE)"

# For vsCode / single file then i.e.: gmake current sqlio.c  
current: 
	system "CRTCMOD MODULE($(BIN_LIB)/$(MOD)) SRCSTMF('$(SRC)') $(CCFLAGS2) "


example: 
	system "CRTBNDRPG PGM($(BIN_LIB)/$(MOD)) SRCSTMF('$(SRC)') DBGVIEW(*ALL)" 

	
