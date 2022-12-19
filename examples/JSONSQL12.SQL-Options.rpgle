**free
// ------------------------------------------------------------- *
// noxDB - Not only XML. JSON, SQL and XML made easy for RPG

// Company . . . : System & Method A/S - Sitemule
// Design  . . . : Niels Liisberg

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

// Look at the header source file "QRPGLEREF" member "NOXDB"
// for a complete description of the functionality

// When using noxDB you need two things:
//  A: Bind you program with "NOXDB" Bind directory
//  B: Include the noxDB prototypes from QRPGLEREF member NOXDB

// ------------------------------------------------------------- *
// Using SQL cursors. Resultsets

// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
/include qrpgleRef,noxdb

   // Disable the cycle
   *inlr = *on;

   // Set the delimiters used to access the graph selector
   // OBSOLETE: delimiters ins now set to job default at invocation.
   // json_setDelimitersByCcsid();

   buildTestData();
   example1();
   example2();
   example3();

   // And if you use anything but the defaults 
   // then ALWAYS reset to default after use: Other wise somthing unexpectet might occur:
   json_sqlSetOptions('{'+ // use dfault connection
      'uppercaseColname: false, '+ // set option for uppcase
      'autoParseContent: true, '+  // auto parse columns predicted to have JSON or XML contents
      'sqlnaming       : false  '+ // use the IBM i and sql naming for tables and use library list
   '}');

   // disconnect database connection
   json_sqlDisconnect();

// ------------------------------------------------------------------------------------
// example1
// ------------------------------------------------------------------------------------
dcl-proc example1;

   Dcl-S pResult            Pointer;

   // This is the deafult 
   // 1) Names in JSON will be lowercase exept if a quoted name ( where case is significant) 
   // 2) Columns with JSON data will be parsed int sub-objects
   // 3) Library list is used when finiding tables and you can use both IBM nmaes libra/file and SQL schema/table 
   // Note: it can be a JSON string or a JSON object made by json_ParseString
   json_sqlSetOptions('{'+ // use dfault connection
      'uppercaseColname: false, '+ // set option for uppcase
      'autoParseContent: true, '+  // auto parse columns predicted to have JSON or XML contents
      'sqlnaming       : false  '+ // use the IBM i and sql naming for tables and use library list
   '}');

   pResult = json_sqlResultSet(
      'Select -
         id as "rowId", -
         xClob as "userProperties" - 
      from noxdbdemo.example':          // The sql stmt
      1:                             // from row number
      JSON_ALLROWS:                  // Max number of rows to fetch
      JSON_META + JSON_FIELDS        // return a object and not an array
   );

   // Produce a JSON stream file in the root of the IFS
   json_writeJsonStmf(pResult:
      '/prj/noxdb/testout/using-options-example1.json' : 1208 : *ON
   );

   // Always delete objects after use - Otherwise yoy will have a memry leak
   json_delete(pResult);
   
   return;
end-proc;

// ------------------------------------------------------------------------------------
// example2
// ------------------------------------------------------------------------------------
dcl-proc example2;

   Dcl-S pResult            Pointer;

   // However - some times you need 
   // 1) the resultset names in upper case:
   // 2) If the data contains JSON the you need it stringified
   // 3) And you will only acces data in current schema execpt if qualified
   // Note: it can be a JSON string or a JSON object made by json_ParseString
   json_sqlSetOptions('{'+ // use dfault connection
      'uppercaseColname: true,  '+ // set option for uppcase
      'autoParseContent: false, '+ // auto parse columns predicted to have JSON or XML contents
      'sqlnaming       : true   '+ // use the SQL naming for database.table and only currently set schema
   '}');

   pResult = json_sqlResultSet(
      'Select * from noxdbdemo.example': // The sql stmt
      1:                             // from row number
      JSON_ALLROWS:                  // Max number of rows to fetch
      JSON_META + JSON_FIELDS        // return a object and not an array
   );

   // Produce a JSON stream file in the root of the IFS
   json_writeJsonStmf(pResult:
      '/prj/noxdb/testout/using-options-example2.json' : 1208 : *ON
   );

   // Always delete objects after use - Otherwise you will have a memory leak
   json_delete(pResult);

end-proc;

// ------------------------------------------------------------------------------------
// example1 - auto parse feature
// ------------------------------------------------------------------------------------
dcl-proc example3;

   Dcl-S pResult            Pointer;

   // This is the deafult 
   // 1) Names in JSON will be lowercase exept if a quoted name ( where case is significant) 
   // 2) Columns with JSON data will be parsed int sub-objects
   // 3) Library list is used when finiding tables and you can use both IBM nmaes libra/file and SQL schema/table 
   // Note: it can be a JSON string or a JSON object made by json_ParseString
   json_sqlSetOptions('{'+ // use dfault connection
      'uppercaseColname: false, '+ // set option for uppcase
      'autoParseContent: true, '+  // auto parse columns predicted to have JSON or XML contents
      'sqlnaming       : false  '+ // use the IBM i and sql naming for tables and use library list
   '}');

   pResult = json_sqlResultSet('-
      select -
      json_object ( -
         key ''service_category'' value service_category, -
         key ''service_schema_name'' value service_schema_name, -
         key ''service_name'' value service_name, -
         key ''sql_object_type'' value sql_object_type, -
         key ''object_type'' value object_type, -
         key ''system_object_name'' value system_object_name, -
         key ''latest_db2_group_level'' value latest_db2_group_level, -
         key ''initial_db2_group_level'' value initial_db2_group_level, -
         key ''earliest_possible_release'' value earliest_possible_release -
      ) -
      from services_info': 
      1:                             // from row number
      JSON_ALLROWS:                  // Max number of rows to fetch
      JSON_META + JSON_FIELDS        // return a object and not an array
   );

   // Produce a JSON stream file in the root of the IFS
   json_writeJsonStmf(pResult:
      '/prj/noxdb/testout/using-options-example3.json' : 1208 : *ON
   );

   // Always delete objects after use - Otherwise yoy will have a memry leak
   json_delete(pResult);
   
   return;
end-proc;

// ---------------------------------------------------------------------------
dcl-proc buildTestData;

   dcl-s err ind;

   // Run a "normal SQL " to create the test case 
   err = json_sqlExec('-
      create or replace table noxdbdemo.example (      -         
         id int generated always as identity,      -
         xSmallint  smallint,                      -
         xInt       int,                           -
         xDec       dec(11 , 2),                   - 
         xNumeric   numeric (11, 2),               -     
         xReal      real,                          - 
         xChar      char(30),                      - 
         xVarchar   varchar(30),                   -
         xDate      date,                          -    
         xTime      time,                          -    
         xTimestamp timestamp,                     -
         xBlob      blob,                          -
         xClob      clob                           -
      )'        
   );

   // Note we put a object into the CLOB column
   err = json_sqlInsert (
      'example':  // table name
      '{-         
         "xSmallint": -32766.00 , -
         "xInt": -2147483646.00,   -
         "xDec": -123456789.12, -
         "xNumeric": -123456789.12, -
         "xReal": -123456789.12, -
         "xChar": "abc", - 
         "xVarchar": "abc", -
         "xDate": "2020-01-01", -
         "xTime": "12.34.56", -
         "xTimestamp": "2020-01-01-12.34.56.123456", -
         "xBlob": "abc", -
         "xClob": {-
            "name": "John", -
            "age": 25 -
         } -
      }'
   );

end-proc; 
