**FREE
// ------------------------------------------------------------------------------------
// noxDB - Not Only Xml - Its JSON, XML, SQL and more
//
// Demo 90 - call any program or service program procedure with JSON
//
// nox_CallProgram and nox_CallProcedure read the parameter list (PCML) that
// is stored in the object when it is compiled with pgminfo(*PCML:*MODULE),
// map a JSON object onto the parameters by name, call it, and give the
// inputoutput parameters back as a new JSON object.
// That is all it takes to put an existing program behind a REST service.
//
// Good to know:
//   - Names match regardless of case. RPG writes them in upper case, so the
//     result has upper case names: { "QUOTE": { "TOTAL": ... } }
//   - Only inputoutput parameters come back; const / value ones are input.
//   - Any type: char, varchar, int, uns, packed, zoned, date (*ISO, *EUR,
//     *USA, *JIS, *YMD, *DMY, *MDY), time, timestamp (ISO 8601 accepted),
//     indicators, data structures, arrays and arrays of structures.
//   - An array with a sibling named <array>_LENGTH returns only that many.
//   - The graph is UTF-8; the parameters are in the job CCSID, so national
//     characters survive both ways.
//   - An indicator is char(1) in the PCML, so it comes back as "1" / "0".
//   - Both PCML versions work: pgminfo(*PCML:*MODULE) gives 6.0 on 7.3,
//     pgminfo(*PCML:*MODULE:*V7) gives 7.0 (varchar with its length).
//   - A program that is not found, or has no PCML, gives *null and the
//     reason in nox_Message().
//
// try/build:
// cd '/prj/NOXDBUTF8'
// addlible NOXDBUTF8
// chgjob ccsid(500)
// gmake examples/ex90Pgm.rpgle examples/ex90Srv.rpgle examples/ex90Call.rpgle --always-make
// CRTSRVPGM SRVPGM(NOXDBUTF8/EX90SRV) MODULE(NOXDBUTF8/EX90SRV) EXPORT(*ALL)
// call ex90Call
// ... then see the job log and /tmp/ex90-*.json
// ------------------------------------------------------------------------------------
Ctl-Opt copyright('Sitemule - System & Method (C), 2026');
Ctl-Opt BndDir('NOXDBUTF8') CCSID(*CHAR:*JOBRUN);
Ctl-Opt dftactgrp(*NO) ACTGRP('QILE') option(*nodebugio:*srcstmt:*nounref);
Ctl-Opt main(main);

/include qrpgleref,noxDbUtf8

// ------------------------------------------------------------------------------------
dcl-proc main;

    dcl-s pParms   pointer;
    dcl-s pResult  pointer;
    dcl-s pMeta    pointer;
    dcl-s total    packed(13:2);
    dcl-s msg      char(52);

    // Step 1: Build the parameters as a graph and call the program
    // The names are the parameter names of EX90PGM; case does not matter
    pParms = nox_Object(
        'customer'  : nox_Str('Blåbærgården ApS') :
        'quantity'  : nox_Int(250) :
        'price'     : nox_Dec(12.50) :
        'firstDate' : nox_Str('2026-12-01')
    );

    pResult = nox_CallProgram('*LIBL' : 'EX90PGM' : pParms);
    nox_delete(pParms);

    if pResult = *null;
        msg = nox_Message();
        dsply msg;
        return;
    endif;

    // { "QUOTE": { "CUSTOMER": "Blåbærgården ApS", "TOTAL": 3125.00,
    //              "DELIVERIES": [ {"DATE":"2026-12-01","QUANTITY":100,"AMOUNT":1250.00}, ... 3 ] } }
    nox_WriteJsonStmf(pResult : '/tmp/ex90-quote.json' : 1208 : *off);
    total = nox_GetDec(pResult : 'quote/total');
    nox_joblog('Quote total: ' + %char(total));
    nox_joblog('Deliveries: ' + %char(nox_GetLength(nox_Locate(pResult : 'quote/deliveries'))));
    nox_delete(pResult);

    // Step 2: The parameters can also be a JSON string
    pResult = nox_CallProgram('*LIBL' : 'EX90PGM' :
        '{"customer":"Ærø Is","quantity":40,"price":9.95,"firstDate":"2027-01-04"}');
    nox_WriteJsonStmf(pResult : '/tmp/ex90-quote2.json' : 1208 : *off);
    nox_delete(pResult);

    // Step 3: A procedure in a service program
    pResult = nox_CallProcedure('*LIBL' : 'EX90SRV' : 'GREETING' :
        '{"name":"Søren","language":"da"}');
    nox_joblog(nox_GetStr(pResult : 'text'));    // Hej Søren - velkommen på Ærø
    nox_delete(pResult);

    // Step 4: The interface itself, as JSON - e.g. to generate an OpenAPI description
    pMeta = nox_ApplicationMeta('*LIBL' : 'EX90PGM' : *null);
    nox_WriteJsonStmf(pMeta : '/tmp/ex90-meta.json' : 1208 : *off);
    nox_delete(pMeta);

    // Step 5: Errors give *null and a message - no exception
    pResult = nox_CallProgram('*LIBL' : 'NOSUCHPGM' : '{}');
    if pResult = *null;
        nox_joblog('As expected: ' + nox_Message());
    endif;

end-proc;
