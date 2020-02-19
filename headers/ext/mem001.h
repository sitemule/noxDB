#define MEMSIG (0x4c6e) // will show <> in the trace
//    define MEMDEBUG 1

PVOID  memAlloc  (ULONG len);
void   memFree   (PVOID * p);
PUCHAR memStrDup (PUCHAR s);
PUCHAR memStrTrimDup(PUCHAR s);
PVOID  memRealloc(PVOID * p, ULONG len);
PVOID  memShare (PUCHAR path, ULONG len);
ULONG  memSize   (PVOID p);
void   memStat   (void);
BOOL   memLeak   (void);
INT64  memUse    (void);

#ifndef MEMTYPES_H
#define MEMTYPES_H
typedef _Packed struct _MEMHDR {
      USHORT  signature;    //  2 the "<>" signature
      UCHAR   filler [10];  // 10 Pad up to 16 bytes total
      ULONG   size;         //  4
} MEMHDR, * PMEMHDR;        // 16 -> Total of 16 to let it allign for pointers
#define MEMMAX (2147483424 - sizeof(MEMHDR))
#endif