
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
        
        //------------------------------------------------------------- *
        
        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        
        //------------------------------------------------------------- *

        pJson = JSON_ParseString('[           -
          {a:"Hello",b:1,c:22.7},             -
          {a:"Yes\" you can",b:2,c:3.14}      -
        ]');

        json_WriteJsonStmf(pJson: '/jsonxml/out1.json': 1208: *OFF);
        json_WriteXmlStmf (pJson: '/jsonxml/out1.xml' : 1208: *OFF);
        json_WriteCsvStmf (pJson: '/jsonxml/out1.csv' : 1208: *OFF :
          '{ decPoint:",",  delimiter:";",  headers:true}'
        );

        json_Close(pJson);
        *inlr = *on;
