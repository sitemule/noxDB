/* ------------------------------------------------------------- *
 * Company . . . : System & Method A/S                           *
 * Design  . . . : Niels Liisberg                                *
 * Function  . . : CCSID fingerprint detector                    *
 *                                                                *
 * The caller's RPG module CCSID is never passed explicitly, and *
 * cannot be assumed from the job CCSID. Instead the RPG compiler *
 * itself is used as the translator: headers/qccsid.rpgle (built  *
 * into NOXDB/QCCSID(QCCSID), always stored as CCSID 500) declares *
 * a short character constant, JX_CCSID_FINGERPRINT. When a caller *
 * /includes it and passes it here, the RPG compiler has already   *
 * translated its bytes from CCSID 500 into whatever CCSID the     *
 * caller's own module was compiled under - so the raw bytes       *
 * received here identify that CCSID.                              *
 *                                                                 *
 * jx_ModuleCcsid() does a fixed-length, byte-for-byte lookup      *
 * against the fingerprints of every supported CCSID. No string    *
 * routines, no strlen(), no job CCSID - the input is treated       *
 * purely as 4 raw bytes.                                          *
 *                                                                 *
 * See design.md / issues docs for how the fingerprint table was   *
 * derived and which CCSID pairs remain indistinguishable.         *
 * ------------------------------------------------------------- */
#include <string.h>

#define FINGERPRINT_LEN 4

typedef struct {
   unsigned char fingerprint[FINGERPRINT_LEN];
   int           ccsid;
} CCSIDFINGERPRINT;

static const CCSIDFINGERPRINT fingerprints[] = {
   { { 0x9F, 0x6A, 0x8C, 0xBA }, 37 },
   { { 0x9F, 0xCC, 0x8C, 0x63 }, 273 },
   { { 0x5A, 0x70, 0x8C, 0x9E }, 277 },
   { { 0x5A, 0xCC, 0x8C, 0xB5 }, 278 },
   { { 0x9F, 0xCD, 0x8C, 0x90 }, 280 },
   { { 0x9F, 0x49, 0x8C, 0x4A }, 284 },
   { { 0x9F, 0x6A, 0x8C, 0xB1 }, 285 },
   { { 0x9F, 0xDD, 0x8C, 0x90 }, 297 },
   { { 0x9F, 0x6A, 0x8C, 0x4A }, 500 },
   { { 0x9F, 0x3F, 0x3F, 0x4A }, 870 },
   { { 0x9F, 0x6A, 0x79, 0xAE }, 871 },
   { { 0x3F, 0xDF, 0x3F, 0x4A }, 875 },
   { { 0x9F, 0x8E, 0x3F, 0x68 }, 1026 },
   { { 0x9F, 0x6A, 0x3F, 0xBA }, 1112 },
   { { 0x5A, 0xCC, 0x3F, 0xB5 }, 1122 },
   { { 0x3F, 0x6A, 0x8C, 0xBA }, 1140 },
   { { 0x3F, 0xCC, 0x8C, 0x63 }, 1141 },
   { { 0x3F, 0x70, 0x8C, 0x9E }, 1142 },
   { { 0x3F, 0xCC, 0x8C, 0xB5 }, 1143 },
   { { 0x3F, 0xCD, 0x8C, 0x90 }, 1144 },
   { { 0x3F, 0x49, 0x8C, 0x4A }, 1145 },
   { { 0x3F, 0x6A, 0x8C, 0xB1 }, 1146 },
   { { 0x3F, 0xDD, 0x8C, 0x90 }, 1147 },
   { { 0x3F, 0x6A, 0x8C, 0x4A }, 1148 },
   { { 0x3F, 0x6A, 0x79, 0xAE }, 1149 },
   { { 0x3F, 0x3F, 0x3F, 0x4A }, 1153 },
   { { 0x3F, 0x8E, 0x3F, 0x68 }, 1155 },
   { { 0x3F, 0x6A, 0x3F, 0xBA }, 1156 },
   { { 0x3F, 0xCC, 0x3F, 0xB5 }, 1157 },
   { { 0x3F, 0x6A, 0x3F, 0x49 }, 1160 },
};

int jx_ModuleCcsid(const unsigned char *p)
{
   size_t i;

   for (i = 0; i < sizeof(fingerprints) / sizeof(fingerprints[0]); ++i) {
      if (memcmp(p, fingerprints[i].fingerprint, FINGERPRINT_LEN) == 0)
         return fingerprints[i].ccsid;
   }

   return 0;
}
