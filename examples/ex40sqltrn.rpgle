**free
// ------------------------------------------------------------------------------------
// noxDB - Not Only Xml - Its JSON, XML, SQL and more
//
// This tutorial will show SQL transactional features: commit and rollback
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

    // Run the example
    example1();

// Always remember to delete used memory !!
on-exit;
    nox_sqlDisconnect(pCon);
    if memuse <> nox_memuse();
        nox_joblog('Ups - forgot to clean something up');
    endif;

end-proc;
// -------------------------------------------------------------
// Transactional flow
// --------------------------------------------------------------
dcl-proc example1;

    dcl-s error         ind;
    dcl-s pRows1        pointer;
    dcl-s pRows2        pointer;
    dcl-s pRows3        pointer;
    dcl-s pRow4         pointer;
    dcl-s sqlhnd	    pointer;
    dcl-s id 	        int(20);
    dcl-s text	        varchar(256);

    // Run a "normal SQL " to create the test case
    error = nox_sqlExec(pCon:
        'create schema noxdbdemo'
    );

    // Run a "normal SQL " to create the test case
    error = nox_sqlExec(pCon:
        'create or replace table noxdbdemo.text (          -
            id    int generated always as identity,   -
            text  varchar(256)                        -
        )'
    );

    error = nox_sqlExec(pCon:
        'truncate noxdbdemo.text'
    );

    // Open a transaction window for commitment control. Do this by Start transaction
    nox_sqlStartTransaction(pCon);

    // This insert is a part of the transaction
    error = nox_sqlExec(pCon:
        'insert into noxdbdemo.text (text) values(''I mean this'')'
    );

    // After the commit - you are out of the transaction window
    error = nox_sqlCommit(pCon);

    // So this read a done without lock
    pRows1 = nox_sqlResultSet(pCon:
        'select * from noxdbdemo.text'
    );

    // Open the next transaction window
    error = nox_sqlStartTransaction(pCon);

    // This insert is a part of the transaction
    error = nox_sqlExec(pCon:'-
        insert into noxdbdemo.text (text) values(''I will regret this '')'
    );

    // notice that rows in this read is locked !!
    pRows2 = nox_sqlResultSet(pCon:
        'select * from noxdbdemo.text'
    );

    // After the rollback - you are out of the
    // transaction window - no harm done - no locke remains
    error = nox_sqlRollback(pCon);

    // So no locks in this read and her after.
    pRows3 = nox_sqlResultSet(pCon:
        'select * from noxdbdemo.text'
    );

    // cursors are kept open and stable
    // --------------------------------

    // Lets read row by row
    sqlhnd  = nox_sqlOpen(pCon:
        'Select * from noxdbdemo.text'
    );

    // Now iterate on each row in the resultset
    pRow4 = nox_sqlFetchNext(sqlhnd);
    DoW not nox_error(pRow4);

        // Simply pull out some data from the row object
        id      = nox_getInt (pRow4 : 'id');
        text    = nox_getStr (pRow4 : 'text');

        // Open the transaction window
        error = nox_sqlStartTransaction(pCon);

        // change stuff !! note - concat the id might  cause UTF-8 conversion issue
        // nox_setStr ( pRow4 : 'text' : 'Row by row' + %char(id));
        nox_setStr ( pRow4 : 'text' : 'Row by row');

        error = nox_sqlUpdate (pCon:
             'noxdbdemo.text'    // table name
             :pRow4              // row in object form {a:1,b:2} etc..
             :'id=${id}'         // Where clause used with marker $ and the the element in the object
             :pRow4              // key template or object
        );

        // After the commit - you are out of the transaction window
        error = nox_sqlCommit(pCon);

        // Always dispose it before get the next - IMPORTANT. nox_sqlFetchNext is a object factory
        nox_delete(pRow4);

        pRow4 = nox_sqlFetchNext(sqlhnd);
    EndDo;

// always remember to delete used memory !!
on-exit;

    // Finaly and always !! close the SQL cursor and dispose the json row object
    nox_sqlClose(sqlhnd);

    nox_delete(pRows1);
    nox_delete(pRows2);
    nox_delete(pRows3);

end-proc;