        
        //------------------------------------------------------------- *

        //Return one signe object for one single row

        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pRow         Pointer;
        Dcl-S sql          Varchar(512);

        //------------------------------------------------------------- *

        // return one object with one row
        sql   = ('-
           Select *                  -
           from product              -
           where prodKey = 100       -
           fetch first 1 row only    -
        ');

        pRow  = json_sqlResultRow(sql);

        // Produce a JSON stream file in the root of the IFS
        json_writeJsonStmf(pRow   :
           '/jsonxml/json/one-object.json' : 1208 : *ON
        );

        // Cleanup: delete the object and disconnect
        json_delete (pRow);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
