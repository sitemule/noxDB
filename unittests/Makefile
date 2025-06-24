#
# Build script for noxDB unit tests
#


#-------------------------------------------------------------------------------
# User-defined part start
#

# BIN_LIB is the destination library for the unit tests.
BIN_LIB=NOXDB

# This folder contains the ASSERT copybook of the unit testing framework.
RUINCDIR=/usr/local/include/irpgunit

# Library which contains RUTESTCASE service program
RU_LIB=*LIBL

# This library contains the ILEASTIC modules.
NOXDB_LIB=NOXDB

#TARGET_CCSID=*JOB

#
# User-defined part end
#-------------------------------------------------------------------------------


OBJECTS = noxdbut1 noxdbut2 noxdbut3
SRVPGMS = $(RU_LIB)/RUTESTCASE $(NOXDB_LIB)/JSONXML

all: clean compile

compile: $(OBJECTS)

noxdbut1:
	system -i "CHGATR OBJ('noxdbut1.rpgle') ATR(*CCSID) VALUE(1252)"
	system -i "CRTRPGMOD MODULE($(BIN_LIB)/noxdbut1) SRCSTMF('noxdbut1.rpgle') INCDIR('$(RUINCDIR)') DBGVIEW(*source) STGMDL(*SNGLVL)"
	system -i "CRTSRVPGM $(BIN_LIB)/noxdbut1 MODULE(($(BIN_LIB)/noxdbut1)) STGMDL(*SNGLVL) BNDSRVPGM($(SRVPGMS)) EXPORT(*ALL) OPTION(*DUPPROC)"

noxdbut2:
	system -i "CHGATR OBJ('noxdbut2.rpgle') ATR(*CCSID) VALUE(1252)"
	system -i "CRTRPGMOD MODULE($(BIN_LIB)/noxdbut2) SRCSTMF('noxdbut2.rpgle') INCDIR('$(RUINCDIR)') DBGVIEW(*source) STGMDL(*SNGLVL)"
	system -i "CRTSRVPGM $(BIN_LIB)/noxdbut2 MODULE(($(BIN_LIB)/noxdbut2)) STGMDL(*SNGLVL) BNDSRVPGM($(SRVPGMS)) EXPORT(*ALL) OPTION(*DUPPROC)"

noxdbut3:
	system -i "CHGATR OBJ('noxdbut3.rpgle') ATR(*CCSID) VALUE(1252)"
	system -i "CRTRPGMOD MODULE($(BIN_LIB)/noxdbut3) SRCSTMF('noxdbut3.rpgle') INCDIR('$(RUINCDIR)') DBGVIEW(*source) STGMDL(*SNGLVL)"
	system -i "CRTSRVPGM $(BIN_LIB)/noxdbut3 MODULE(($(BIN_LIB)/noxdbut3)) STGMDL(*SNGLVL) BNDSRVPGM($(SRVPGMS)) EXPORT(*ALL) OPTION(*DUPPROC)"

clean:
	-system -i "DLTMOD $(BIN_LIB)/noxdbut1"
	-system -i "DLTSRVPGM $(BIN_LIB)/noxdbut1"
	-system -i "DLTMOD $(BIN_LIB)/noxdbut2"
	-system -i "DLTSRVPGM $(BIN_LIB)/noxdbut2"
	-system -i "DLTMOD $(BIN_LIB)/noxdbut3"
	-system -i "DLTSRVPGM $(BIN_LIB)/noxdbut3"
