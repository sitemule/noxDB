
#-----------------------------------------------------------
# User-defined part start
#

# BIN_LIB is the destination library for the service program.
# the rpg modules and the binder source file are also created in BIN_LIB.
# binder source file and rpg module can be remove with the clean step (make clean)
BIN_LIB=NOXDB
DBGVIEW=*ALL

# Do not touch below
INCLUDE='/QIBM/include' 'headers/' 'headers/ext/'
DEPS_LIST=$(BIN_LIB)/RTVSYSVAL $(BIN_LIB)/UTL100 $(BIN_LIB)/VARCHAR $(BIN_LIB)/MEM001 $(BIN_LIB)/XLATE $(BIN_LIB)/STREAM $(BIN_LIB)/TIMESTAMP $(BIN_LIB)/SNDPGMMSG $(BIN_LIB)/TRYCATCH

CCFLAGS=OPTIMIZE(10) ENUM(*INT) TERASPACE(*YES) STGMDL(*INHERIT) SYSIFCOPT(*IFSIO) INCDIR($(INCLUDE)) DBGVIEW($(DBGVIEW))

#
# User-defined part end
#-----------------------------------------------------------

all: clean env compile ext bind

env:
	-system -q "CRTLIB $(BIN_LIB) TYPE(*TEST) TEXT('Nox.DB build library')
	-system -q "CRTBNDDIR BNDDIR($(BIN_LIB)/JSONXML)"
	-system -q "ADDBNDDIRE BNDDIR($(BIN_LIB)/JSONXML) OBJ((JSONXML))"


compile:
	system "CRTCMOD MODULE($(BIN_LIB)/JXM001) SRCSTMF('src/JXM001.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JXM002) SRCSTMF('src/JXM002.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JXM003) SRCSTMF('src/JXM003.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JXM004) SRCSTMF('src/JXM004.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JXM005) SRCSTMF('src/JXM005.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JXM006) SRCSTMF('src/JXM006.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JXM007) SRCSTMF('src/JXM007.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JXM008) SRCSTMF('src/JXM008.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JXM010) SRCSTMF('src/JXM010.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JXM900) SRCSTMF('src/JXM900.c') $(CCFLAGS)"

	system "CRTSRCPF FILE($(BIN_LIB)/QCLLESRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('src/JXM901.clle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QCLLESRC.file/JXM901.mbr') MBROPT(*ADD)"
	system "CPYFRMSTMF FROMSTMF('src/JXM902.clle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QCLLESRC.file/JXM902.mbr') MBROPT(*ADD)"
	system -s "CRTCLMOD MODULE($(BIN_LIB)/JXM901) SRCFILE($(BIN_LIB)/QCLLESRC) DBGVIEW($(DBGVIEW))"
	system -s "CRTCLMOD MODULE($(BIN_LIB)/JXM902) SRCFILE($(BIN_LIB)/QCLLESRC) DBGVIEW($(DBGVIEW))"
	

ext:
	system "CRTCMOD MODULE($(BIN_LIB)/MEM001) SRCSTMF('src/ext/mem001.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/PARMS) SRCSTMF('src/ext/parms.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/SNDPGMMSG) SRCSTMF('src/ext/sndpgmmsg.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/STREAM) SRCSTMF('src/ext/stream.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/TIMESTAMP) SRCSTMF('src/ext/timestamp.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/TRYCATCH) SRCSTMF('src/ext/trycatch.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/UTL100) SRCSTMF('src/ext/utl100.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/VARCHAR) SRCSTMF('src/ext/varchar.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/XLATE) SRCSTMF('src/ext/xlate.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/RTVSYSVAL) SRCSTMF('src/ext/rtvsysval.c') $(CCFLAGS)"

bind:
	system "CRTSRCPF FILE($(BIN_LIB)/QSRVSRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('headers/JSONXML.binder') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QSRVSRC.file/JSONXML.mbr') MBROPT(*ADD)"
	system -kpieb "CRTSRVPGM SRVPGM($(BIN_LIB)/JSONXML) MODULE($(BIN_LIB)/JXM* $(DEPS_LIST)) SRCFILE($(BIN_LIB)/QSRVSRC) ACTGRP(QILE) ALWLIBUPD(*YES) TGTRLS(*current)"
	
clean:
	-system -q "DLTOBJ OBJ($(BIN_LIB)/QCLLESRC) OBJTYPE(*FILE)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/QSRVSRC) OBJTYPE(*FILE)"
