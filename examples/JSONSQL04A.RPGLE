        //------------------------------------------------------------- *

        //Note: This is only for backward compatility.
        //Please use the JOSNSQL04 sample

        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S manuRow      Pointer;
        Dcl-S prodArray    Pointer;
        Dcl-S prodRow      Pointer;
        Dcl-S resultArray  Pointer;
        Dcl-S resultObj    Pointer;
        Dcl-S manuHnd      Pointer;
        Dcl-S prodHnd      Pointer;
        Dcl-S sql          Varchar(512);

        //------------------------------------------------------------- *

        // The destination object for our SQL result row
        // and the array to contain the rows
        resultArray  = json_newArray ();

        // Open our SQL cursor. Use a simple select
        sql = 'Select * from manufact';
        manuHnd  = json_sqlOpen(sql);

        // Now iterate on each row in the resultset
        manuRow = json_sqlFetchNext(manuHnd);
        dow (manuRow <> *NULL);
           prodArray  = json_newArray ();

           // Note: the SQL can be a template, we fill with values from a json row
           sql = 'Select * from product where manuid = $manuid' ;
           prodHnd  = json_sqlOpen(sql : manuRow);
           
           prodRow = json_sqlFetchNext(prodHnd);
           dow ( prodRow <>  *NULL);
              Json_MemStat();

              json_setValue(prodArray :'[]' : prodRow: JSON_OBJMOVE);

              Json_MemStat();

              prodRow = json_sqlFetchNext(prodHnd);
           enddo;

           json_sqlClose(prodHnd);
           // Append the row to the end of the result array. The [] means "new array element"
           json_setValue(manuRow   : 'products' : prodArray : JSON_OBJMOVE);

           // Append the row to the end of the result array. The [] means "new array element"
           json_setValue(resultArray : '[]' : manuRow : JSON_OBJMOVE);
           manuRow = json_sqlFetchNext(manuHnd) ;
        enddo;

        // Produce a JSON stream file in the root of the IFS
        json_writeJsonStmf(resultArray  :
           '/jsonxml/json/demo-nested.json' : 1208 : *ON
        );
        json_NodeRename( resultArray : 'ROWS');
        // Give the root a name for XML
        json_writeXmlStmf(resultArray  :
           '/jsonxml/xml/demo-nested.xml' : 1208 : *ON
        );

        // Cleanup: Close the SQL cursor, dispose the row and the array
        json_close(resultArray);
        json_sqlClose(manuHnd);
        json_sqlDisconnect();

        // If needed you can detect leaks here:
        if Json_MemLeak();
           Json_MemStat();
        endif;

        // That's it..
        *inlr = *on;
