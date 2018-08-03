      * ------------------------------------------------------------- *
     H BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' )
      /include 'headers/JSONPARSER.rpgle'
     D pJson           s               *
      /free
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
