**free
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

/include 'headers/JSONPARSER.rpgle'

dcl-s p1 pointer;
dcl-s p2 pointer;
dcl-s jsonText varchar(1000);

p1 = json_newObject();
json_setNull(p1:'a');
jsonText = json_asJsonText(p1);// {"a":null}
json_delete(p1);

p2 = json_parseString('{"a":null}');
jsonText = json_asJsonText(p2);// {"a":""}
json_delete(p2);        
*inlr = *on;
