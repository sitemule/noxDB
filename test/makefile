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
CCSID=277

all: compile
.ONESHELL:
compile:
	../examples/compile.sh -f "$(SRC)"  -l $(BIN_LIB) -c $(CCSID) -o "$(RPG_OPT)"

.PHONY: compile