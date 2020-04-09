#!/QOpenSys/usr/bin/python

#cd /prj/capdev
#python compile.py --stmf=/prj/icecap/src/hello.c --lib=CAPDEV --obj=HELLO
import argparse, sys, os, subprocess, re

# ------------------------------------------------------------------------
# Build scripts
# Note: Compilers procuces an eventfile, so that option is always used
# Add your own ...
# ------------------------------------------------------------------------
def build_cmod(stmf , cmd ,lib , liblist , obj , flags , include):
	flags = flags + " OPTION(*EVENTF) OUTPUT(*PRINT)"
	shell =  oscmd("liblist -a " + liblist )
	shell += oscmd("setccsid 1252 " + stmf)
	cmd =  (cmd if cmd > ""  else "CRTBNDC")
	if cmd == "CRTBNDC":
		shell += syscmdlist(cmd + " SRCSTMF('" + stmf + "') PGM(" + lib + "/" + obj + ") " + flags + " INCDIR(" + include + ")")
	else:
		shell += syscmdlist( cmd + " SRCSTMF('" + stmf + "') MODULE(" + lib + "/" + obj + ") " + flags + " INCDIR(" + include + ")")
	runscriptAndShowEventfile (stmf, shell, lib , obj)


def build_rpgmod (stmf , cmd ,lib , liblist , obj , flags , include):
	flags = flags + " OPTION(*NOUNREF *EVENTF)"
	shell =  oscmd("liblist -a " + liblist)
	shell += oscmd("setccsid 1252 " + stmf)
	cmd =  (cmd if cmd > ""  else "CRTBNDRPG")
	if cmd == "CRTBNDRPG":
		shell += syscmdlist ( cmd + " SRCSTMF('" + stmf + "') PGM(" + lib + "/" + obj + ") " + flags + " INCDIR(" + include + ")")
	else:
		shell += syscmdlist ( cmd + " SRCSTMF('" + stmf + "') MODULE(" + lib + "/" + obj + ") " + flags + " INCDIR(" + include + ")")
	runscriptAndShowEventfile (stmf, shell, lib , obj)

def build_sqlrpgmod (stmf , cmd ,lib , liblist , obj , flags , include):
	flags = flags + " OPTION(*EVENTF)"
	shell =  oscmd("liblist -a " + liblist)
	shell += oscmd("setccsid 1252 " + stmf)
	shell += syscmdlist ( "CRTSQLRPGI SRCSTMF('" + stmf + "') OBJ(" + lib + "/" + obj + ") " + flags + " INCDIR(" + include + ")")
	runscriptAndShowEventfile (stmf, shell, lib , obj)

def build_clmod (stmf , cmd ,lib , liblist , obj , flags , include):
	flags = flags + " OPTION(*EVENTF)"
	shell = oscmd("liblist -a " + liblist )
	shell +=  oscmd("setccsid 1252 " + stmf)
	shell += syscmd("CRTSRCPF FILE(" + lib + "/QCLLESRC) RCDLEN(112)")
	shell += syscmd("CPYFRMSTMF FROMSTMF('" + stmf + "') TOMBR('/QSYS.lib/" + lib + ".lib/QCLLESRC.file/" + obj + ".mbr') MBROPT(*replace)")

	cmd =  (cmd if cmd > ""  else "CRTBNDCL")
	if cmd == "CRTBNDCL":
		shell += syscmdlist ( cmd + " SRCFILE(" + lib + "/QCLLESRC) PGM(" + lib + "/" + obj + ") " + flags + " INCFILE(" + include + ")")
	else:
		shell += syscmdlist (  cmd + " SRCFILE(" + lib + "/QCLLESRC) MODULE(" + lib + "/" + obj + ") " + flags + " INCFILE(" + include + ")")

	runscriptAndShowEventfile (stmf, shell, lib , obj)

def build_srvpgm (stmf , cmd ,lib , liblist , obj , flags , include):
	shell = oscmd("liblist -a " + liblist )
	shell += syscmd("CHGATR OBJ('" + stmf + "') ATR(*CCSID) VALUE(1252)")
	shell += syscmd("CRTSRCPF FILE(" + lib + "/QSRVSRC) RCDLEN(132)")
	shell += syscmd("CPYFRMSTMF FROMSTMF('" + stmf + "') TOMBR('/QSYS.lib/"+ lib + ".lib/QSRVSRC.file/" + obj + ".mbr') MBROPT(*REPLACE)")
	shell += syscmd("CRTSRVPGM  SRVPGM(" + lib + "/" + obj + ") " + flags)
	runscriptAndShowOutput (stmf, shell)

def build_cmd (stmf , cmd ,lib , liblist , obj , flags , include):
	shell = oscmd("liblist -a " + liblist )
	shell +=  oscmd("setccsid 1252 " + stmf)
	shell += syscmd("CRTSRCPF FILE(" + lib + "/QCMDSRC) RCDLEN(132)")
	shell += syscmd("CPYFRMSTMF FROMSTMF('" + stmf + "') TOMBR('/QSYS.lib/"+ lib + ".lib/QCMDSRC.file/" + obj + ".mbr') MBROPT(*REPLACE)")
	shell += syscmdlist("CRTCMD cmd(" + lib + "/" + obj + ") SRCFILE(" + lib + "/QCMDSRC) " + flags)
	runscript (stmf, shell)

def build_dspf (stmf , cmd ,lib , liblist , obj , flags , include):
	flags = flags + " OPTION(*EVENTF)"
	shell = oscmd("liblist -a " + liblist )
	shell +=  oscmd("setccsid 1252 " + stmf)
	shell += syscmd("CRTSRCPF FILE(" + lib + "/QDDSSRC) RCDLEN(132)")
	shell += syscmd("CPYFRMSTMF FROMSTMF('" + stmf + "') TOMBR('/QSYS.lib/"+ lib + ".lib/QDDSSRC.file/" + obj + ".mbr') MBROPT(*REPLACE)")
	shell += syscmdlist("CRTDSPF FILE(" + lib + "/" + obj + ") SRCFILE(" + lib + "/QDDSSRC) " + flags)
	runscriptAndShowEventfile (stmf, shell, lib , obj)

def build_menu (stmf , cmd ,lib , liblist , obj , flags , include):
	flags = flags + " OPTION(*EVENTF)"
	shell = oscmd("liblist -a " + liblist )
	shell +=  oscmd("setccsid 1252 " + stmf)
	shell += syscmd("CRTSRCPF FILE(" + lib + "/QUIMSRC) RCDLEN(132)")
	shell += syscmd("CPYFRMSTMF FROMSTMF('" + stmf + "') TOMBR('/QSYS.lib/"+ lib + ".lib/QUIMSRC.file/" + obj + ".mbr') MBROPT(*REPLACE)")
	shell += syscmdlist("CRTMNU TYPE(*UIM) MENU(" + lib + "/" + obj + ") SRCFILE(" + lib + "/QUIMSRC) " + flags)
	runscriptAndShowEventfile (stmf, shell, lib , obj)

def build_pnlgrp (stmf , cmd ,lib , liblist , obj , flags , include):
	flags = flags + " OPTION(*EVENTF)"
	shell = oscmd("liblist -a " + liblist )
	shell +=  oscmd("setccsid 1252 " + stmf)
	shell += syscmd("CRTSRCPF FILE(" + lib + "/QUIMSRC) RCDLEN(132)")
	shell += syscmd("CPYFRMSTMF FROMSTMF('" + stmf + "') TOMBR('/QSYS.lib/"+ lib + ".lib/QUIMSRC.file/" + obj + ".mbr') MBROPT(*REPLACE)")
	shell += syscmdlist("CRTPNLGRP PNLGRP(" + lib + "/" + obj + ") SRCFILE(" + lib + "/QUIMSRC) " + flags)
	runscriptAndShowEventfile (stmf, shell, lib , obj)

# def build_sql_ILE (stmf , cmd ,lib , liblist , obj , flags , include):
# 	shell =  oscmd("liblist -a " + liblist )
# 	shell += oscmd("setccsid 1252 " + stmf)
# 	shell += syscmdlist("RUNSQLSTM SRCSTMF('" + stmf + "') " + flags)
# 	return shell,False

def build_sql (stmf , cmd ,lib , liblist , obj , flags , include):
	shell =  oscmd("liblist -a " + liblist )
	shell += oscmd("setccsid 1252 " + stmf)
	shell += oscmd("db2 -f " + stmf)
	runandshow (shell)
	return


# ------------------------------------------------------------------------
# Execute the compound script againt the IBM i
# ------------------------------------------------------------------------
def	runscriptAndShowOutput  (stmf, shell):
	shell = "/QOpenSys/usr/bin/qsh -c '" + shell + "'"
	proc = subprocess.Popen(shell,
		shell=True,
		stdin=subprocess.PIPE,
		stdout=subprocess.PIPE,
		stderr=subprocess.PIPE
	)

	for ln in proc.stdout:
		ln = ln.rstrip()
		#if ln.startswith(' ***ERROR'):
		print ln

	for ln in proc.stderr:
		ln = ln.rstrip()
		print ln

def	runscriptAndShowEventfile (stmf, shell, lib , obj):
	runscript (stmf, shell)
	showEventFile (lib, obj)

def runscript(stmf, shell):
	shell = "/QOpenSys/usr/bin/qsh -c '" + shell + "'"
	proc = subprocess.Popen(shell,
		shell=True,
		stdin=subprocess.PIPE,
		stdout=subprocess.PIPE,
		stderr=subprocess.PIPE
	)

	# Format messages
	i=0
	for ln in proc.stderr:
		ln = ln.rstrip()
		msgid = ln[0:7]
		if msgid  not in ['CPC2206' , 'CZM1003', 'CPD4090' ,'CZS2117' , 'CPFB414', 'CPF5813' ,'CPF7302' , 'CPCA081', 'CPC0904' ,'CPC7301' ,'CPI2126']:
			i += 1
			print '{stmf}:{line}:{col}:{sev}:{msg}'.format(
				stmf  = stmf,
				sev   = 'info',
				msg   = ln,
				line  = 0,
				col   = i
			)

# ------------------------------------------------------------------------
# Format the data from the EVENTF
#peek from
#ERROR      1 001 1 000003 000003 005 000003 005 CZM0045 S 30 024 Undeclared identifier i.
#ERROR      0 001 1 000020 000020 000 000020 000 CPD0791 I 00 116 No labels used in program.

def showEventFile (lib , obj):
	shell = oscmd ("cat /QSYS.LIB/" + lib + ".LIB/EVFEVENT.FILE/" + obj + ".MBR") 
	shell = "/QOpenSys/usr/bin/qsh -c '" + shell + "'"
	proc = subprocess.Popen(shell,
		shell=True,
		stdin=subprocess.PIPE,
		stdout=subprocess.PIPE,
		stderr=subprocess.PIPE
	)

	rec = proc.stdout.read(400)
	while rec > ' ':
		ln = rec.decode('cp500').encode('latin1').rstrip()
		lntype = ln[0:5]
		if  lntype == 'ERROR': 
			msgid = ln[48:55]
			severity = ln[56:57]
			if  msgid not in ['RNF7031', 'RNF7534' , 'RNF5409']:
				print '{stmf}:{line}:{col}:{sev}:{msgid}:{msgtext}'.format(
					stmf  = stmf,
					sev   = ('info' if severity in ["I" , "W"] else 'error'),
					msgid = msgid,
					msgtext = ln[65:9999],
					line  = ln[37:43],
					col   = ln[44:47]
				)
		rec = proc.stdout.read(400)

def runandshow (shell):
	shell = "/QOpenSys/usr/bin/qsh -c '" + shell + "'"
	proc = subprocess.Popen(shell,
		shell=True,
		stdin=subprocess.PIPE,
		stdout=subprocess.PIPE,
		stderr=subprocess.PIPE
	)

	for ln in proc.stdout:
		print ln.rstrip()

def syscmd(cmd):
	wrkcmd = "system -vK \"" + cmd.replace("'", "'\\''") + "\";\n"
	return wrkcmd

def syscmdlist(cmd):
	print cmd
	wrkcmd = oscmd("touch postlist.txt")
	wrkcmd += oscmd("setccsid 1252 postlist.txt")
	wrkcmd += "system -vK \"" + cmd.replace("'", "'\\''") + "\" >postlist.txt;\n"
	return wrkcmd

def oscmd (cmd):
	wrkcmd = cmd.replace("'", "'\\''") .replace("\"" , "\\\"")+ ";\n"
	return wrkcmd

def pickUpFlags(stmf):
	f = open(stmf)
	line = f.readline()
	if line.startswith( '**FREE'):
		line = f.readline()
	f.close()
	# picup parameter if it has a CMD: annotation.two components: the compiler command its parameters
	options = re.search("CMD:([^\s]+)?(?:\s*)(.*\))?", line)
	cmd = "" if options == None or options.group(1) == None else  options.group(1)
	extflags = "" if options == None or options.group(2) == None else  options.group(2)
	return  cmd, extflags


# ------------------------------------------------------------------------
# Main line
# ------------------------------------------------------------------------
parser=argparse.ArgumentParser()
parser.add_argument('--stmf', help='stream file')
parser.add_argument('--lib' , help='Object library')
parser.add_argument('--liblist', help='library lists')
parser.add_argument('--flags', help='compile flags')
parser.add_argument('--include', help='include directories')
args=parser.parse_args()


lib = args.lib
liblist = args.liblist
stmf = args.stmf
include = args.include
flags = args.flags

showEvent = False


#print args
#print sys


# get the components: file, path and extention
path, filename  = os.path.split(stmf)
obj, ext = filename.split(".")
cmd, extflags = pickUpFlags(stmf)

# flags from souce has higer precedence that the makefile
# Exept for CMD where we merge
# TODO! Always merge, and replace duplicates where souce has higer precedence!!
if ext == 'cmd':
	flags = flags + " " +extflags
elif extflags > "":
	flags = extflags

if   ext == 'c':
	build_cmod (stmf , cmd ,lib,  liblist , obj , flags , include)
elif ext == 'rpgle':
	build_rpgmod (stmf , cmd ,lib, liblist , obj , flags , include)
elif ext == 'sqlrpgle':
	build_sqlrpgmod (stmf , cmd ,lib, liblist , obj , flags , include)
elif ext == 'clle':
	build_clmod (stmf , cmd ,lib , liblist ,obj , flags , include)
elif ext == 'srvpgm':
	build_srvpgm (stmf , cmd ,lib , liblist ,obj , flags , include)
elif ext == 'cmd':
	build_cmd (stmf , cmd ,lib , liblist ,obj , flags , include)
elif ext == 'dspf':
	build_dspf (stmf , cmd ,lib , liblist ,obj , flags , include)
elif ext == 'menu':
	build_menu (stmf , cmd ,lib , liblist ,obj , flags , include)
elif ext == 'pnlgrp':
	build_pnlgrp (stmf , cmd ,lib , liblist ,obj , flags , include)
elif ext == 'sql':
	build_sql (stmf , cmd ,lib , liblist ,obj , flags , include)
else:
	print "no compiler for " + ext