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
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
/include qrpgleRef,noxdb

Dcl-S pRows              Pointer;

// return a object with all rows
pRows = json_sqlResultSet(
  'Select * from noxdbdemo.products':
  1: // Starting from row
  JSON_ALLROWS: // Number of rows to read
  JSON_META+JSON_FIELDS // Embed the rows array in an object and produce a metatag with column info
);

// Produce a JSON stream file in the root of the IFS
json_writeJsonStmf(pRows  :
    '/prj/noxdb/testout/resultset-object-products.json' : 1208 : *ON
);

// Cleanup: Close the SQL cursor, dispose the rows, arrays and disconnect
json_delete(pRows);
json_sqlDisconnect();

// That's it..
*inlr = *on;
