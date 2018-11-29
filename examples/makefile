BIN_LIB=NOXDB2
# NOTE - UTF is not allowed for ILE source (yet) - so convert to WIN-1252
SHELL=/QOpenSys/usr/bin/sh
RPG_OPT=DBGVIEW(*LIST) INCDIR('./..' '/prj/noxdb')
FILTER1=| grep '*RNF' | grep -v '*RNF7031' | grep -v '*RNF5409' | sed  "s!*!$(SRC): &!"
FILTER=> /prj/noxdbutf8/examples/error.txt  
    
all: compile
.ONESHELL:
compile: 
	qsh <<EOF 
	export QIBM_CCSID=500
	liblist -a $(BIN_LIB)
	system "CHGATR OBJ('$(SRC)') ATR(*CCSID) VALUE(1252)"
	system "CHGJOB ccsid(500)"
	system -i "CRTBNDRPG  PGM($(BIN_LIB)/$(MOD)) SRCSTMF('$(SRC)') $(RPG_OPT)" $(FILTER) 
	EOF
       
.PHONY: compile