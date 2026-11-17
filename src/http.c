// CMD:CRTCMOD 
/* ------------------------------------------------------------- *
 * Company . . . : System & Method A/S                           *
 * Design  . . . : Niels Liisberg                                *
 * Function  . . : http handler                                  *
 * ------------------------------------------------------------- */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <leod.h>
#include <decimal.h>
#include <wchar.h>
#include <qp2shell.h>   
// #include <errno.h>

#include <sys/stat.h>
#include "ostypes.h"
#include "varchar.h"
#include "xlate.h"
#include "parms.h"
#include "memUtil.h"
#include "noxdb2.h"

// ---------------------------------------------------------------------------
PUCHAR loadText (PUCHAR file)
{
	  PUCHAR p;
	  FILE * f;
	  int l;
	  long fileSize;
	  f = fopen(file , "rb");
	  if (f == NULL) return NULL;
	  fseek(f, 0L, SEEK_END);
	  fileSize = ftell(f);
	  if (fileSize <= 0) {
		  fclose(f);
		  return NULL;
	  }
	  fseek(f, 0L, SEEK_SET);
	  // The file size is in bytes; room for all of them and the terminator
	  p = malloc(fileSize + 1);
	  l = fread(p, 1 , fileSize , f);
	  fclose(f);
	  if (l<= 0) {
		  free(p);
		  return(NULL);
	  }
	  p[l] = '\0';
	  return p;
}
// ---------------------------------------------------------------------------
void sh (PUCHAR cmd)
{
	QP2SHELL  ("/QOpenSys/usr/bin/sh", "-c" , cmd);  
}
/* ---------------------------------------------------------------------------
   The curl command runs through "sh -c": every argument we put on that
   command line is single quoted, so the shell sees no $( ) ` ; | & < > or
   blanks in it. A ' in the text becomes '"'"' (end quote, a quoted ', quote).
   --------------------------------------------------------------------------- */
static PUCHAR putShellChar (PUCHAR p, UCHAR c)
{
   if (c == '\'') {
      memcpy (p , "'\"'\"'" , 5);
      return p + 5;
   }
   *p = c;
   return p + 1;
}
static PUCHAR putShellQuoted (PUCHAR p, PUCHAR s)
{
   *(p++) = '\'';
   for (; *s ; s++) p = putShellChar (p , *s);
   *(p++) = '\'';
   *(p++) = ' ';
   return p;
}
/* ---------------------------------------------------------------------------
   "options" are curl options, i.e.: -H 'Authorization: Bearer x' -X PUT
   Split them into words the way the shell would (blanks, '...' and "...")
   and pass each word quoted - so the words reach curl, but nothing in them
   is run by the shell. Note: they are still curl options - an application
   must not build them from untrusted input.
   --------------------------------------------------------------------------- */
static PUCHAR putShellOptions (PUCHAR p, PUCHAR opt)
{
   for (;;) {
      UCHAR quote = 0;
      for (; *opt == ' ' ; opt++);
      if (*opt == '\0') break;
      *(p++) = ' ';
      *(p++) = '\'';
      for (; *opt ; opt++) {
         if (quote) {
            if (*opt == quote) {
               quote = 0;
            } else {
               p = putShellChar (p , *opt);
            }
         } else if (*opt == '\'' || *opt == '"') {
            quote = *opt;
         } else if (*opt == ' ') {
            break;
         } else {
            p = putShellChar (p , *opt);
         }
      }
      *(p++) = '\'';
      *(p++) = ' ';
   }
   return p;
}
/* ---------------------------------------------------------------------------
	get a resource on the net
	--------------------------------------------------------------------------- */
PNOXNODE nox_httpRequest (PLVARCHAR urlP, PNOXNODE pNode, PLVARCHAR optionsP)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	PUCHAR  cmd;
	PUCHAR  p;
	UCHAR   temp1[256];
	UCHAR   temp2[256];
	UCHAR   error[256];
	UCHAR   at [2];
	PUCHAR  url;
	PNOXNODE  pRes;
	PUCHAR  options;

	// Setup parameters - buffers sized from the input
	// (UTF-8 to the job CCSID: at most 3 bytes out for each byte in)
	url = memAlloc (urlP->Length * 3 + 1);
	Xlatestr (url  , plvc2str (urlP) , 1208 , 0);

	if ( pParms->OpDescList->NbrOfParms < 2 )  pNode = NULL;
	
	if ( pParms->OpDescList->NbrOfParms < 3 ) {
		options = memAlloc (1);
		options [0] = '\0';
	} else {
		options = memAlloc (optionsP->Length * 3 + 1);
		Xlatestr (options , plvc2str(optionsP) , 1208 , 0);
	}
	// fixed text, three file names and every quoted character up to 5 bytes
	cmd = memAlloc (2048 + 3 * sizeof(temp1) + 5 * (strlen(url) + strlen(options)));
	p = cmd;

	// Get the job version of a @	
	#pragma convert(1252)  
	Xlatestr (at , "@" , 1252 , 0);
	#pragma convert(0)  
	
	// Build workfile names:
	tmpnam(temp1);
	tmpnam(temp2);
	tmpnam(error);

	// buiild the script / curl command
	p += sprintf( p , "touch -c 1208 %s;" , temp2);
	p += sprintf( p , "/QOpenSys/pkgs/bin/curl -k --silent --show-error -o %s", temp2);

	if (pNode) {
		// The positive value causes it to not produce BOM code
		nox_WriteJsonStmf (pNode , temp1 , 1208, ON ,NULL);
		p += sprintf( p , " -X POST --data-binary %s%s " , at, temp1);
	}
	p += sprintf( p ,  " %s ",
		"-H 'Content-Type: application/json; charset=utf-8' "
		"-H 'Accept: application/json' "
	);
	p = putShellOptions (p , options);
	// --url: the url is never taken as a curl option, even if it starts with -
	p += sprintf( p ,  " --url ");
	p = putShellQuoted (p , url);
	p += sprintf( p ,  " --stderr %s;", error);
	p += sprintf( p , "setccsid 1208 %s" , temp2);
	
	// Run the script
	sh (cmd);
	memFree (&cmd);
	memFree (&url);
	memFree (&options);

	// Process the response:
	p =  loadText(error);
	if (p != NULL) {
		pRes = nox_NewObject();
		#pragma convert(1252)  
		nox_SetValueByName(pRes , "success"  , "false" , LITERAL);
		nox_SetValueByName(pRes , "reason" , p , VALUE );
		#pragma convert(0)
		free(p);
	} else {
		pRes = nox_ParseFile (temp2);
		if (pRes == NULL) {
			pRes = nox_NewObject();
			p =  loadText(temp2);
			#pragma convert(1252)  
			nox_SetValueByName(pRes , "success"  , "true" , LITERAL);
			nox_SetValueByName(pRes , "data" , p , VALUE );
			#pragma convert(0)
			free(p);
		}
	}
	// Clean up
	unlink (temp1);
	unlink (temp2);
	unlink (error);
	return pRes;
}

