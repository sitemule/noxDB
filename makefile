
#-----------------------------------------------------------
# User-defined part start
#

# BIN_LIB is the destination library for the service program.
# the rpg modules and the binder source file are also created in BIN_LIB.
# binder source file and rpg module can be remove with the clean step (make clean)
BIN_LIB=NOXDB

# to this folder the header files (prototypes) are copied in the install step
INCLUDE=/QIBM/include:headers/

DBGVIEW=*ALL

# CCFLAGS = C compiler parameter
##CCFLAGS=OPTION(*EXPMAC *SHOWINC) OUTPUT(*PRINT *NOSHOWSRC) OPTIMIZE(10) ENUM(*INT) TERASPACE(*YES) STGMDL(*INHERIT) DEFINE(NOCRYPT USE_STANDARD_TMPFILE USE_BIG_ENDIAN LXW_HAS_SNPRINTF) SYSIFCOPT(*IFS64IO) INCDIR('/QIBM/include' '../include' '$(ZLIB_INC)' '../third_party/minizip')
##CCFLAGS=OUTPUT(*PRINT *NOSHOWSRC) OPTIMIZE(10) ENUM(*INT) TERASPACE(*YES) STGMDL(*INHERIT) SYSIFCOPT(*IFSIO) INCDIR('$(INCLUDE)')
CCFLAGS=OPTIMIZE(10) ENUM(*INT) TERASPACE(*YES) STGMDL(*INHERIT) SYSIFCOPT(*IFSIO) INCDIR('$(INCLUDE)') DBGVIEW($(DBGVIEW))

#
# User-defined part end
#-----------------------------------------------------------
							 
all: env compile bind 

env:
	-system -q "CRTLIB $(BIN_LIB) TYPE(*TEST) TEXT('Nox.DB build library')																					
	-system -q "CRTBNDDIR BNDDIR($(BIN_LIB)/JSONXML)"
	-system -q "ADDBNDDIRE BNDDIR($(BIN_LIB)/JSONXML) OBJ((JSONXML))"


compile: 
	system "CRTCMOD MODULE($(BIN_LIB)/JMX001) SRCSTMF('src/JMX001.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JMX002) SRCSTMF('src/JMX002.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JMX003) SRCSTMF('src/JMX003.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JMX004) SRCSTMF('src/JMX004.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JMX005) SRCSTMF('src/JMX005.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JMX006) SRCSTMF('src/JMX006.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JMX007) SRCSTMF('src/JMX007.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JMX008) SRCSTMF('src/JMX008.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JMX010) SRCSTMF('src/JMX010.c') $(CCFLAGS)"
	system "CRTCMOD MODULE($(BIN_LIB)/JMX900) SRCSTMF('src/JMX900.c') $(CCFLAGS)"

	system "CRTSRCPF FILE($(BIN_LIB)/QCLLESRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('src/JMX901.clle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QCCLESRC.file/JXM901.mbr') MBROPT(*ADD)"
	system "CPYFRMSTMF FROMSTMF('src/JMX902.clle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QCCLESRC.file/JXM902.mbr') MBROPT(*ADD)"
	system "CRTBNDCL PGM($(BIN_LIB)/JXM901) SRCFILE($(BIN_LIB)/QCLLESRC) DBGVIEW($(DBGVIEW))"
	system "CRTBNDCL PGM($(BIN_LIB)/JMX902) SRCFILE($(BIN_LIB)/QCLLESRC) DBGVIEW($(DBGVIEW))"

bind: 
	system "CRTSRCPF FILE($(BIN_LIB)/QSRVSRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('headers/JSONXML.binder') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QSRVSRC.file/JSONXML.mbr') MBROPT(*ADD)"
	system -kpieb "CRTSRVPGM SRVPGM(JSONXML/JSONXML) MODULE(JXM* RTVSYSVAL UTL100 VARCHAR MEM001 XLATE STREAM TIMESTAMP SNDPGMMSG TRYCATCH) SRCMBR(JSONXML) ACTGRP(QILE) ALWLIBUPD(*YES) TGTRLS(*current)"
 