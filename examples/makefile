BIN_LIB=NOXDB
# NOTE - UTF is not allowed for ILE source (yet) - so convert to WIN-1252

# Note TGTCCSID is only supported from 7.4 > so the examples will run in ccsid 500
# i.e. you have to do a 
#    CHGJOB CCSID(500)
# Before your examples will run.
# If you are on 7.4 change the compile option to:
#
#    RPG_OPT=DBGVIEW(*LIST) INCDIR('./..' '/prj/noxdb') PPGENOPT(*EXPINCLUDE) TGTCCSID(277)

RPG_OPT=DBGVIEW(*LIST) INCDIR('./..' '/prj/noxdb') 
    
all: compile
.ONESHELL:
compile: 
	qsh <<EOF 
	export QIBM_CCSID=277
	liblist -a $(BIN_LIB)
	touch error.txt
	setccsid 1252 error.txt
	setccsid 1252 $(SRC)
	system -i "CRTBNDRPG  PGM($(BIN_LIB)/$(word 1, $(subst ., ,$(OBJ)))) SRCSTMF('$(SRC)') $(RPG_OPT)" > error.txt
	EOF
       
.PHONY: compile