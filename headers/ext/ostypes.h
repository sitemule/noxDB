#ifndef OSTYPES_H
#define OSTYPES_H

#ifndef   __decimal_h
 #include <decimal.h>
#endif

/* Logical boleans states */
#pragma enum     (1)
typedef enum {
   OFF = '0',
   ON  = '1'
} LGL , *  PLGL;
#pragma enum     (pop)

/* Logical boleans states */
#pragma enum     (1)
typedef enum {
   FALSE = 0,
   TRUE = 1
} BOOL, *PBOOL;
#pragma enum     (pop)

/* Logical boleans states */
#pragma enum     (2)
typedef enum {
   FALSE16  = 0,
   TRUE16   = 1
} BOOL16, *PBOOL16;
#pragma enum     (pop)

/* Logical boleans states */
#ifndef TRUE
  #define TRUE  1
#endif

#ifndef FALSE
  #define FALSE 0
#endif

/* Logical boleans states C++ style*/
#ifndef true
  #define true  1
#endif

#ifndef false
  #define false 0
#endif

#ifndef null
  #define null  0
#endif


typedef void                VOID, * PVOID;
/* typedef unsigned char       BOOL, * PBOOL; */
typedef signed   char       CHAR, * PCHAR;
typedef unsigned char       UCHAR, * PUCHAR;
typedef unsigned long int   ULONG, *  PULONG;
typedef unsigned long long int   UINT64, *  PUINT64;
typedef unsigned short int  USHORT, * PUSHORT;
typedef signed long int     LONG, * PLONG;
typedef signed long long int INT64, * PINT64;
typedef signed short int    SHORT, * PSHORT;
typedef UCHAR               ZONED, * PZONED;
typedef int                 SOCKET, *   PSOCKET;
typedef PUCHAR              PZS;

/* ------------------------------------------------------------- */
/* Dynamic OS/400 function call */
/* ------------------------------------------------------------- */
typedef void(PGM) ();
#pragma linkage (PGM, OS)
typedef PGM * PPGM;

#ifndef Ubound
  #define Ubound(a) (sizeof(a)/sizeof(a[0]))
#endif

#ifndef ENUM
   #define ENUM(a,b) (b)
#endif

#ifndef Found
   #define Found(a) (a->riofb.num_bytes>0)
#endif

#ifndef Eof
   #define Eof(a)  (!Found(a))
#endif

#ifndef Max
   #define Max(a,b) (a>b) ? a : b
#endif

#ifndef Min
   #define Min(a,b) (a<b) ? a : b
#endif

/* Missing in math.h */
#ifndef M_PI
  #define M_PI 3.141592653589793238462643
#endif

#ifndef M_SQRT2
#define M_SQRT2 1.4142135623730950488016887
#endif

/* Missing in sys/stats.h */
#ifndef O_BINARY
#define O_BINARY  0
#endif

#ifndef S_IREAD
  #define S_IREAD S_IROTH
#endif
#ifndef S_IWRITE
  #define S_IWRITE  S_IWOTH
#endif

typedef _Packed struct {
   LONG  top;
   LONG  left;
   LONG  bottom;
   LONG  right;
} RECT;



typedef decimal(30,15) FIXEDDEC, * PFIXEDDEC;

typedef void * PVAR_CHAR;

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

typedef _Packed struct _VARCHAR_16M {
   LONG Length;
   UCHAR String[16773096];
} VARCHAR_16M, * PVARCHAR_16M;


typedef _Packed struct _VARPUCHAR {
   USHORT Length;
   PUCHAR String;
} VARPUCHAR, * PVARPUCHAR;

typedef _Packed struct {
   UCHAR year[4];
   UCHAR pad1;
   UCHAR month[2];
   UCHAR pad2;
   UCHAR day[2];
} DATE, *PDATE;

typedef _Packed struct {
   UCHAR hh[2];
   UCHAR pad1;
   UCHAR mm[2];
   UCHAR pad2;
   UCHAR ss[2];
} TIME, *PTIME;

typedef _Packed struct _TIMESTAMP  {
   UCHAR  ccyy [4];
   UCHAR  d1;
   UCHAR  month [2];
   UCHAR  d2;
   UCHAR  day   [2];
   UCHAR  d3;
   UCHAR  hour  [2];
   UCHAR  d4;
   UCHAR  minute [2];
   UCHAR  d5;
   UCHAR  second [2];
   UCHAR  d6;
   UCHAR  milsecond [6];
} TIMESTAMP, * PTIMESTAMP;

typedef _Packed struct _BLOB {
   ULONG Length;
   UCHAR String[1];
} BLOB, * PBLOB;

#ifndef memicmp
#  define memicmp __memicmp
  int __memicmp(PUCHAR , PUCHAR, int );
#endif

#ifndef stricmp
#  define stricmp __stricmp
  int __stricmp(PUCHAR , PUCHAR);
#endif

#ifndef strnicmp
#  define strnicmp __strnicmp
  int __strnicmp(PUCHAR , PUCHAR, int );
#endif

#ifndef strdup
#  define strdup  __strdup
  PUCHAR  __strdup (PUCHAR str);
#endif
#define BeginsWith(a,b) (memicmp(a, b, sizeof(b)-1) == 0)

#ifndef GETVARPUCHARPARM
 #define GETVARPUCHARPARM(a,b,c) \
 { int posn = c ,desctype  , datatype  , descinf1  , descinf2 , Len;  \
   CEEDOD (&posn  , &desctype  , &datatype  , &descinf1  , &descinf2  , &Len , NULL); \
   a ## .Length = Len;   \
   a ## .String = b;     \
 }
#endif
#endif
