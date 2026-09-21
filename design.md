# NoxDB Classic (`master` branch)

## Overview

When parsing files, parsing strings, loading the graph from SQL, or building the graph from scratch in an ILE program, all data ultimately stored in the graph uses the **CCSID of the current job**.

Unicode characters, and characters from other SBCS (Single-Byte Character Sets) that cannot be represented in the current job CCSID, are stored in the graph using the same approach as JSON: the Unicode value is escaped as a two-byte hexadecimal Unicode code point, for example:

```text
\uA1B2
```

The NoxDB service program is designed to be **CCSID-agnostic**. This means that client code using NoxDB can be written in any CCSID, including CCSID 65535, as described below.

noxDb loads the default parser constants when the JOSNXML service program is invoked by querineg the job CCSID at that time. If the user - after that point - issues a CHGJOB CCSID(xxx) - this change is never discovered - a detection of "current ccsid" need to be implmented.

---

# Loading Data from a Stream File

When a stream file is parsed, the input CCSID is determined using the following priority:

1. **Byte Order Mark (BOM)**
   If a BOM is present, it has the highest priority and determines the encoding.

2. **File CCSID**
   The file's CCSID is considered next, but only if it is consistent with the actual data.

   For example, a file may have a CCSID of 277 but actually contain ASCII data. In that situation, the file CCSID should be ignored because it does not describe the actual contents of the file.

   > **Code note (2026-09):** this tier is currently **not implemented** — it's dead code. `jx_ParseFile` (`src/noxdb.c:2005`) does fetch `statbuf.st_ccsid` into `InputCcsid`, but immediately discards it two lines later by calling `jx_parseStringCcsid(pFirstChar, 0)`, which resets `InputCcsid` to 0 before `detectEncoding` ever runs. The block inside `detectEncoding` that would have used the file's CCSID (`src/noxdb.c:1159-1164`) is commented out, with the note *"Avoid to use the ccsid from the file - this can be anything"*. In practice today the only tiers actually in effect are (1) BOM and (3) content sniffing — see below.

3. **Unicode byte order and content**
   If the data appears to be Unicode, either little-endian or big-endian, the contents of the file are examined to determine the Unicode encoding. The file CCSID is taken into account only if it is consistent with the detected encoding.

A common reason for an incorrect file CCSID is an FTP transfer that places a file on the IFS with an ISO-8859 CCSID even though the actual contents use a different encoding.

The `jx_ParseFile` function determines the input CCSID, sets `InputCcsid` accordingly, converts the file contents into the required representation, and passes the resulting buffer to `jx_ParseStringCCSID`.

---

# XML Encoding

When parsing an XML document, the XML declaration (prolog) is taken into account if it is present and consistent with the actual data.

For example, if the file contains a UTF-8 BOM but the XML prolog specifies a different Unicode encoding, the BOM takes precedence and the conflicting XML declaration is disregarded.

In other words, the detected encoding must be consistent with the actual byte representation of the document. The BOM has higher precedence than the XML prolog.

---

# JSON Encoding

JSON does not have an XML-style encoding prolog.

Therefore, when no other encoding information is available, JSON parsing falls back to **UTF-8** as the default encoding.

---

# Parsing from a String

There are two relevant APIs:

### `jx_ParseStringCCSID`

`jx_ParseStringCCSID` expects the input string to be encoded using the CCSID supplied in its `ccsid` parameter.

The caller is therefore explicitly responsible for specifying the actual CCSID of the input string.

### `jx_ParseString`

`jx_ParseString` assumes that the input string is encoded using the **current job CCSID**.

However, the program making the call to NoxDB may itself have been compiled with a different CCSID.

Therefore, when `jx_ParseString` is used, NoxDB must determine the actual CCSID of the input string rather than simply assuming the CCSID of the calling program.

---

# Determining the CCSID of the Calling Application

When possible, the CCSID should be determined from the parameter itself.

The input is passed as a pointer to a null-terminated string, and the ILE call stack can provide information about the calling program and its CCSID. This should have the highest priority.

However, IBM's documentation is not sufficiently precise about all aspects of this behavior, so this approach needs to be verified carefully.

An alternative is to examine the CCSID of the program that directly calls the NoxDB functionality.

This can potentially introduce a subtle CCSID transition problem.

For example:

```text
PGMA (CCSID 277)
    |
    +--> PGM5 (CCSID 500)
             |
             +--> NoxDB
```

If `PGMA` creates a graph and calls `PGM5`, which then calls NoxDB, determining the CCSID from the wrong level of the call stack could result in the wrong CCSID being associated with the input data.

The exact behavior of CCSID transitions between programs therefore needs to be considered carefully.

---

# Distinguishing a NoxDB Graph from a String

The APIs `jx_ParseString` and `jx_ParseStringCCSID` may also receive a pointer to an existing NoxDB graph.

When a pointer is passed to these functions, NoxDB must determine whether it points to a string or to an existing NoxDB graph.

This can be determined from the **signature** of the object being passed:

* A NoxDB node/graph has a NoxDB-specific signature.
* A normal string does not have this signature.

Therefore, the function can inspect the signature and determine whether the input is an existing NoxDB graph or a string.

If the input is already a NoxDB graph, the function can simply return the existing graph instead of attempting to parse it as a string.

---

# Known Issues & Debugging Notes (2026-09)

These notes come out of building a regression test for issue #126 (`issues/issue0126.rpgle`, which is the reproducer for everything below) and then reading the relevant source to explain what it found. Status as of 2026-09-21: #1 and #4 are fixed and rebuilt into the live `JSONXML` service program; #2 and #3 are confirmed but not yet fixed; #5 is half-fixed (one blocker removed, a second confirmed but not yet fixed); #6 is a test-design question, not a library bug.

## 1. `detectEncoding()` silently overrides an explicit `jx_ParseStringCcsid` CCSID — FIXED (2026-09-21)

`src/noxdb.c:1080-1108`, inside `detectEncoding()`, the JSON content-sniff does this:

```c
#pragma convert(277)
case  '['  :
case  '{'  :
case  '\"' :
case  '\'' :
  pJxCom->isJson = TRUE;
  InputCcsid = 277;
  done = TRUE;
  break;
```

This runs unconditionally, for *every* call to `jx_ParseString` (and therefore `jx_ParseStringCcsid`, which just pre-sets `InputCcsid` and delegates to `jx_ParseString` — see `src/noxdb.c:1908-1919`). It fires before the code ever looks at a caller-supplied CCSID or at the `BraBeg`/`CurBeg`/`Quot` globals that `jx_setDelimitersByCcsid()` had just correctly configured for that CCSID (`src/reader.c:89-149`) — those are only consulted in the `default:` branch, which this case never reaches.

Because `{` (and `"`, `[`) share the same byte value across most single-byte EBCDIC code pages (277, 500, etc. — they're part of the EBCDIC-invariant subset), this case matches for essentially all JSON input regardless of its real CCSID, and **unconditionally stomps `InputCcsid` back to 277**.

Net effect: an explicit `jx_ParseStringCcsid(buf, 500)` call is not reliable for JSON content — whatever CCSID you pass gets discarded the moment `detectEncoding` sees the leading `{`. Confirmed empirically: `issues/issue0126.rpgle`'s `json3 ccsid500` test tags a buffer as CCSID 500 end-to-end and calls `json_parseStringCcsid(...:500)` explicitly, and it still fails when the job runs under its native CCSID 277 — this is why.

**Fix applied and rebuilt (2026-09-21):** the hardcoded CCSID 277 case is gone, replaced with a check against `BraBeg`/`CurBeg`/`Quot`/`Apos` (JSON) and `LT` (XML) — whatever CCSID those currently reflect, ccsid-agnostically. A `callerCcsid` flag (captured before anything touches `InputCcsid`) also stops the downstream lines that used to unconditionally reset `InputCcsid` (for EBCDIC-XML and ASCII-JSON) from clobbering an explicit caller CCSID. Rebuilt into the live `JSONXML` service program and re-tested — see the "test methodology" finding (#6) below for what that test run actually revealed.

## 2. `jx_newWriter()` hardcodes the JSON writer's delimiters to the raw job CCSID, not `OutputCcsid`

`src/serializer.c:351-359` (`jx_newWriter`, used by `jx_AsJsonTextMem`/`jx_AsJsonStream`, i.e. `json_asJsonTextMem`):

```c
PJWRITE jx_newWriter ()
{
	PJWRITE pjWrite = malloc (sizeof(JWRITE));
	memset(pjWrite , 0 , sizeof(JWRITE) - sizeof(pjWrite->filler));
	#pragma convert(1252)
	XlateBufferQ(&pjWrite->braBeg , "[]{}\\\"" , 6, 1252 ,0 ); ;
	#pragma convert(0)
	return pjWrite;
}
```

The `0` target CCSID here is Xlate's "current job CCSID" sentinel — this translates the JSON structural characters (`[`, `]`, `{`, `}`, `\`, `"`) straight from CCSID 1252 to whatever CCSID the job happens to be running under *right now*, completely bypassing noxDB's own tracked `OutputCcsid` (which is what `initconst(OutputCcsid)` and `jx_WriteJsonStmf`'s `XlateOpenDescriptor(OutputCcsid, Ccsid, false)` consistently use elsewhere, e.g. `src/noxdb.c:1213`, `src/serializer.c:401`). Same pattern repeated at `src/serializer.c:232-236` (`jx_AsJsonStream`'s backwards-compat fallback) and `src/serializer.c:415-418` (`jx_WriteJsonStmf`).

This is a strong candidate for why `json_asJsonTextMem` output is job-CCSID-dependent (only round-trips correctly when the job runs at CCSID 500, matching the compile CCSID — see the comment already in `issues/issue0126.rpgle`: *"only works if job runs in ccsid 500 as compiled obj"*), while `jx_AsXmlTextMem` (`src/xmlserial.c`) does not exhibit the same dependency — it doesn't call anything with this ccsid-0-to-1252 pattern; its tag punctuation comes from plain C string literals in `sprintf` calls instead (`src/xmlserial.c:267-296` and friends), which are fixed at C-module compile time rather than looked up per call.

## 3. SQL round-trip of `ccsid(1208)` columns returns blank/corrupted data — still open, not yet traced into source

Empirically reproducible via `issues/issue0126.rpgle`: a `CLOB ccsid 1208` and a `VARCHAR(30) ccsid 1208` column both come back blank/corrupted immediately after `json_sqlInsert` + `json_sqlResultRow`, while sibling columns without an explicit CCSID (default job CCSID) round-trip correctly in the same row. This in turn breaks `json_WriteXmlStmf` for the whole row — the XML writer appears to abort after the corrupted field, silently dropping the remaining columns from the output document entirely (confirmed by inspecting the raw stream file: it contained only `<text1>` with `SUB` (0x1A) filler bytes, no `<row>` wrapper and no other fields at all).

**False lead retracted (2026-09-21):** an earlier note here said `text1`/`text2` passed under the loop's CCSID 500 pass. That was wrong — a self-inflicted bug, not a library behavior. While rewriting `issue0126.rpgle` for the CCSID loop, an editing tool's own JSON-string encoding silently turned the test's `'\uCE88\uCEB8...'` literal (a deliberate byte-wise pseudo-escape — see the Overview's `\uA1B2` convention) into real decoded Unicode characters, twice, without it being noticed at the time. Both sides of the `text1`/`text2` comparison ended up holding the same corrupted value, so the assert passed for the wrong reason. Fixed and re-verified: `text1`, `text2`, `json stmf text1`, and `xml stmf text1` all still fail, under **both** CCSID passes. This bug is confirmed still fully open. `src/sqlio.c` is still the next place to look.

## 4. `initconst()`'s static cache is exactly the "CHGJOB is never discovered" gap from the top of this document — FIXED (2026-09-21)

This is the mechanism behind the note in the Overview: *"noxDb loads the default parser constants when the JSONXML service program is invoked by querying the job CCSID at that time. If the user - after that point - issues a CHGJOB CCSID(xxx) - this change is never discovered."* Traced to a specific static cache, not just a general impression:

```c
// src/reader.c:153-162
void initconst(int ccsid)
{
   static int prevccsid = -1;  // can not be negative => force rebuild const
   if ( prevccsid == ccsid) return;
   prevccsid = ccsid;
   jx_setDelimitersByCcsid (ccsid);
}
```

`detectEncoding()` calls `initconst(OutputCcsid)` on every parse (`src/noxdb.c:1213`). `OutputCcsid` is a global that starts at `0` and is only ever reset back to `0` or explicitly overwritten by `jx_SetCcsid()`/`json_SetCcsid()` (`src/noxdb.c:1757-1761,1895,1993`) — nothing in the normal parse/serialize path ever sets it to a concrete CCSID. So in the common case `initconst` is called with the literal value `0` every single time, where `0` is Xlate's "current job CCSID" sentinel (same convention as finding #2).

The bug is that `prevccsid` caches the **sentinel**, not the **resolved CCSID**. The first call ever made (`prevccsid == -1`) lets `0` through to `jx_setDelimitersByCcsid(0)`, which calls `XlateGetStaticConversionTables(..., 0)` — and *that's* the one moment the real, current job CCSID gets baked into `e2aTbl`/`a2eTbl` and the derived globals (`BraBeg`, `CurBeg`, `Quot`, etc.). From then on, `prevccsid` is `0`, so every later call — even after a genuine `CHGJOB CCSID(...)` changes what "current job CCSID" actually resolves to — sees `ccsid == prevccsid` (`0 == 0`) and returns immediately without rebuilding anything. There is no reset path anywhere in the codebase (confirmed: `prevccsid` is referenced only inside this one function).

This lines up with the `issue0126.rpgle` two-pass loop: pass 1 (CCSID 500) is the very first noxDB call this job ever makes, so it's the one that gets to set `prevccsid` and correctly bake in CCSID 500's tables. Pass 2's `CHGJOB CCSID(277)` then genuinely changes the job, but `initconst` never notices — noxDB keeps operating on CCSID 500's cached tables while everything else in the job has moved to 277.

**Fix applied and rebuilt (2026-09-21):** `initconst()` no longer caches at all — it always calls `jx_setDelimitersByCcsid(ccsid)`. That function only rebuilds a couple of small, fixed-size SBCS lookup tables and runs once per parse (not once per character), so always rebuilding is cheap enough that the cache wasn't buying much against the cost of silently freezing state across a `CHGJOB`. Checked first whether anything relies on the frozen-after-first-call behavior before removing it — see finding #1's fix, which had to be done together with this one for exactly that reason (`jx_ParseStringCcsid` was accidentally relying on the cache *not* firing to keep its explicit override alive through the rest of the same parse call). Rebuilt into the live `JSONXML` service program (`gmake current SRC=src/reader.c MODULE=reader`) and re-tested — see finding #6 for what that revealed.

## 5. BOM-less big-endian UTF-16 input is unparseable — a lone `'\0'` byte is (wrongly) treated as "empty input"

**Correction (2026-09-21):** originally attributed this to `detectEncoding()`'s `case '\0':`. That's the right *shape* of bug but the wrong *location* — tracing it further back, the actual first blocker is one level up, in `jx_ParseString()`'s own leading guard (`src/noxdb.c:1851`, before `detectEncoding` is ever called):

```c
if (Buf == NULL || *Buf == '\0' ) {
    return NULL;
}
```

In UTF-16BE, an ASCII-range character is encoded `[0x00][ascii byte]` (high byte first) — so a document starting `<?xml ...` begins with the raw byte **0x00**. `jx_ParseString` sees `*Buf == '\0'` and returns `NULL` immediately, before `detectEncoding` (and its own, structurally identical `case '\0':` bail-out a bit further down the same code path) ever runs. `substr()` (`src/ext/utl100.c:373`) does a raw `memcpy`, so `Buf[1]` (the real next byte, e.g. `0x3C` for `<`'s low byte) is legitimate to read here — it was never actually a genuine end of input.

**Fix applied and rebuilt (2026-09-21):** both spots now require *two* adjacent null bytes before treating input as genuinely empty — matching how every caller already null-terminates buffers twice (`jx_ParseFile`'s `pStreamBuf[len]='\0'; pStreamBuf[len+1]='\0';`, and the `+ x'00'` convention used in `issue0126.rpgle`'s `%addr(...:*data)` calls). `jx_ParseString`'s guard is now `*Buf == '\0' && *(Buf+1) == '\0'`; `detectEncoding`'s scan-loop `case '\0':` now only bails out under the same two-null condition, otherwise falls through and keeps scanning (so a mid-document high byte — not just the very first one — is handled the same way). Also fixed the bare `return;` (undefined behavior in a function declared `PUCHAR`) to `return NULL;` while touching that line.

UTF-16LE never hit either guard: its byte order is `[ascii byte][0x00]`, so the first byte of `<?xml ...` is the printable `<` (0x3C), not `\0`. `unicodeLE-nobom.xml` passed both before and after this fix.

**Confirmed, not just reasoned through (2026-09-21): a second, separate bug is right behind this one and is still blocking `unicodeBE-nobom.xml`.** The `'\0'` fix alone didn't unblock it — re-tested after rebuilding and `unicodeBE -bom load`/`serialise` still fail under both CCSID passes. Added temporary debug: `json_parseFile()` on it now returns a non-null node with no error flag set (`json_error()` is `*off`, `json_message()` is empty) — so parsing itself no longer bails out — but `json_getStr(pDoc:'/A/B')` comes back empty, meaning the resulting tree doesn't actually have the expected `/A/B` structure. That's consistent with the LE/BE disambiguation bug suspected here:

```c
if (*(p+1) == 0x00) { // Little endian
  ...
} else if (p > buf && *(p-1) == 0x00) { // UNICODE big endian
  ...
}
```

For BOM-less BE content, once the character right after the matched delimiter (e.g. `?` after `<`) is *also* in the ASCII range — true for essentially every real document — `*(p+1)` lands on *that next character's own* BE high byte, which is `0x00` too. Since the LE check runs first, this misdetects genuine big-endian content as little-endian, and the parser then tries to byte-swap/decode BE bytes as if they were LE — garbage in, structurally-valid-but-wrong tree out. Not yet fixed — the byte arithmetic needs care (this note already got the location wrong once, in the original version of this finding) and deserves its own dedicated pass rather than a quick follow-on edit.

## 6. The library fixes work — confirmed at the byte level — but `issue0126.rpgle` can't validate the CCSID 277 pass the way it's written

After rebuilding with #1 and #4's fixes, the CCSID 277 pass in `issue0126.rpgle` still fails almost everything — at first glance looking like the fixes hadn't done anything. Tracing one failure (`xml1a`) all the way down showed the opposite:

`xml1a` parses Greek text and asserts the re-serialised XML equals the literal `'<test>&#x0388;...</test>'`. Under CCSID 277 it still failed, byte lengths matched (69 both sides), so a temporary position-by-position diff was added. It found the mismatch at position 8 — the `#` character — with the actual byte `74` (decimal) against the expected literal's `123`. Those are exactly the known CCSID 277 (Danish/Norwegian EBCDIC) vs. CCSID 500 (International EBCDIC) byte values for `#` — one of the classic "national use" substitution characters that differs between EBCDIC country variants.

In other words: **`json_asXmlTextMem` is now correctly emitting `#` in the job's real, current CCSID (277)** — exactly what #1's fix was for. The assert still fails only because `issue0126.rpgle`'s expected-value literals are RPG string constants, compiled once at CCSID 500 (`issues/Makefile`'s `CCSID=500`), and a compile-time literal used directly in a comparison expression does not get re-converted to match a CCSID the job switched to *after* compilation via `CHGJOB`. So the test is comparing "real CCSID 277 output" against "a CCSID 500 literal, unconverted" — a mismatch the test itself manufactures, not a library bug.

This explains the whole broad CCSID 277 failure list at once: everything that compares live output against a fixed literal (`xml1a`, `xml1b`, `json1`, `json2`, `json3`, and all the `checkTestFile` file checks comparing against `'Smørrebrødspålæg'`) is subject to the same effect, since `Ø`/`Æ`/`Å` are *also* EBCDIC country-variant characters. `xml2a`/`xml2b` are the exception that proves it: those compare two runtime *variables* (`toParseE` vs the output), never a literal, and they pass under both passes.

**Not a library bug — a test design question**, left open rather than acted on unilaterally: should `issue0126.rpgle`'s multi-CCSID assertions compare against something CCSID-aware instead of a fixed literal (e.g. re-derive the expected string the same way the input was built, or tag the literals `ccsid(500)` and explicitly convert before comparing)? Worth deciding deliberately next time this is picked up, rather than guessing at a fix inline.

**Resolved (2026-09-21):** answered by adding an explicit `targetCcsid` parameter to the in-memory serializers — see the new section below. `xml1a`'s `'<test>&#x0388;...` assert still fails under the CCSID 277 pass (that's now *expected* — it's deliberately showing "job CCSID" behavior), but a second assert added right after it, using the same call pinned to CCSID 500 explicitly, passes under **both** CCSID passes. That's the general answer for the rest of this finding's failure list too (`xml1b`, `json1`, `json2`, `json3`, and the `checkTestFile` checks) — not yet applied to all of them, done for `xml1a` only as the proof.

# Explicit target CCSID for in-memory serializers (2026-09-21)

Added an optional trailing `targetCcsid` parameter (default/omitted = `0` = current job CCSID, i.e. exactly today's behavior) to the five in-memory/return-value serializers, so a caller can pin the output CCSID explicitly instead of always getting whatever the job happens to be running under:

- `jx_AsJsonTextMem` / `json_asJsonTextMem` / `xml_asJsonTextMem`
- `jx_AsJsonText16M` / `json_AsJsonText16M` / `xml_AsJsonText16M`
- `jx_AsJsonText` / `json_asJsonText` / `xml_asJsonText`
- `jx_AsXmlTextMem` / `json_asXmlTextMem` / `xml_asXmlTextMem`
- `jx_AsXmlText` / `json_asXmlText` / `xml_asXmlText`

**Why an explicit parameter, not caller-CCSID auto-detection:** call-stack CCSID detection is exactly what the Overview's own "Determining the CCSID of the Calling Application" section already flags as unreliable — IBM's docs are vague on it, and a multi-level chain (`PGMA(277)→PGM5(500)→NoxDB`) has no single unambiguous "the caller's ccsid." An explicit parameter has no such ambiguity, and it's not a new API shape: `jx_WriteJsonStmf`/`jx_WriteXmlStmf` (the file writers) already work exactly this way — this just brings the in-memory path in line with the file path.

**Implementation:** the parameter drives `jx_setDelimitersByCcsid(resolvedCcsid)` (save the current delimiters first, restore them after), the same mechanism `jx_ParseStringCcsid` already used for parsing. `jx_newWriter()` — the root of finding #2 — no longer does its own independent `XlateBufferQ(...,1252,0)`; it now reads `BraBeg`/`BraEnd`/`CurBeg`/`CurEnd`/`BackSlash`/`Quot` (whatever `jx_setDelimitersByCcsid` last set), so an explicit `targetCcsid` reaches it too instead of being silently overridden. This closes finding #2 as a side effect.

**Scope, deliberately**: this controls the *structural/punctuation* characters noxDB itself generates (`{`, `}`, `[`, `]`, `"`, `\`, `#` in XML's `&#xHHHH;` refs) — not the node *value* content, which is copied byte-for-byte as before. Re-encoding arbitrary stored value content to a different target CCSID is a materially bigger change (would need iconv on every value during serialization) and isn't what today's failures needed — the existing `\uXXXX`-escape-at-storage-time convention already makes value content CCSID-portable for the common case.

**Backward compatibility:** every internal caller (`noxdb.c`, `sqlio.c` — 8 call sites) was updated to pass `0` explicitly, since C has no default-argument mechanism the way RPG's `options(*nopass)` does for its own callers; RPG callers that don't pass the new parameter get identical behavior to before (confirmed: rebuilt and re-ran `issue0126.rpgle` *before* touching the test at all — identical failure list, same 31 asserts, same names, same passes, zero regressions). `headers/JSONXML.rpgle` is the actual source of truth for the RPG prototypes (`headers/NOXDB.rpgle`/`JSONPARSER.rpgle`/`XMLPARSER.rpgle` are generated from it by `gmake hdr`, which also deploys to the `QRPGLEREF` source member the compiler actually reads — editing the generated files directly would've been silently overwritten).

**Proof it works**: added a second `xml1a`-shaped assert to `issue0126.rpgle`, identical except it calls `json_asXmlTextMem(pInput : %addr(...) : 500)` with the ccsid pinned explicitly. It passes under **both** CCSID passes, while the original (unpinned, job-CCSID-dependent) `xml1a` assert still fails under CCSID 277 exactly as finding #6 explains.

**Rolled out to the rest of finding #6's failure list (2026-09-21)** — mixed results, all now precisely understood rather than just "still red":

- **Fixed**: `xml1b`, `json1` (both pinned variants pass under both CCSID passes), and `checkTestFile`'s `'... serialise'` asserts for all 7 test files (pins both the serialise step *and* the re-parse of its own output to CCSID 500 via `json_parseStringCcsid`).
- **Not fixable in this scope**: `checkTestFile`'s `'... load'` asserts, and `json3 ccsid500`. `checkTestFile`'s `'... load'` compares `json_getStr()`'s extracted value against a literal — `json_getStr` isn't one of the five functions `targetCcsid` was added to, and tagging the *comparison variable* `ccsid(500)` instead (the same trick used for `Danish500`/`toParseC`) does **not** help — confirmed by testing it, not assumed; RPG apparently doesn't reconvert either operand to match after a `CHGJOB`. `json3 ccsid500` fails for the plainer, already-documented reason: `json_parseStringCcsid(...:500)` correctly converts its Danish value to the job's real CCSID (277) while parsing, so pinning only the punctuation to 500 afterwards produces a genuine 277/500 byte mix that a pure-500 literal can't match — exactly what the `targetCcsid` scope note already says it won't fix.
- **A new, unrelated bug found**: `json2 ccsid500 pinned` — and, it turned out, the *unpinned* `json2` too. See finding #7.

First real gotcha hit while rolling this out, worth remembering for next time: `json_asJsonTextMem` has *two* trailing optional parameters (`bufferSize` then `targetCcsid`). Passing `: 500` as the 3rd argument silently fills `bufferSize`, not `targetCcsid` — RPG doesn't skip a supplied-but-omitted middle parameter automatically. `*OMIT` doesn't work as a placeholder either unless that parameter was declared `options(*omit)` (`bufferSize` is only `options(*nopass)`) — the fix was to pass the real buffer size explicitly (`%size(xmlBugBufds.buf)`) instead of trying to skip it.

## 7. `json2` truncates under CCSID 277 — a compiled national character collides with a JSON structural byte during *parsing*, not serialising

**Corrected (2026-09-22)** — the first version of this finding blamed `jx_EncodeJsonStream`'s per-byte escape comparisons in the serialiser. That was a plausible-sounding guess that turned out wrong; tracing it properly with temporary `joblog()` instrumentation in `jsonStreamPrintObject`/`jx_AsJsonTextMem` (not just watching from the RPG side) found the real mechanism, and it isn't in the serialiser at all.

**The actual cause:** `Danish` and `toParseE` (`issue0126.rpgle`) are built from compile-time CCSID-500 literals — and per finding #6, RPG never reconverts those to the job's real CCSID after a runtime `CHGJOB`. Dumping `Danish`'s raw bytes confirmed they're **byte-for-byte identical** across both the CCSID 500 and CCSID 277 passes: `226 148 112 153 153 133 130 153 112 132 162 151 71 147 156 135` — still CCSID 500's encoding of "Smørrebrødspålæg", every time, regardless of what `CHGJOB` just did.

Byte 13 in that list — CCSID 500's `å` — is **71**. Separately dumping `jsonStreamPrintObject`'s `PJWRITE` fields for the *unpinned* call under the CCSID 277 pass showed `curEnd=71` — CCSID 277's closing `}`. Same byte.

So `toParseE`, when the job is genuinely at CCSID 277, is content that's actually still 100% CCSID-500-encoded, being parsed by `json_ParseString` under CCSID-277 assumptions (`InputCcsid` defaults to `0`/job, i.e. 277, since nothing tells it otherwise). Somewhere in that parse, the `å` byte — meant to be sitting inside the quoted Danish value — gets read as CCSID 277's `}` and the object closes early. Confirmed this happens at **parse** time, not serialize time: both the pinned *and* unpinned `json_asJsonTextMem` calls on the exact same `pInput` come back short (length 7, `{"test"` — cut off before the colon), which only makes sense if the tree was already truncated before either serialize call ran.

This is downstream of finding #6, not a new independent bug, but a materially worse symptom of it — finding #6 was "compares wrong", this is "parses wrong, tree is short, everything downstream is just faithfully reporting a broken tree." `json3` avoids it because `json_parseStringCcsid(...:500)` tells the parser the true CCSID explicitly, so it correctly iconv-converts the value to CCSID 277 during parsing (`InputCcsid` 500 ≠ `OutputCcsid` 277) instead of misreading raw CCSID-500 bytes as CCSID-277 structural characters.

Not fixed — this is arguably a `json_ParseString`/`detectEncoding` robustness question (should a byte inside an already-open quoted string ever be read as a structural delimiter, regardless of *why* the string contains that byte?), and it's tangled together with finding #6's separate, already-flagged "literal doesn't reconvert" RPG limitation. Left open for a dedicated look. `json2`/`json2 ccsid500 pinned` remain honestly-failing, now-understood entries in `issue0126.rpgle` rather than hidden or worked around.

## 8. HTTP/streaming path regression test added (2026-09-21) — `issues/issue0126-http.sh`

`issue0126.rpgle` only ever exercised SQL, the in-memory serializers (`json_asXmlTextMem`/`json_asJsonTextMem`) and the IFS `Stmf` writers — never `src/ext/stream.c`'s `PSTREAM` abstraction (`jx_Stream`/`jx_AsJsonStream`, 4096-byte buffer flushed via a writer callback — the mechanism behind finding #2 above). The only thing that actually drives that code path is the live IceBreak HTTP echo server: its response comes back `Transfer-Encoding: chunked`, one chunk per `PSTREAM` buffer flush. A plain `.rpgle` test can't reach it (no HTTP client), so this is a separate shell script, not more RPG.

Two real ICE server jobs already exist for this, one per CCSID — `SYSTES277` (port 60277) and `SYSTES500` (port 60500) — each exposing `/echoxml` and `/echojson`. `issues/issue0126-http.sh` drives both over real HTTP with `curl`, covering per server/endpoint: an SBCS (Danish, mappable) round trip, an unmappable-Greek escape round trip (same `&#xHHHH;`/`\uHHHH` escaping as `xml1a`/`json1`), and a streaming-boundary case — 2000 repeats of an escaped Greek character (8 bytes XML / 6 bytes JSON per repeat, neither divides 4096 evenly) specifically to force an escape sequence to straddle a `stream_write()` flush boundary, which a single contiguous in-memory buffer never has to handle. All 12 cases pass on both CCSIDs — confirms the streaming/chunked path has no CCSID or buffer-boundary bugs the in-memory path's tests wouldn't already have caught.

**Gotcha hit again while writing it:** a literal `Α`-style escape typed directly into the script's own source (both in test data and, separately, in a comment) got silently decoded into a real Unicode character by the editing tool before the file was ever saved — same failure mode already logged in this project's build-system notes. Worked around by building the backslash programmatically (`chr(92)`) instead of typing a literal backslash-u sequence anywhere in the tool call.

## Tooling for next time

- `src/trace.clle` + a `SQLTRACE` data area next to the `JSONXML` service program look like a built-in SQL trace facility — not yet explored how to enable/read it.
- Debugging on `MY_IBM_I` this round meant a hand-rolled `SBMJOB` → `DSPJOBLOG OUTPUT(*PRINT)` → `CPYSPLF ... TOSTMF` → `iconv` round trip just to see joblog output. Worth building a small reusable script for "compile, run, dump joblog as UTF-8" instead of redoing this by hand each time.
- `issue0126.rpgle` now switches CCSID *itself* at runtime (`QCMDEXC('CHGJOB CCSID(...)')`) and runs its whole test body once per CCSID (500, then 277), tagging `ASSERT FAILED` messages with which pass they're from. No more manually wrapping the `CALL` in a CL program that does `CHGJOB` first — one `CALL PGM(NOXDB/ISSUE0126)` now covers both CCSID contexts in a single job. Worth reusing this pattern (a `chgJobCcsid()`-style helper + a `doTest()` called in a loop) in other CCSID-sensitive regression tests.

---

# Future Direction

The `main` branch attempts to solve the SBCS/Unicode storage problem by storing **all graph data internally as UTF-8**.

However, this changes the internal representation and is therefore **not backward-compatible** with the `master` / Classic implementation.

The intended long-term solution should therefore be a new version that combines:

* All features currently available in the Classic (`master`) implementation.
* The UTF-8 internal representation from the `main` branch.
* No SBCS-specific Unicode escaping inside the graph.
* A CCSID-agnostic API for client applications.

In other words, the next version should retain the complete Classic feature set while changing the internal representation so that **UTF-8 is used throughout the graph instead of the current job CCSID with escaped Unicode characters**.
