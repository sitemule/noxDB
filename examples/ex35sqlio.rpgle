**free
// ------------------------------------------------------------------------------------
// noxDB - Not Only Xml - Its JSON, XML, SQL and more
//
// This tutorial will show SQL I/O features: insert, update and delete but also
// more advanced upsert
//
// Design:  Niels Liisberg
// Project: Sitemule.com
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// Look at the header source file "QRPGLEREF" member "NOXDBUTF8"
// for a complete description of the functionality
//
// When using noxDbUtf8 you need two things:
//  A: Bind you program with "NOXDBUTF8" Bind directory
//  B: Include the noxDbUtf8 prototypes from QRPGLEREF member NOXDBUTF8
//
// Important: You need to set the CCSID of the source to the CCSID of the
//            target ccsid of the running job.
//            otherwise special chars will be strange for constants.
//            This project is by default set to CCSID 500
//            do a CHGJOBCCSID(500) before running these examples.
//            This only applies to program constants !!
//
// Note:      This program is/can be build with UTF-8, so all CHAR/VARCHAR are in UTF-8
//            This is not an requirement - you can use any CCSID you like
//
// Note: In the SQL folder you will find a SQL script: stock.sql
// that creates the tables used in this example.
//
//
// try/build:
// cd '/prj/NOXDBUTF8'
// addlible NOXDBUTF8
// chgjobccsid(500)
// call
// ------------------------------------------------------------------------------------
Ctl-Opt copyright('Sitemule - System & Method (C), 2025');
Ctl-Opt BndDir('NOXDBUTF8') CCSID(*CHAR:*UTF8);
Ctl-Opt dftactgrp(*NO) ACTGRP('QILE') option(*nodebugio:*srcstmt:*nounref) ALWNULL(*USRCTL);
Ctl-Opt main(main);

/include qrpgleref,noxDbUtf8

// Global connection pointer
dcl-s pCon         pointer;


// ------------------------------------------------------------------------------------
dcl-proc main;

    dcl-s memuse       int(20);

    // Take a snapshot of the memory usage before we start
    memuse = nox_memUse();

    // Connect to the database - using the noxDbUtf8 driver. This is global for all examples
    pCon = nox_sqlConnect();

    // Run the examples
    example1();
    example2();
    example3();
    example4();

// Always remember to delete used memory !!
on-exit;
    nox_sqlDisconnect(pCon);
    if memuse <> nox_memuse();
        nox_joblog('Ups - forgot to clean something up');
    endif;

end-proc;
// -------------------------------------------------------------
// Simple insert:
// noxdb insert uses a graph object and maps it to the table structure
// The graph object can be build in many ways - here we use the nox_Object
// --------------------------------------------------------------
dcl-proc example1;

    Dcl-S pRow       Pointer;
    Dcl-S error      ind;
    Dcl-S id         int(10);

    pRow = nox_Object(
        'sku'           : 'Golf' :
        'department'    : 'Golf' :
        'main_Category' : 'Clubs'  :
        'sub_Category'  : 'Set' :
        'description'   : 'Super swing complete set' :
        'price'         : nox_dec(311.95):
        'price_Date'    : nox_date(%date()):
        'price_Time'    : nox_time(%time()):
        'updated_At'    : nox_ts  (%timestamp())
    );

    // Insert the row into the stock table
    error = nox_sqlInsert (
        pCon:               // The connection pointer
        'noxdbdemo.stock':  // The table name
        pRow                // The row data
    );

    // Test errors:
    if error;
        nox_joblog(nox_Message(pRow));
        Return;
    EndIf;

    // Get the inserted ID
    id = nox_sqlGetInsertId ( pCon );

    // and place it in our graph object
    nox_setInt ( pRow : 'id' : id  );

    nox_joblog('Inserted id = ' + %char(id));

    // Dump it as an IFS file
    nox_WriteJsonStmf(pRow:'/prj/noxdbutf8/testout/ex35-insert1.json':1208:*OFF);

on-exit;
   nox_delete(pRow);
end-proc;
// -------------------------------------------------------------
// Update:
// noxdb updatesuses a graph object and maps it to the table structure
// The graph object can be build in many ways - here we use the nox_Object
// --------------------------------------------------------------
dcl-proc example2;

    Dcl-S pRow       Pointer;
    Dcl-S error      ind;

    pRow = nox_Object(
        'sku'           : 'Golf' :
        'description'   : 'Super maxi swing complete set' :
        'price'         : nox_dec(311.95):
        'price_Date'    : nox_date(%date()):
        'price_Time'    : nox_time(%time()):
        'updated_At'    : nox_ts  (%timestamp())
    );

    // update the row in the stock table
    error = nox_sqlUpdate (
        pCon:                 // The connection pointer
        'noxdbdemo.stock':    // The table name
        pRow :                // The row data
        'sku = ' + nox_strQuote('Golf') // The where clause to identify the row(s) to update
    );

    // Test errors:
    if error;
        nox_joblog(nox_Message(pRow));
        Return;
    EndIf;

    // Dump it as an IFS file
    nox_WriteJsonStmf(pRow:'/prj/noxdbutf8/testout/ex35-update1.json':1208:*OFF);

on-exit;
   nox_delete(pRow);
end-proc;
// -------------------------------------------------------------
// upsert:
// Update if exists, eler inser new row;
// --------------------------------------------------------------
dcl-proc example3;

    Dcl-S pRow       Pointer;
    Dcl-S error      ind;

    pRow = nox_Object(
        'sku'           : 'Badminton Racket' :
        'department'    : 'Sports' :
        'main_Category' : 'Racquet Sports'  :
        'sub_Category'  : 'Badminton Equipment' :
        'description'   : 'Professional badminton racket with strings' :
        'price'         : nox_dec(33.95):
        'price_Date'    : nox_date(%date()):
        'price_Time'    : nox_time(%time()):
        'updated_At'    : nox_ts  (%timestamp())
    );

    // Insert the row into the stock table
    error = nox_sqlUpsert (
        pCon:               // The connection pointer
        'noxdbdemo.stock':  // The table name
        pRow:               // The row data
        'sku = ' + nox_StrQuote('Badminton Racket') // The where clause to identify the row(s) to update
    );

    // Test errors:
    if error;
        nox_joblog(nox_Message(pRow));
        Return;
    EndIf;

    // Dump it as an IFS file
    nox_WriteJsonStmf(pRow:'/prj/noxdbutf8/testout/ex35-upsert1.json':1208:*OFF);

on-exit;
   nox_delete(pRow);
end-proc;
// -------------------------------------------------------------
// delete - or any other sql statement for that matter
// note the use nox_strQuote to quote the string value  in the sql statement
// to avoid sql injection
// --------------------------------------------------------------
dcl-proc example4;

    Dcl-S error      ind;

    // Insert the row into the stock table
    error = nox_sqlExec  (
        pCon:               // The connection pointer
        'delete from noxdbdemo.stock -
        where sku = ' + nox_StrQuote('Badminton Racket') // The sql statement
    );

    // Test errors:
    if error;
        nox_joblog(nox_Message());
        Return;
    EndIf;

end-proc;