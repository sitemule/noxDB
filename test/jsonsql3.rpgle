
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );
        
        /include 'headers/JSONPARSER.rpgle'
        
        Dcl-S manuRow      Pointer;
        Dcl-S prodArray    Pointer;
        Dcl-S resultArray  Pointer;
        Dcl-S resultObj    Pointer;
        Dcl-S manuHnd      Pointer;
        Dcl-S prodHnd      Pointer;
        Dcl-S sql          Varchar(512);
        Dcl-S json         Varchar(512);

        //------------------------------------------------------------- *
        
        Dcl-Pi JSONSQL3;
          pResult Char(50);
        End-Pi;

        // The destination object for our SQL result row
        // and the array to contain the rows
        resultArray  = json_newArray ();

        // Open our SQL cursor. Use a simple select
        sql = 'Select manuid from manufact fetch first 1 rows only';
        manuHnd  = json_sqlOpen(sql);

        // Now iterate on each row in the resultset
        manuRow = json_sqlFetchNext(manuHnd);
        dow (manuRow <> *NULL);
           // Note: the SQL can be a template, we fill with values from a json row
           sql = 'Select * from product where manuid = $manuid' ;
           prodArray  = json_sqlResultSet(sql: 1 : 2 : 0 : manuRow);
           // Append the row to the end of the result array.
           json_MoveObjectInto (manuRow   : 'products' : prodArray );
           json_ArrayPush (resultArray : manuRow );
           manuRow = json_sqlFetchNext(manuHnd) ;
        enddo;

        // Produce a JSON stream file in the root of the IFS
        json_writeJsonStmf(resultArray  :
           '/jsonxml/json/demo-nested.json' : 1208 : *ON
        );
        json = json_asJsonText(resultArray);
        pResult = json;

        // Cleanup: Close the SQL cursor, dispose the row and the array
        json_close(resultArray);
        json_sqlClose(manuHnd);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;

        Return;
