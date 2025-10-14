#ifndef VARCHAR_H
#define  VARCHAR_H

typedef _Packed struct  _VARCHARLIST {                 
   ULONG  memUsed;                                     
   ULONG  endOffset;                                   
   ULONG  numEntries;                                  
   PUCHAR list;                                        
} VARCHARLIST, * PVARCHARLIST;                         

typedef void * PVAR_CHAR;

typedef _Packed struct _VARPUCHAR {    
   USHORT Length;                      
   PUCHAR String;                      
} VARPUCHAR, * PVARPUCHAR;             

typedef _Packed struct _LVARPUCHAR {    
   ULONG  Length;                      
   PUCHAR String;                      
} LVARPUCHAR, * PLVARPUCHAR;             


typedef _Packed struct _LVARCHAR {
   ULONG  Length;
   UCHAR  String[1048576];
} LVARCHAR, * PLVARCHAR;

// Real varchars:
typedef _Packed struct _VARCHAR {
   SHORT Length;
   UCHAR String[32767];
} VARCHAR, * PVARCHAR;

typedef _Packed struct _VARCHAR1   {
   SHORT Length;
   UCHAR String[1];
} VARCHAR1, * PVARCHAR1;

typedef _Packed struct _VARCHAR12  {
   SHORT Length;
   UCHAR String[12];
} VARCHAR12, * PVARCHAR12;

typedef _Packed struct _VARCHAR20  {
   SHORT Length;
   UCHAR String[20];
} VARCHAR20, * PVARCHAR20;

typedef _Packed struct _VARCHAR32  {
   SHORT Length;
   UCHAR String[32];
} VARCHAR32, * PVARCHAR32;

typedef _Packed struct _VARCHAR64  {
   SHORT Length;
   UCHAR String[64];
} VARCHAR64, * PVARCHAR64;

typedef _Packed struct _VARCHAR128 {
   SHORT Length;
   UCHAR String[128];
} VARCHAR128, * PVARCHAR128;

typedef _Packed struct _VARCHAR200 {
   SHORT Length;
   UCHAR String[200];
} VARCHAR200, * PVARCHAR200;

typedef _Packed struct _VARCHAR256 {
   SHORT Length;
   UCHAR String[256];
} VARCHAR256, * PVARCHAR256;

typedef _Packed struct _VARCHAR512 {
   SHORT Length;
   UCHAR String[512];
} VARCHAR512, * PVARCHAR512;

typedef _Packed struct _VARCHAR1024 {
   SHORT Length;
   UCHAR String[1024];
} VARCHAR1024, * PVARCHAR1024;

typedef _Packed struct _VARCHAR4096 {
   SHORT Length;
   UCHAR String[4096];
} VARCHAR4096, * PVARCHAR4096;

typedef _Packed struct _VARCHAR8192 {
   SHORT Length;
   UCHAR String[8192];
} VARCHAR8192, * PVARCHAR8192;

typedef _Packed struct _VARCHAR16384 {
   SHORT Length;
   UCHAR String[16384];
} VARCHAR16384, * PVARCHAR16384;

void vcTrimRight (PVAR_CHAR VarChar);
void str2vc    ( PVAR_CHAR VarChar, PUCHAR in);
PUCHAR vc2strtrim(PVOID pv);
void substr2vc ( PVAR_CHAR out , PUCHAR in , LONG len);
PUCHAR vc2strcpy(PUCHAR res,  PVOID pv);
PUCHAR vc2str  (PVAR_CHAR pv);
PUCHAR plvc2str (PLVARCHAR pv);
void vccpy     (PVARCHAR out , PVARCHAR in);
void vccatstr  (PVARCHAR out , PUCHAR s   );
void vccatc    (PVARCHAR out, UCHAR in);
void vccatvc   (PVARCHAR out, PVARCHAR in);
void vccatmem  (PVARCHAR out , PUCHAR s , LONG len);
void vcprintf  ( PVAR_CHAR VarChar, PUCHAR Ctlstr , ...);
void vccatf    ( PVAR_CHAR VarChar, PUCHAR Ctlstr , ...);

// Long versions
void lvpc2lvc (PLVARCHAR out, PLVARPUCHAR in);
void lvpc2vc  (PVARCHAR out, PLVARPUCHAR in);
BOOL vpcIsEqual(PVARPUCHAR p1, PVARPUCHAR p2);
BOOL lvpcIsEqual(PLVARPUCHAR p1, PLVARPUCHAR p2);
PUCHAR plvc2str (PLVARCHAR s);
void   str2plvc (PLVARCHAR out , PUCHAR in);
void plvccatstr (PLVARCHAR out , PUCHAR s   );
void plvccopy (PLVARCHAR out, PLVARCHAR in);



#endif