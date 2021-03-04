/* SYSIFCOPT(*IFSIO) TERASPACE(*YES *TSIFC) STGMDL(*SNGLVL) */
/* ------------------------------------------------------------- *
 * Company . . . : System & Method A/S                           *
 * Design  . . . : Niels Liisberg                                *
 * Function  . . : NOX - JSON serializer                         *
 *                                                               *
 * By     Date     Task    Description                           *
 * NL     02.06.03 0000000 New program                           *
 * ------------------------------------------------------------- */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <iconv.h>


#include <sys/stat.h>
#include "ostypes.h"
#include "sndpgmmsg.h"
#include "trycatch.h"
#include "rtvsysval.h"
#include "parms.h"
#include "utl100.h"
#include "mem001.h"
#include "varchar.h"
#include "jsonxml.h"
#include "/QSYS.LIB/QOAR.LIB/H.file/QRNDTAINTO.MBR"


extern int   OutputCcsid;

PJXNODE pRoot; 

typedef void (*JX_DATAINTO)();
static void  jx_dataIntoMapNode  (PJXNODE pNode, QrnDiParm_T * pParms, SHORT level);

/* --------------------------------------------------------------------------- */
static void  jx_dataIntoMapObject  (PJXNODE pParent, QrnDiParm_T * pParms, SHORT level)
{
	PJXNODE pNode;
	SHORT nextLevel = level +1;

	pParms->env->QrnDiStartStruct (pParms->handle);
	for (pNode = pParent->pNodeChildHead ; pNode ; pNode=pNode->pNodeSibling) {
		if  ( pNode->Name && *pNode->Name > 0) {
			pParms->env->QrnDiReportName  (pParms->handle , pNode->Name , strlen(pNode->Name));    
		}
		jx_dataIntoMapNode (pNode , pParms, nextLevel);
	}
	pParms->env->QrnDiEndStruct (pParms->handle);
}
/* --------------------------------------------------------------------------- */
static void  jx_dataIntoMapArray (PJXNODE pParent, QrnDiParm_T * pParms, SHORT level)
{
	PJXNODE pNode;
	SHORT nextLevel = level +1;

	pParms->env->QrnDiStartArray  (pParms->handle); 
	for (pNode = pParent->pNodeChildHead ; pNode ; pNode=pNode->pNodeSibling) {
		jx_dataIntoMapNode (pNode , pParms, nextLevel);
	}
	pParms->env->QrnDiEndArray  (pParms->handle); 
}
/* --------------------------------------------------------------------------- */
static void jx_dataIntoMapValue   (PJXNODE pNode, QrnDiParm_T * pParms )
{
	// Has value?
	if (pNode->Value && pNode->Value[0] > '\0') {
		pParms->env->QrnDiReportValue (pParms->handle , pNode->Value, strlen(pNode->Value));
	// Else it is some kind of null: Strings are "". Literals will return "null"
	} else {
		// Null handeling
		if (pNode->isLiteral) {
		//	pParms->env->QrnDiReportName  (pParms->handle , pNode->Name , strlen(pNode->Name));    
		//	pParms->env->QrnDiReportValue (pParms->handle , pNode->Value, strlen(pNode->Value));
		}
	}
}
/* --------------------------------------------------------------------------- */
/* Invalid node types are just jeft out                                          */
/* --------------------------------------------------------------------------- */
static void  jx_dataIntoMapNode  (PJXNODE pNode, QrnDiParm_T * pParms, SHORT level)
{
	if (pNode) {
		switch (pNode->type) {
			case OBJECT:
				jx_dataIntoMapObject  (pNode, pParms, level);
				break;

			case ARRAY:
				jx_dataIntoMapArray   (pNode, pParms, level);
				break;

			case VALUE:
			case POINTER_VALUE:
				jx_dataIntoMapValue   (pNode, pParms);
				break;
		}
	}
}
/* 	---------------------------------------------------------------------------
	--------------------------------------------------------------------------- */
static void   jx_dataIntoMapper (QrnDiParm_T * pParms)
{

	pParms->env->QrnDiStart  (pParms->handle); 
	jx_dataIntoMapNode (pRoot , pParms , 0 );             
	pParms->env->QrnDiFinish (pParms->handle );              

}
/* 	---------------------------------------------------------------------------
	--------------------------------------------------------------------------- */
JX_DATAINTO jx_dataInto (PJXNODE pNode) 
{
	pRoot = pNode; // not reentrant 

    return &jx_dataIntoMapper;
}
