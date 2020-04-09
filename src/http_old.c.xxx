/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL) */
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
#include <errno.h>
// #include <qp2shell.h> 
#include <qp2user.h>  
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
	  PUCHAR p = malloc(320000);
	  FILE * f;
	  int l;
	  f = fopen(file , "rb");
	  l = fread(p, 1 , 320000 , f);
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

	int rc;                     
	UCHAR ret [256];              
	PUCHAR pgm = "/QOpenSys/usr/bin/sh";   
	PUCHAR argv[4];                           
	PUCHAR envp[2];                           
	argv [0] = pgm;   // Note !! argv 0 is always the program it self
	argv [1] = "-c"  ;                               
	argv [2] = cmd;                                                 
	argv [3] = NULL;                                                 
	rc = Qp2RunPase(                                                        
		pgm  ,    /* Path name */                                            
		NULL,     /* Symbol for calling to ILE, not used in this sample */   
		NULL,     /* Symbol data for ILE call, not used here */              
		0 ,       /* Symbol data length for ILE call, not used here */       
		1208,     /* ASCII CCSID for IBM i PASE */                           
		argv,     /* Arguments for IBM i PASE program */                     
		NULL      /* Environment variable list */                            
	);              
	if (rc) {
		sprintf(ret , "Error: %d - %s\n", rc, strerror(errno));	
	}
}
/* ---------------------------------------------------------------------------
	get a resource on the net
	--------------------------------------------------------------------------- */
PNOXNODE nox_httpRequest (PLVARCHAR urlP, PNOXNODE pNode, PLVARCHAR optionsP)
{
	PNPMPARMLISTADDRP pParms = _NPMPARMLISTADDR();
	UCHAR   cmd [4097];
	PUCHAR  p = cmd;
	UCHAR   temp1[256];
	UCHAR   temp2[256];
	UCHAR   error[256];
	UCHAR   atemp1[256];
	UCHAR   atemp2[256];
	UCHAR   aerror[256];
	PNOXNODE  pRes;
	PUCHAR options = ( pParms->OpDescList->NbrOfParms < 3 )  ? NULL : plvc2str(optionsP);
	PUCHAR url = plvc2str (urlP);

	if ( pParms->OpDescList->NbrOfParms < 2 )  pNode = NULL;

	#pragma convert(1252)  

	tmpnam(temp1);
	tmpnam(temp2);
	tmpnam(error);

	stre2a (atemp1, temp1);
	stre2a (atemp2, temp2);
	stre2a (aerror, error);

	cmd [0] = '\0';
	strcat(cmd , "touch -C 1208 ");
	strcat(cmd , atemp2);
	strcat(cmd , ";curl -s -k -o ");
	strcat(cmd , atemp2);

	if (pNode) {
		// The negative causes it not to produce BOM code
		nox_WriteJsonStmf (pNode , temp1 , -1208, ON ,NULL);
		strcat (cmd , " -X POST --data @");
		strcat (cmd , atemp1);
	}
	strcat (cmd,
		" -H 'Content-Type: application/json' "
		" -H 'Accept: application/json' "
	);
	if (options) {
		strcat (cmd, options);
	}
	strcat (cmd, " ");
	strcat (cmd, url);
	sh (cmd);

	p =  loadText(error);
	if (p != NULL) {
		pRes = nox_NewObject();
		nox_SetValueByName(pRes , "success"  , "false" , LITERAL);
		nox_SetValueByName(pRes , "reason" , p , VALUE );
		free(p);
	} else {
		pRes = nox_ParseFile (temp2);
		if (pRes == NULL) {
			pRes = nox_NewObject();
			p =  loadText(temp2);
			nox_SetValueByName(pRes , "success"  , "true" , LITERAL);
			nox_SetValueByName(pRes , "data" , p , VALUE );
			free(p);
		}
	}
	unlink (temp1);
	unlink (temp2);
	unlink (error);
	return pRes;
	#pragma convert(0)
}

