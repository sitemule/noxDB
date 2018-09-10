        
        //------------------------------------------------------------- *

        //Return one signe object for one single row

        //------------------------------------------------------------- *

        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pRow         Pointer;
        Dcl-S sql          Varchar(512);

        //------------------------------------------------------------- *

        // return one object with one row
        sql   = ('-
           Select *                  -
           from product              -
           where prodKey = $prodKey  -
           fetch first 1 row only    -
        ');

        // The key is setup in the json template:
        pRow  = json_sqlResultRow(sql: '{ prodKey : 100 }');

        // Produce a JSON stream file in the root of the IFS
        json_writeJsonStmf(pRow   :
           '/jsonxml/json/one-object.json' : 1208 : *ON
        );

        // Cleanup: delete the object and disconnect
        json_delete (pRow);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
