**FREE
      // build:
      //  addlible noxdb2
      //  cd  '/prj/noxdbutf8'   
      //  CRTBNDRPG PGM(NOXDB2/JSONSQL1) SRCSTMF('/prj/noxdbutf8/test/jsonsql1.rpgle') dbgview(*ALL)  
      Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');

      /include 'headers/JSONPARSER.rpgle'


      Dcl-S pRow         Pointer;
      Dcl-S sqlHnd       Pointer;

      Dcl-S ints         Int(10);
      Dcl-S numbers      Zoned(11:2);
      Dcl-S text         Varchar(512);
      Dcl-S dates        Date;

      Dcl-S Result       Varchar(50);

      //------------------------------------------------------------- *

      Dcl-Pi JSONSQL1;
         pResult Char(50);
      End-Pi;

      Result = '';
      
      // Connection can be made implecit or explicit 
      // json_sqlconnect();

      // Open our SQL cursor. Use a simple select
      sqlhnd  = json_sqlOpen(
         'Select * from product ' +
         'where PRODID like ''Coolpix%'' ' +
         'fetch first 5 rows only'
      );

      // Was there a problem ?
      if json_Error(sqlhnd);
         pResult = json_message(sqlhnd);
         json_sqlDisconnect();
         return;  // You can return, however the rest of the routines a roubust enough to just continue
      endif;

      // Now iterate on each row in the resultset
      pRow = json_sqlFetchNext(sqlhnd);
      dow (pRow <> *NULL);
         ints    = json_getInt  (pRow : 'PRODKEY');
         numbers = json_getNum  (pRow : 'PRICE');
         text    = json_getStr  (pRow : 'DESC');
         dates   = json_getDate (pRow : 'STOCKDATE');
         
         Result += %Char(ints) + ',' + %Char(numbers) + '-';
         
         json_delete(pRow); // Always dispose it before get the next
         pRow = json_sqlFetchNext(sqlhnd);
      enddo;

      pResult = Result;

      // Finaly and always !! close the SQL cursor and dispose the json row object
      json_sqlClose(sqlhnd);

      // You can leave the connection on for succesive requests   
      // json_sqlDisconnect();

      // That's it..
      *inlr = *on;


