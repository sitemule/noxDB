**free
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
// Unicode BOM code LE is not recognized:

/include 'headers/jsonxml.rpgle'

dcl-s pTree           Pointer;
dcl-s xmlText   varchar(1024);

    *INLR = *ON;

    // Little endian
    pTree  = jx_parseFile ('/prj/noxdb/testdata/unicodeLE.xml');
    xmlText = jx_asXmlText(pTree);
    jx_joblog (xmlText);
    jx_delete(pTree);

    // Big endian
    pTree  = jx_parseFile ('/prj/noxdb/testdata/unicodeBE.xml');
    xmlText = jx_asXmlText(pTree);
    jx_joblog (xmlText);
    jx_delete(pTree);

    // windows-1252 and file is ccsid is 1252
    pTree  = jx_parseFile ('/prj/noxdb/testdata/simple1.xml');
    xmlText = jx_asXmlText(pTree);
    jx_joblog (xmlText);
    jx_delete(pTree);

    // UTF-8 but file ccsid is 1252
    pTree  = jx_parseFile ('/prj/noxdb/testdata/deliverynote.xml');
    xmlText = jx_asXmlText(pTree);
    jx_joblog (xmlText);
    jx_delete(pTree);

    // UTF-8 with BOM - json
    pTree  = jx_parseFile ('/prj/noxdb/testdata/simple.json');
    xmlText = jx_asJsonText(pTree);
    jx_joblog (xmlText);
    jx_delete(pTree);

Return;