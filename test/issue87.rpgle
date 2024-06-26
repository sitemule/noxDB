**free
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

/include 'headers/jsonparser.rpgle'

Dcl-S pRows              Pointer;

// return an simple array with rows
pRows = json_sqlResultSet(
    'Select * from noxdbdemo.icproduct'
);

// Produce a JSON stream file in the IFS
// Debug and patch the issue #87 to null the se it work
// since the implementation of stream her in noxDb might be newer than used else where
json_writeJsonStmf(pRows  :
    '/prj/noxdb/testout/issue87.json' : 1208 :*OFF
);

// Cleanup
json_delete(pRows);


Return;