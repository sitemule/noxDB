
        //  ------------------------------------------------------------- *
        //  -- Procedure returns a resultset
        //  --------------------------------
        //  CREATE or replace PROCEDURE  qgpl.custlist  (
        //  in custName varchar(20) default null
        //  )
        //  LANGUAGE SQL 
        //  DYNAMIC RESULT SETS 1

        //  BEGIN

        //      DECLARE c1 CURSOR WITH RETURN FOR
        //        select * 
        //        from   qiws.QCUSTCDT
        //        where  custName is null 
        //        or     upper(lstnam) like '%' concat upper(custName) concat '%';
        //      
        //      OPEN c1;

        //  END; 


        //   call qgpl.custList();
        //   call qgpl.custList(custName=>'john');


        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'
        Dcl-S pRows        Pointer;
        Dcl-S sql          Varchar(512);
        Dcl-S start        Int(10);
        Dcl-S limit        Int(10);

        //------------------------------------------------------------- *

        // return a object with all rows
        sql   = ('-
              call qgpl.custList (custName => ''john'' ) -
        ');

        start = 1;
        limit = JSON_ALLROWS;
        pRows = json_sqlResultSet(
            sql:
            start:
            limit:
            JSON_META+JSON_FIELDS
        );

        // Produce a JSON stream file in the root of the IFS
        json_writeJsonStmf(pRows  :
           '/jsonxml/json/resultset-object-1.json' : 1208 : *ON
        );

        // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
        json_close(pRows);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
