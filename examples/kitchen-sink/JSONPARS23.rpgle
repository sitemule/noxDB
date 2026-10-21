
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );
        
        //------------------------------------------------------------- *
        
        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson        Pointer;
        
        //------------------------------------------------------------- *

        pJson = NOX_ParseString('[           -
          {a:"Hello",b:1,c:22.7},             -
          {a:"Yes\" you can",b:2,c:3.14}      -
        ]');

        nox_WriteJsonStmf(pJson: '/jsonxml/out1.json': 1208: *OFF);
        nox_WriteXmlStmf (pJson: '/jsonxml/out1.xml' : 1208: *OFF);
        nox_WriteCsvStmf (pJson: '/jsonxml/out1.csv' : 1208: *OFF :
          '{ decPoint:",",  delimiter:";",  headers:true}'
        );

        nox_Close(pJson);
        *inlr = *on;
