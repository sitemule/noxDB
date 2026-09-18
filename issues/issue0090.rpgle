**free
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

/include 'headers/jsonxml.rpgle'

dcl-s pTree           Pointer;
dcl-s xmlText   varchar(1024);
dcl-s jsonText   varchar(1024);

    *INLR = *ON;

    pTree  = jx_parseString(
        '<root>' +
            '<elm1>abc</elm1>' +
            '<elm2>123</elm2>' +
            '<elm3/>' +
        '</root>'
    );

    // result is still the original string ok
    xmlText = jx_asXmlText(pTree);
    jx_joblog (xmlText);

    // - no attributes supported,
    // - no duplicate names supported.
    // But elements occurs OK now:
    jsonText = jx_asJsonText(pTree);
    jx_joblog (jsonText);

    // Cleanup
    jx_delete(pTree);


Return;