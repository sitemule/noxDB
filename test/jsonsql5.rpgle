
        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );
        
        /include 'headers/JSONPARSER.rpgle'
        
        Dcl-S pRow         Pointer;
        Dcl-S sql          Varchar(512);
        
        Dcl-C OS Const(x'9C');
        Dcl-C CS Const(x'47');
        Dcl-C DL Const(x'67');

        //------------------------------------------------------------- *
        
        Dcl-Pi JSONSQL5;
          pResult Char(50);
        End-Pi;

        // return one object with one row
        sql   = (
           'Select PRODKEY, PRODID, PRICE ' +
           'from product ' +
           'where prodKey = ' + DL + 'prodKey ' +
           'fetch first 1 row only'
        );

        pRow  = json_sqlResultRow(sql:OS + 'prodKey : 250' + CS);

        pResult = json_asJsonText(pRow);

        // Cleanup: delete the object and disconnect
        json_delete (pRow);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
        
        Return;