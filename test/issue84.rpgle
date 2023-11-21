**free
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

/include 'headers/jsonparser.rpgle'

dcl-s pJson        pointer;
dcl-s jsonNodePtr  pointer;
dcl-s size         varchar(10);

pJson = json_parseString('{"size":null}');

// This works
size = json_getStr ( pJson : 'size': '0');

// This fails
jsonNodePtr = json_Locate( pJson : 'size' );
size  = json_GetValueStr( jsonNodePtr : '' );


// Cleanup
json_delete(pJson);


Return;