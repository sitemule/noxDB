# NOTE - UTF-8 is not allowed for ILE source on 7.2 unsing stream files
# This makefile is made for 7.2 since ccsid conversion from 1208 causes issues 
#
# Note TGTCCSID is only supported from 7.4 > so the examples will run in ccsid 500
# i.e. you have to do a 
#    CHGJOB CCSID(500)
# Before your examples will run.
# If you are on 7.4 change the compile option to:
#
#    RPG_OPT=DBGVIEW(*LIST) INCDIR('./..' '/prj/noxdb') PPGENOPT(*EXPINCLUDE) TGTCCSID(277)
# 
BIN_LIB=NOXDB
RPG_OPT=DBGVIEW(*LIST) INCDIR('./..' '/prj/noxdb')  OPTION(*NOSHOWCPY *NODEBUGIO *NOUNREF *EVENTF *NOEXT *NOEXPDDS)
OBJNAME=$(word 1, $(subst ., ,$(OBJ)))  
CCSID=277  

all: compile
.ONESHELL:
compile: 
	qsh <<EOF 
	liblist -a $(BIN_LIB)
	liblist -a ICEBREAK
	touch error.txt
	setccsid 1208 error.txt
	setccsid 1208 $(SRC)
	system -iq "CRTSRCPF $(BIN_LIB)/srctemp RCDLEN(240) CCSID($(CCSID))"
	system -iq "CPYFRMSTMF FROMSTMF('$(SRC)') TOMBR('/QSYS.LIB/$(BIN_LIB).LIB/srctemp.file/srctemp.mbr')  MBROPT(*REPLACE)"
	system -i "CRTBNDRPG  PGM($(BIN_LIB)/$(OBJNAME)) SRCFILE($(BIN_LIB)/srctemp) SRCMBR(SRCTEMP) $(RPG_OPT)" > error.txt
	system -iq "DLTF $(BIN_LIB)/srctemp"
	EOF
       
.PHONY: compile