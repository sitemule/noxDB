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
// Using SQL resulset - read all rows 
// and produce a metatag with column info

// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') main(main);
/include qrpgleRef,noxdb

// ------------------------------------------------------------------------------------
// main
// ------------------------------------------------------------------------------------
dcl-proc main;

  clobs();
  blobs();
  db2services();
  json_sqlDisconnect();
  return;
end-proc;


// ------------------------------------------------------------------------------------
// blobs
// ------------------------------------------------------------------------------------
dcl-proc blobs;

  dcl-s pRows              Pointer;

  // return a object with all rows
  pRows = json_sqlResultSet(
    'Select * from noxdbdemo.blobs':
    1: // Starting from row
    JSON_ALLROWS: // Number of rows to read
    JSON_META+JSON_FIELDS // Embed the rows array in an object and produce a metatag with column info
  );

  // Produce a JSON stream file in the root of the IFS
  json_writeJsonStmf(pRows  :
      '/prj/noxdb/testout/resultset-object-blob.json' : 1208 : *ON
  );

  return; // Always remeber the return - otherwise the on-exit wil not be run

on-exit;

  // Cleanup: Close the SQL cursor, dispose the rows, arrays etc;
  json_delete(pRows);

end-proc;

// ------------------------------------------------------------------------------------
// clobs
// ------------------------------------------------------------------------------------
dcl-proc clobs;

  dcl-s pRows              Pointer;

  // return a object with all rows
  pRows = json_sqlResultSet(
    'Select * from noxdbdemo.clobs':
    1: // Starting from row
    JSON_ALLROWS: // Number of rows to read
    JSON_META+JSON_FIELDS // Embed the rows array in an object and produce a metatag with column info
  );

  // Produce a JSON stream file in the root of the IFS
  json_writeJsonStmf(pRows  :
      '/prj/noxdb/testout/resultset-object-clob.json' : 1208 : *ON
  );

  return; // Always remeber the return - otherwise the on-exit wil not be run

on-exit;

  // Cleanup: Close the SQL cursor, dispose the rows, arrays etc;
  json_delete(pRows);

end-proc;
// ------------------------------------------------------------------------------------
// db2services
// ------------------------------------------------------------------------------------
dcl-proc db2services;

  dcl-s pRows              Pointer;

  // return a object with all rows
  pRows = json_sqlResultSet(
    'select * -
    from table(qsys2.ifs_object_statistics(''/home'',''NO'')) ' : 
    1: // Starting from row
    JSON_ALLROWS: // Number of rows to read
    JSON_META+JSON_FIELDS // Embed the rows array in an object and produce a metatag with column info
  );

  // Produce a JSON stream file in the root of the IFS
  json_writeJsonStmf(pRows  :
      '/prj/noxdb/testout/resultset-object-db2services.json' : 1208 : *ON
  );

  return; // Always remeber the return - otherwise the on-exit wil not be run

on-exit;

  // Cleanup: Close the SQL cursor, dispose the rows, arrays etc;
  json_delete(pRows);

end-proc;




