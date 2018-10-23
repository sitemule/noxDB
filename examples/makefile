BIN_LIB=NOXDB
# NOTE - UTF is not allowed for ILE source (yet) - so convert to WIN-1252

# to this folder the header files (prototypes) are copied in the install step
#	system -i "CRTBNDRPG  PGM($(BIN_LIB)/demo01) SRCSTMF('demo01.rpgle') $(RPG_OPT)" 
#	system -i "CRTBNDRPG  PGM($(BIN_LIB)/demo02) SRCSTMF('demo02.rpgle') $(RPG_OPT)" 
RPG_OPT=DBGVIEW(*LIST) INCDIR('./..' '/prj/noxdb')
    
all: compile
.ONESHELL:
compile: 
	qsh <<EOF 
	export QIBM_CCSID=277
	liblist -a $(BIN_LIB)
	system "CHGATR OBJ('$(SRC)') ATR(*CCSID) VALUE(1252)"
	system -i "CRTBNDRPG  PGM($(BIN_LIB)/$(OBJ)) SRCSTMF('$(SRC)') $(RPG_OPT)" > error.txt
	EOF
       
.PHONY: compile