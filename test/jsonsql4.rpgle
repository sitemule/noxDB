
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
        
        /include 'headers/JSONPARSER.rpgle'
        
        Dcl-S pRow         Pointer;
        Dcl-S sql          Varchar(512);

        //------------------------------------------------------------- *
        
        Dcl-Pi JSONSQL4;
          pResult Char(50);
        End-Pi;

        // return one object with one row
        sql   = (
           'Select PRODKEY, PRODID, PRICE ' +
           'from product ' +
           'where prodKey = 250 ' +
           'fetch first 1 row only'
        );

        pRow  = json_sqlResultRow(sql);

        pResult = json_asJsonText(pRow);

        // Cleanup: delete the object and disconnect
        json_delete (pRow);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
        
        Return;