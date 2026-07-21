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
// Using SQL resultsets

// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') main(main);
/include qrpgleRef,noxdb


// ------------------------------------------------------------------------------------
// main
// ------------------------------------------------------------------------------------
dcl-proc main;

   simpleStatement ();
   groupByStatement ();
   commonTableExpresionStatement();
   aproximate();

   json_sqlDisconnect();

end-proc;

// ------------------------------------------------------------------------------------
// Simple Statement
// ------------------------------------------------------------------------------------
dcl-proc simpleStatement;
   Dcl-S pResult            Pointer;
   Dcl-S sql                VarChar(512);
   Dcl-S start              Int(10);
   Dcl-S limit              Int(10);
   Dcl-S totalRows          Int(10);
   

   // return a object with 10 first rows - give me exact number of rows ( slow result)
   sql= ('-
      Select * -
      from noxdbdemo.icproduct -
      order by 1 -
   ');
   start = 1;
   limit = 10; // Give me the 10 first rows

   // The json_META constructs a resultset object with a "row" array
   // Total rows convert ( if possible ) the select to an select count(*) first
   pResult = json_sqlResultSet(sql:start:limit:
      JSON_META + JSON_TOTALROWS
   );

   // Produce a JSON stream file in the root of the IFS
   json_writeJsonStmf(pResult:
      '/prj/noxdb/testout/total-rows-simple-Statement.json' 
      : 1208 
      : *ON
   );

   totalRows = json_getInt(pResult:'totalRows');
   json_joblog (%char(totalRows));

   // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
   json_delete(pResult);


end-proc;


// ------------------------------------------------------------------------------------
// Group By Statement
// ------------------------------------------------------------------------------------
dcl-proc groupByStatement;

   Dcl-S pResult            Pointer;
   Dcl-S sql                VarChar(512);
   Dcl-S start              Int(10);
   Dcl-S limit              Int(10);
   Dcl-S totalRows          Int(10);


   // return a object with 10 first rows - give me exact number of rows ( slow result)
   sql=(' -
      Select manuid, count(*) counter - 
      from noxdbdemo.icproduct - 
      group by manuid -
      order by 1 -
   ');

   start = 1;
   limit = 10; // Give me the 10 first rows

   // The json_META constructs a resultset object with a "row" array
   // Total rows convert ( if possible ) the select to an select count(*) first
   pResult = json_sqlResultSet(sql:start:limit:
      JSON_META + JSON_TOTALROWS
   );

   // Produce a JSON stream file in the root of the IFS
   json_writeJsonStmf(pResult:
      '/prj/noxdb/testout/total-rows-group-By-Statement.json' 
      : 1208 
      : *ON
   );

   totalRows = json_getInt(pResult:'totalRows');
   json_joblog (%char(totalRows));

   // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
   json_delete(pResult);


end-proc;
// ------------------------------------------------------------------------------------
// Common Table Expresion Statement
// ------------------------------------------------------------------------------------
dcl-proc commonTableExpresionStatement;

   Dcl-S pResult            Pointer;
   Dcl-S sql                VarChar(512);
   Dcl-S start              Int(10);
   Dcl-S limit              Int(10);
   Dcl-S totalRows          Int(10);


   // return a object with 10 first rows - give me exact number of rows ( slow result)
   sql= (' -
      with a as ( -
         Select *  -
         from noxdbdemo.icproduct -
      )  -
      select *  -
      from a  -
      order by 1 -
   ');
   start = 1;
   limit = 10; // Give me the 10 first rows

   // The json_META constructs a resultset object with a "row" array
   // Total rows convert ( if possible ) the select to an select count(*) first
   pResult = json_sqlResultSet(sql:start:limit:
      JSON_META + JSON_TOTALROWS
   );

   // Produce a JSON stream file in the root of the IFS
   json_writeJsonStmf(pResult:
      '/prj/noxdb/testout/total-rows-commonTableExpresionStatement.json' 
      : 1208 
      : *ON
   );

   totalRows = json_getInt(pResult:'totalRows');
   json_joblog (%char(totalRows));

   // Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
   json_delete(pResult);

end-proc;

// ------------------------------------------------------------------------------------
// Aproximate
// ------------------------------------------------------------------------------------
dcl-proc aproximate;

   Dcl-S pResult            Pointer;
   Dcl-S sql                VarChar(512);
   Dcl-S start              Int(10);
   Dcl-S limit              Int(10);
   Dcl-S totalRows          Int(10);

   // return a object with first 10, give me the approximatly number of rows ( fast result)
   sql   = ('-
      Select * -
      from noxdbdemo.icproduct -
   ');
   start = 1;
   limit = -1; // Give me all rows

   // The json_META constructs a resultset object with a "row" array
   // Total rows convert ( if possible ) the select to an select count(*) first
   pResult = json_sqlResultSet(sql:start:limit:
      JSON_META + JSON_APPROXIMATE_TOTALROWS
   );

   // Produce a JSON stream file in the root of the IFS
   json_writeJsonStmf(pResult:
      '/prj/noxdb/testout/total-rows-aproximate.json' 
      : 1208 
      : *ON
   );

   totalRows = json_getInt(pResult:'totalRows');
   json_joblog (%char(totalRows));

   // Cleanup: Close the SQL cursor, dispose the row and the array
   json_delete(pResult);

end-proc;

