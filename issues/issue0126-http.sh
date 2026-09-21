#!/usr/bin/env bash
# -------------------------------------------------------------
# issue0126-http.sh - regression test for the noxDB "streamer"
#
# issue0126.rpgle exercises SQL round-trips, the in-memory
# serializers (json_asXmlTextMem/json_asJsonTextMem) and the IFS
# stream-file writers (json_WriteXmlStmf/json_WriteJsonStmf).
# None of those go through src/ext/stream.c's PSTREAM abstraction
# (jx_Stream / jx_AsJsonStream, 4096-byte buffer, flushed via a
# writer callback - see design.md finding #2 and src/serializer.c).
#
# The only place that code path actually runs is the live IceBreak
# HTTP echo server: it writes its response with
# "Transfer-Encoding: chunked", one chunk per PSTREAM buffer flush.
# This script drives that server directly over HTTP so the flush/
# writer-callback loop in stream_write() (src/ext/stream.c) is what
# actually produces every response byte we check here - a plain
# .rpgle test can't reach this path since it has no HTTP client.
#
# Two ICE server instances run the same noxDB service program under
# different job CCSIDs, exactly like issue0126.rpgle's two-pass
# CHGJOB loop, but as two real jobs instead of one job switching CCSID:
#   ccsid277 -> http://$HOST:60277  (SVRID SYSTES277)
#   ccsid500 -> http://$HOST:60500  (SVRID SYSTES500)
# Each exposes /echoxml and /echojson: parse the posted body, then
# serialize it straight back out.
#
# Usage: ./issue0126-http.sh   (HOST env var overrides the default host)
# -------------------------------------------------------------
set -u

HOST="${HOST:-my_ibm_i}"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

PASS=0
FAIL=0

# ------------------------------------------------------------------
# post REQFILE to $HOST:PORT/PATH with the given Content-Type,
# save the raw response body to RESPFILE.
# ------------------------------------------------------------------
post() {
    local port="$1" path="$2" contentType="$3" reqfile="$4" respfile="$5"
    curl -sS -X POST \
        -H "Content-Type: ${contentType}" \
        --data-binary "@${reqfile}" \
        -o "${respfile}" \
        "http://${HOST}:${port}/${path}"
}

# ------------------------------------------------------------------
# compare RESPFILE to EXPFILE byte-for-byte and report.
# ------------------------------------------------------------------
check() {
    local label="$1" respfile="$2" expfile="$3"
    if cmp -s "${respfile}" "${expfile}"; then
        PASS=$((PASS + 1))
        echo "PASS: ${label}"
    else
        FAIL=$((FAIL + 1))
        echo "FAIL: ${label}"
        echo "  expected ($(wc -c < "${expfile}") bytes) vs actual ($(wc -c < "${respfile}") bytes):"
        diff <(xxd "${expfile}") <(xxd "${respfile}") | head -6 | sed 's/^/  /'
    fi
}

# ------------------------------------------------------------------
# SBCS round trip - Danish text is mappable in both ccsid 277 and
# ccsid 500 (design.md Overview), so it should come back byte-for-
# byte identical UTF-8, same as this file's issue0126.rpgle xml2a/
# json2-shaped asserts, but now via a real CP1252 HTTP POST decoded
# server-side instead of an in-process RPG variable.
# ------------------------------------------------------------------
test_sbcs_roundtrip() {
    local ccsidLabel="$1" port="$2" kind="$3"   # kind: xml | json
    local reqfile="${TMPDIR}/req" respfile="${TMPDIR}/resp" expfile="${TMPDIR}/exp"

    if [ "$kind" = "xml" ]; then
        python3 -c "import sys; sys.stdout.buffer.write('<test>Smørrebrødspålæg</test>'.encode('cp1252'))" > "${reqfile}"
        printf '%s' '<test>Smørrebrødspålæg</test>' > "${expfile}"
        post "$port" echoxml "application/xml; charset=windows-1252" "${reqfile}" "${respfile}"
    else
        python3 -c "import sys; sys.stdout.buffer.write('{\"test\":\"Smørrebrødspålæg\"}'.encode('cp1252'))" > "${reqfile}"
        printf '%s' '{"test":"Smørrebrødspålæg"}' > "${expfile}"
        post "$port" echojson "application/json; charset=windows-1252" "${reqfile}" "${respfile}"
    fi

    check "${ccsidLabel} ${kind} sbcs roundtrip" "${respfile}" "${expfile}"
}

# ------------------------------------------------------------------
# Unmappable-character round trip - Greek is not representable in
# either ccsid 277 or ccsid 500, so both servers must escape it the
# same way noxDB's in-memory serializers already do (xml1a/json1 in
# issue0126.rpgle): &#xHHHH; for XML, \uHHHH for JSON. Sent as plain
# UTF-8 (no iconv - UTF-8 is JSON's/detectEncoding's implicit
# default per design.md's "JSON Encoding" section).
# ------------------------------------------------------------------
test_unmappable_roundtrip() {
    local ccsidLabel="$1" port="$2" kind="$3"
    local reqfile="${TMPDIR}/req" respfile="${TMPDIR}/resp" expfile="${TMPDIR}/exp"

    if [ "$kind" = "xml" ]; then
        printf '%s' '<test>Αθήνα</test>' > "${reqfile}"
        printf '%s' '<test>&#x0391;&#x03B8;&#x03AE;&#x03BD;&#x03B1;</test>' > "${expfile}"
        post "$port" echoxml "application/xml; charset=utf-8" "${reqfile}" "${respfile}"
    else
        printf '%s' '{"test":"Αθήνα"}' > "${reqfile}"
        # Built via chr(92) rather than a literal backslash-u sequence in
        # this script's own source: an earlier draft embedded the JSON
        # escape text directly here and it was silently decoded into a
        # real Unicode character by the editing tool before ever reaching
        # the shell - the exact gotcha noted in this project's
        # build-system notes.
        python3 -c "
import sys
bs = chr(92)
codepoints = [0x0391, 0x03B8, 0x03AE, 0x03BD, 0x03B1]
esc = ''.join(bs + 'u%04X' % cp for cp in codepoints)
sys.stdout.buffer.write(('{\"test\":\"' + esc + '\"}').encode('utf-8'))
" > "${expfile}"
        post "$port" echojson "application/json; charset=utf-8" "${reqfile}" "${respfile}"
    fi

    check "${ccsidLabel} ${kind} unmappable roundtrip" "${respfile}" "${expfile}"
}

# ------------------------------------------------------------------
# Streaming boundary test - the actual point of this file. The HTTP
# writer flushes every 4096 bytes (stream_new(4096) in
# src/serializer.c's jx_Stream/jx_AsJsonStream). A single escaped
# Greek "Α" is 8 bytes as an XML numeric reference (&#x0391;) or 6
# bytes as a JSON unicode escape, neither of which evenly divides
# 4096, so repeating it guarantees some escape
# sequence straddles a flush boundary - exactly the case
# stream_write()'s memcpy-based split loop (src/ext/stream.c) has to
# get right that a single contiguous in-memory buffer
# (json_asXmlTextMem/json_asJsonTextMem) never needs to. 2000 reps
# pushes the XML response past 16KB and the JSON response past 12KB,
# crossing that 4096 boundary multiple times over.
# ------------------------------------------------------------------
test_streaming_boundary() {
    local ccsidLabel="$1" port="$2" kind="$3"
    local reqfile="${TMPDIR}/req" respfile="${TMPDIR}/resp" expfile="${TMPDIR}/exp"
    local reps=2000

    if [ "$kind" = "xml" ]; then
        python3 -c "
import sys
body = 'Α' * ${reps}
sys.stdout.buffer.write(('<test>' + body + '</test>').encode('utf-8'))
" > "${reqfile}"
        python3 -c "
import sys
esc = '&#x0391;' * ${reps}
sys.stdout.buffer.write(('<test>' + esc + '</test>').encode('utf-8'))
" > "${expfile}"
        post "$port" echoxml "application/xml; charset=utf-8" "${reqfile}" "${respfile}"
    else
        python3 -c "
import sys
body = 'Α' * ${reps}
sys.stdout.buffer.write(('{\"test\":\"' + body + '\"}').encode('utf-8'))
" > "${reqfile}"
        python3 -c "
import sys
esc = (chr(92) + 'u0391') * ${reps}
sys.stdout.buffer.write(('{\"test\":\"' + esc + '\"}').encode('utf-8'))
" > "${expfile}"
        post "$port" echojson "application/json; charset=utf-8" "${reqfile}" "${respfile}"
    fi

    check "${ccsidLabel} ${kind} streaming boundary (${reps} reps)" "${respfile}" "${expfile}"
}

for pair in "ccsid277:60277" "ccsid500:60500"; do
    label="${pair%%:*}"
    port="${pair##*:}"
    for kind in xml json; do
        test_sbcs_roundtrip "${label}" "${port}" "${kind}"
        test_unmappable_roundtrip "${label}" "${port}" "${kind}"
        test_streaming_boundary "${label}" "${port}" "${kind}"
    done
done

echo "-------------------------------------------------"
echo "PASS=${PASS} FAIL=${FAIL}"
[ "${FAIL}" -eq 0 ]
