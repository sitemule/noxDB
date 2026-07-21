**FREE
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

// Locking in noxDb is done by transaction. That mean 
// everything you do in a transaction window is 
// locked – that is reads, writes, updates and 
// deletes but also any DDL’s like 
// create, drop , grant etc. – basically everything. 

// A transaction window is defined 
// by sqlStartTransaction and the window keeps 
// open until you do a sqlCommit or a sqlRollback ( or your job ends ). 
// Hereafter noxDB is back into a transaction-less state where everything
// is done without any lock and  reads, writes, 
// updates and deletes are happening immediately.

// So the transaction in noxDB is well defined 
// and designed to be used together with a 
// microservice architecture in mind. It is not 
// designed for pessimistic data locking, but 
// of course also be (mis)used in this way. 

// Note: This is buy nature not thread safe
// You have to serialize transactions with semaphores or alike 
// when using threads 
// Also this requires that the files/tables a under journaling

// The flow is:  

//     sqlStartTransaction
//     do reads, writes, updates and deletes 
//     sqlCommit

// or if anything goes wrong:

//     sqlStartTransaction
//     do reads, writes, updates and deletes 
//     sqlRollback

// Note: testing the errors are omitted for clear reading
// .. but you should not :) 

// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') ;
/include qrpgleRef,noxdb
dcl-s err           ind;
dcl-s pRows1        pointer;
dcl-s pRows2        pointer;
dcl-s pRows3        pointer;
dcl-s pRow4         pointer;
dcl-s sqlhnd	    pointer;
dcl-s id 	        int(20);
dcl-s text	        varchar(256);


    // Run a "normal SQL " to create the test case 
    err = json_sqlExec(
        'create schema noxdbdemo'
    );

    // Run a "normal SQL " to create the test case 
    err = json_sqlExec(
        'create or replace table noxdbdemo.text (          -         
            id    int generated always as identity,   -
            text  varchar(256)                        -
        )'        
    );

    err = json_sqlExec(
        'truncate noxdbdemo.text'
    );

    // Open a transaction window for commitment control. Do this by Start transaction 
    json_sqlStartTransaction();

    // This insert is a part of the transaction 
    err = json_sqlExec(
        'insert into noxdbdemo.text (text) values(''I mean this'')'
    );

    // After the commit - you are out of the transaction window
    err = json_sqlCommit();

    // So this read a done without lock 
    pRows1 = json_sqlResultSet(
        'select * from noxdbdemo.text'
    );

    // Open the next transaction window
    err = json_sqlStartTransaction();

    // This insert is a part of the transaction 
    err = json_sqlExec('-
        insert into noxdbdemo.text (text) values(''I will regret this '')'
    );

    // notice that rows in this read is locked !!
    pRows2 = json_sqlResultSet(
        'select * from noxdbdemo.text'
    );

    // After the rollback - you are out of the 
    // transaction window - no harm done - no locke remains
    err = json_sqlRollback();

    // So no locks in this read and her after.
    pRows3 = json_sqlResultSet(
        'select * from noxdbdemo.text'
    );

    // cursors are kept open and stable 
    // --------------------------------

    // Lets read row by row
    sqlhnd  = json_sqlOpen(
        'Select * from noxdbdemo.text'
    );

    // Now iterate on each row in the resultset
    pRow4 = json_sqlFetchNext(sqlhnd);
    DoW not json_Error(pRow4);

        // Simply pull out some data from the row object
        id      = json_getInt (pRow4 : 'id');
        text    = json_getStr (pRow4 : 'text');

        // Open the transaction window
        err = json_sqlStartTransaction();

        // change stuff
        json_setStr ( pRow4 : 'text' : 'Row by row' + %char(id));

        err = json_sqlUpdate (
             'noxdbdemo.text'    // table name
             :pRow4              // row in object form {a:1,b:2} etc..
             :'id=$id'           // Where clause used with marker $ and the the element in the object 
             :pRow4              // key template or object
        );

        // After the commit - you are out of the transaction window
        err = json_sqlCommit();

        // Always dispose it before get the next - IMPORTANT. json_sqlFetchNext is a object factory
        json_delete(pRow4); 
        
        pRow4 = json_sqlFetchNext(sqlhnd);
    EndDo;


    // Finaly and always !! close the SQL cursor and dispose the json row object
    json_sqlClose(sqlhnd);

    json_delete(pRows1);
    json_delete(pRows2);
    json_delete(pRows3);

    json_sqlDisconnect();

    // That's it..
    *inlr = *on;

