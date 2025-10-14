        //------------------------------------------------------------- *

        //Note: This is only for backward compatility.
        //Please use the JOSNSQL04 sample

        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

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
        resultArray  = nox_newArray ();

        // Open our SQL cursor. Use a simple select
        sql = 'Select * from manufact';
        manuHnd  = nox_sqlOpen(sql);

        // Now iterate on each row in the resultset
        manuRow = nox_sqlFetchNext(manuHnd);
        dow (manuRow <> *NULL);
           prodArray  = nox_newArray ();

           // Note: the SQL can be a template, we fill with values from a json row
           sql = 'Select * from product where manuid = $manuid' ;
           prodHnd  = nox_sqlOpen(sql : manuRow);
           
           prodRow = nox_sqlFetchNext(prodHnd);
           dow ( prodRow <>  *NULL);
              Nox_MemStat();

              nox_setValue(prodArray :'[]' : prodRow: NOX_OBJMOVE);

              Nox_MemStat();

              prodRow = nox_sqlFetchNext(prodHnd);
           enddo;

           nox_sqlClose(prodHnd);
           // Append the row to the end of the result array. The [] means "new array element"
           nox_setValue(manuRow   : 'products' : prodArray : NOX_OBJMOVE);

           // Append the row to the end of the result array. The [] means "new array element"
           nox_setValue(resultArray : '[]' : manuRow : NOX_OBJMOVE);
           manuRow = nox_sqlFetchNext(manuHnd) ;
        enddo;

        // Produce a JSON stream file in the root of the IFS
        nox_writeJsonStmf(resultArray  :
           '/jsonxml/json/demo-nested.json' : 1208 : *ON
        );
        nox_NodeRename( resultArray : 'ROWS');
        // Give the root a name for XML
        nox_writeXmlStmf(resultArray  :
           '/jsonxml/xml/demo-nested.xml' : 1208 : *ON
        );

        // Cleanup: Close the SQL cursor, dispose the row and the array
        nox_close(resultArray);
        nox_sqlClose(manuHnd);
        nox_sqlDisconnect();

        // If needed you can detect leaks here:
        if Nox_MemLeak();
           Nox_MemStat();
        endif;

        // That's it..
        *inlr = *on;
