**free
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

/include 'headers/jsonparser.rpgle'

Dcl-S pJson        Pointer;
Dcl-S size         varchar(10);

pJson = json_parseString('{"size":null}');
size = json_getStr ( pJson : 'size': '0');
json_delete(pJson);

Return;