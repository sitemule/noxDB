.ONESHELL:

BIN_LIB=NOXDB2
# NOTE - UTF is not allowed for ILE source (yet) - so convert to WIN-1252
RPG_OPT=DBGVIEW(*LIST) INCDIR(''./..'' ''/prj/noxdb'')
FILTER2=| grep '*RNF' | grep -v '*RNF7031' | grep -v '*RNF5409' | sed  "s!*!$(SRC): &!"
FILTER1=> /prj/noxdbutf8/examples/error.txt  
SYSCMD=execlist cmd(\
	'chgjob ccsid(500)' \
	'chgatr obj(''$(SRC)'') atr(*ccsid) value(1252)' \
	'crtbndrpg  pgm($(BIN_LIB)/$(MOD)) srcstmf(''$(SRC)'') $(RPG_OPT)' \
)
    
all: compile
compile: 
	qsh << EOF 
	liblist -a $(BIN_LIB)
	system -i "$(SYSCMD)" $(FILTER1)
	EOF
       
.PHONY: compile