
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
TARGET_RLS=*PRV

# Need this with release 7.3 / 7.4  since /QIBM/include
#DEFINE=QOAR_INCLUDE_IFS


# Do not touch below
INCLUDE='/QIBM/include' 'headers/' 'headers/ext/'

CCFLAGS=OPTIMIZE(10) ENUM(*INT) TERASPACE(*YES) STGMDL(*INHERIT) SYSIFCOPT(*IFSIO) INCDIR($(INCLUDE)) DBGVIEW($(DBGVIEW)) DEFINE($(DEFINE)) TGTCCSID($(TARGET_CCSID)) TGTRLS($(TARGET_RLS))

# For current compile:
CCFLAGS2=OPTION(*STDLOGMSG) OUTPUT(*print) $(CCFLAGS)


#
# User-defined part end
#-----------------------------------------------------------

# Dependency list
# For vsCode / single file then i.e.: gmake current sqlio.c
ifeq "$(suffix $(SRC))" ".c"
current:
	system -i "CRTCMOD MODULE($(BIN_LIB)/$(MODULE)) SRCSTMF('$(SRC)') $(CCFLAGS2) "
	system -i "UPDSRVPGM SRVPGM($(BIN_LIB)/JSONXML) MODULE($(BIN_LIB)/$(MODULE))"
endif

ifeq "$(suffix $(SRC))" ".cpp"
current:
	system "CRTCPPMOD MODULE($(BIN_LIB)/$(MODULE)) SRCSTMF('$(SRC)') $(CCFLAGS2) "
	system "UPDSRVPGM SRVPGM($(BIN_LIB)/JSONXML) MODULE($(BIN_LIB)/$(MODULE))"
endif


all:  $(BIN_LIB).lib link hdr githash jsonxml.srvpgm jsonxml.bnddir

jsonxml.srvpgm: initialize.cpp noxdb.c sqlio.c sqlwrapper.c xmlparser.c xmlserial.c jsonparser.c serializer.c reader.c segments.c iterator.c datagen.c datainto.c http.c generic.c loadpgm.c callproc.c trace.clle githash.c ext/mem001.c ext/parms.c ext/sndpgmmsg.c ext/stream.c ext/timestamp.c ext/trycatch.c ext/utl100.c ext/varchar.c ext/xlate.c ext/rtvsysval.c jsonxml.bnddir noxdb.bnddir

#-----------------------------------------------------------

%.lib:
	-system -q "CRTLIB $* TYPE(*TEST)"

# QOAR are for unknow reasons not in /QIBM/include
link:
	-mkdir -p ./headers/qoar/h
	-ln -s  /QSYS.LIB/QOAR.LIB/H.file/QRNTYPES.MBR ./headers/qoar/h/qrntypes
	-ln -s  /QSYS.LIB/QOAR.LIB/H.file/QRNDTAGEN.MBR ./headers/qoar/h/qrndtagen
	-ln -s  /QSYS.LIB/QOAR.LIB/H.file/QRNDTAINTO.MBR ./headers/qoar/h/qrndtainto

hdr:
	sed "s/ jx_/ json_/g; s/ JX_/ json_/g" headers/JSONXML.rpgle > headers/JSONPARSER.rpgle
	sed "s/ jx_/ xml_/g; s/ JX_/ xml_/g" headers/JSONXML.rpgle > headers/XMLPARSER.rpgle

	cp headers/JSONPARSER.rpgle headers/NOXDB.rpgle
	sed "s/**FREE//g" headers/XMLPARSER.rpgle >> headers/NOXDB.rpgle


	-system -q "CRTSRCPF FILE($(BIN_LIB)/QRPGLEREF) RCDLEN(200)"
	-system -q "CRTSRCPF FILE($(BIN_LIB)/H) RCDLEN(200)"

	system "CPYFRMSTMF FROMSTMF('headers/JSONPARSER.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/JSONPARSER.mbr') MBROPT(*REPLACE)"
	system "CPYFRMSTMF FROMSTMF('headers/XMLPARSER.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/XMLPARSER.mbr') MBROPT(*REPLACE)"
	system "CPYFRMSTMF FROMSTMF('headers/NOXDB.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLEREF.file/NOXDB.mbr') MBROPT(*REPLACE)"
	system "CPYFRMSTMF FROMSTMF('headers/jsonxml.h') TOMBR('/QSYS.lib/$(BIN_LIB).lib/H.file/JSONXML.mbr') MBROPT(*REPLACE)"


# get the git hash and put it into the version file so it becomes part of the copyright notice in the service program
githash:
	-$(eval gitshort := $(shell git rev-parse --short HEAD))
	-$(eval githash := $(shell git rev-parse --verify HEAD))
	-$(eval ts := $(shell date +'%F-%H.%M.%S' ))
	-echo "#pragma comment(copyright,\"System & Method A/S - Sitemule: git checkout $(gitshort) (hash: $(githash) ) build: $(ts)\")" > src/githash.c

%.bnddir:
	@-system -q "DLTBNDDIR BNDDIR($(BIN_LIB)/$*)"
	@system -q "CRTBNDDIR BNDDIR($(BIN_LIB)/$*)"
	@system -q "ADDBNDDIRE BNDDIR($(BIN_LIB)/$*) OBJ((*LIBL/JSONXML *SRVPGM *IMMED))"

%.c:
	@system -q "CHGATR OBJ('src/$*.c') ATR(*CCSID) VALUE(1252)"
	system "CRTCMOD MODULE($(BIN_LIB)/$(notdir $*)) SRCSTMF('src/$*.c') $(CCFLAGS)"

%.cpp:
	@system -q "CHGATR OBJ('src/$*.cpp') ATR(*CCSID) VALUE(1252)"
	system "CRTCPPMOD MODULE($(BIN_LIB)/$(notdir $*)) SRCSTMF('src/$*.cpp') $(CCFLAGS)"

%.clle:
	@system -q "CHGATR OBJ('src/$*.clle') ATR(*CCSID) VALUE(1252)"
	@-system -q "CRTSRCPF FILE($(BIN_LIB)/QCLLESRC) RCDLEN(200)"
	@system -q "CPYFRMSTMF FROMSTMF('src/$*.clle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QCLLESRC.file/$(notdir $*).mbr') MBROPT(*ADD)"
	system "CRTCLMOD MODULE($(BIN_LIB)/$(notdir $*)) SRCFILE($(BIN_LIB)/QCLLESRC) DBGVIEW($(DBGVIEW)) TGTRLS($(TARGET_RLS))"

%.srvpgm:
	@-system -q "CRTSRCPF FILE($(BIN_LIB)/QSRVSRC) RCDLEN(200)"
	@system "CPYFRMSTMF FROMSTMF('headers/$*.binder') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QSRVSRC.file/$*.mbr') MBROPT(*replace)"

	@# You may be wondering what this ugly string is. It's a list of objects created from the dep list that end with .c or .clle.
	@$(eval modules := $(patsubst %,$(BIN_LIB)/%,$(basename $(filter %.c %.cpp %.clle,$(notdir $^)))))

	system -q -kpieb "CRTSRVPGM SRVPGM($(BIN_LIB)/$*) MODULE($(modules)) SRCFILE($(BIN_LIB)/QSRVSRC) ACTGRP(QILE) ALWLIBUPD(*YES) DETAIL(*BASIC) TGTRLS($(TARGET_RLS))"

	@for module in $(modules); do\
		system -q "dltmod $$module" ; \
	done

all:
	@echo Build success!

clean:
	-system -q "DLTOBJ OBJ($(BIN_LIB)/*ALL) OBJTYPE(*MODULE)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/XMLPARS*) OBJTYPE(*PGM)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/JSONPARS*) OBJTYPE(*PGM)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/JXTEST*) 	 OBJTYPE(*PGM)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/JSONSQL*)  OBJTYPE(*PGM)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/HTTPX*)    OBJTYPE(*PGM)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/ISSUE*)    OBJTYPE(*PGM)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/EVFEVENT)  OBJTYPE(*file)"
	-system -q "DLTOBJ OBJ($(BIN_LIB)/RELEASE)   OBJTYPE(*file)"


release: clean
	@echo " -- Creating noxdb release. --"
	@echo " -- Creating save file. --"
	system "CRTSAVF FILE($(BIN_LIB)/RELEASE)"
	system "SAVLIB LIB($(BIN_LIB)) DEV(*SAVF) SAVF($(BIN_LIB)/RELEASE) DTACPR(*HIGH) OMITOBJ((RELEASE *FILE))"
	-mkdir -p release
	-rm ./release/release.savf
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
example:
	system -i "CRTBNDRPG PGM($(BIN_LIB)/$(SRC)) SRCSTMF('examples/$(SRC).rpgle') DBGVIEW(*ALL)" > error.txt

test:
	system -i "CRTBNDRPG PGM($(BIN_LIB)/$(SRC)) SRCSTMF('test/$(SRC).rpgle') DBGVIEW(*ALL)" > error.txt
