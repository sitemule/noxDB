.ONESHELL:

BIN_LIB=NOXDBUTF8
PRJ_ROOT=./examples
# NOTE - UTF is not allowed for ILE source (yet) - so convert to WIN-1252
RPG_OPT=DBGVIEW(*LIST) INCDIR('./..' '/prj/NOXDBUTF8') OPTION(*NOXREF *NOSHOWCPY *NODEBUGIO *NOUNREF *EVENTF *NOEXT *NOEXPDDS)
FILTER2=| grep '*RNF' | grep -v '*RNF7031' | grep -v '*RNF5409' | sed  "s!*!$(SRC): &!"
FILTER1=> /prj/NOXDBUTF8/examples/error.txt  

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
	system "chgatr obj('$(SRC)') atr(*ccsid) value(1252)"
	-system "crtsrcpf $(BIN_LIB)/qtmpsrc rcdlen(240) CCSID(500)"
	system "CPYFRMSTMF FROMSTMF('$(SRC)') TOMBR('/QSYS.LIB/$(BIN_LIB).LIB/qtmpsrc.FILE/$(OBJ).mbr') MBROPT(*REPLACE)"
	system "crtbndrpg  pgm($(BIN_LIB)/$(OBJ)) srcfile($(BIN_LIB)/qtmpsrc) $(RPG_OPT)"  $(FILTER1)
	../tools/formaterr.sh /QSYS.LIB/NOXDBUTF8.LIB/EVFEVENT.FILE/$(OBJ).mbr $(PRJ_ROOT)/$(SRC)
	EOF
##system -i "$(SYSCMD)" $(FILTER1)

#compile: 
#	qsh << EOF 
#	liblist -a $(BIN_LIB)
#	system "chgatr obj('$(SRC)') atr(*ccsid) value(1252)"
#	system "crtbndrpg  pgm($(BIN_LIB)/$(OBJ)) srcstmf('$(SRC)') $(RPG_OPT)"
#	EOF
#
.PHONY: compile