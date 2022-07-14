.ONESHELL:

BIN_LIB=NOXDB2
# NOTE - UTF is not allowed for ILE source (yet) - so convert to WIN-1252
RPG_OPT=DBGVIEW(*LIST) INCDIR('./..' '/prj/noxdb2') OPTION(*NOXREF *NOSHOWCPY *NODEBUGIO *NOUNREF *EVENTF *NOEXT *NOEXPDDS)
FILTER2=| grep '*RNF' | grep -v '*RNF7031' | grep -v '*RNF5409' | sed  "s!*!$(SRC): &!"
FILTER1=> /prj/noxdb2/test/error.txt  
SYSCMD=execlist cmd(\
	'chgjob ccsid(500)' \
	'chgatr obj(''$(SRC)'') atr(*ccsid) value(1252)' \
	'crtbndrpg  pgm($(BIN_LIB)/$(SRC)) srcstmf(''$(SRC)'') $(RPG_OPT)' \
)
OBJ = $(subst .,,$(SRC))

    
all: compile
compile: 
	qsh << EOF 
	liblist -a $(BIN_LIB)
	touch error.txt
	setccsid 1208 error.txt
	system -iq "chgatr obj('$(SRC)') atr(*ccsid) value(1252)"
	system -i "crtbndrpg  pgm($(BIN_LIB)/$(OBJ)) srcstmf('$(SRC)') $(RPG_OPT)"  
	EOF
##system -i "$(SYSCMD)" $(FILTER1)
       
.PHONY: compile