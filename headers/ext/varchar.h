typedef _Packed struct  _VARCHARLIST {
   ULONG  memUsed;
   ULONG  endOffset;
   ULONG  numEntries;
   PUCHAR list;
} VARCHARLIST, * PVARCHARLIST;

void vcTrimRight (PVAR_CHAR VarChar);
void str2vc    ( PVAR_CHAR VarChar, PUCHAR in);
PUCHAR vc2strtrim(PVOID pv);
void substr2vc ( PVAR_CHAR out , PUCHAR in , LONG len);
PUCHAR vc2strcpy(PUCHAR res,  PVOID pv);
PUCHAR vc2str  (PVAR_CHAR pv);
void vccpy     (PVARCHAR out , PVARCHAR in);
void vccatstr  (PVARCHAR out , PUCHAR s   );
void vccatc    (PVARCHAR out, UCHAR in);
void vccatvc   (PVARCHAR out, PVARCHAR in);
void vccatmem  (PVARCHAR out , PUCHAR s , LONG len);
void vcprintf  ( PVAR_CHAR VarChar, PUCHAR Ctlstr , ...);
void vccatf    ( PVAR_CHAR VarChar, PUCHAR Ctlstr , ...);
VARPUCHAR vc2varpuchar(PVAR_CHAR s);
VARPUCHAR str2varpuchar(PUCHAR s);
PVARCHARLIST  vcListNew (void);
void vcListAdd (PVARCHARLIST pVcl ,PVAR_CHAR str);
void vcListFree(PVARCHARLIST pVcl);
PVARCHAR  vcListFirst (PVARCHARLIST pVcl);
PVARCHAR  vcListNext  (PVARCHARLIST pVcl, PVAR_CHAR pVc);
#define VARCHAR2PUCHAR(a) ((PVARCHAR) a)->String; ((PVARCHAR) a)->String[((PVARCHAR) a)->Length] = '\0';
PUCHAR  vpc2string(PUCHAR res, PVARPUCHAR pvpc );
VARPUCHAR vpcSetString(PUCHAR s);
BOOL vpcIsEqual(PVARPUCHAR p1, PVARPUCHAR p2);

// long version:
PLVARCHAR lvcCopy(PLVARCHAR out, PLVARCHAR in);
PLVARCHAR lvcStrCopy(PLVARCHAR out, PUCHAR in);
void lvcPrintf  (PLVARCHAR , PUCHAR Ctlstr , ...);
void lvcCatstr  (PLVARCHAR out , PUCHAR s   );
