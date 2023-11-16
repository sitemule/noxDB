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


// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') ;
/include qrpgleRef,noxdb

    // Call stored procedures
    executeRoutine();


    // That's it..
    *inlr = *on;

// ------------------------------------------------------------------------------------
//
// Create the procedure from ACS. Maybe change the schema location
//
// create or replace table noxdbdemo.customer  (
//   id  int generated always as identity primary key,
//   name varchar(30),
//   age  int
// );


// insert into noxdbdemo.customer (name) values ('john');
// select * from noxdbdemo.customer;

// drop procedure   noxdbdemo.noxtest;
// create or replace procedure noxdbdemo.noxtest (
//   in noxinobj  bigint,
//   in noxoutobj bigint
// )
// set option output=*print, commit=*none, dbgview = *list

// begin
//     declare sqlcode int;
//     declare tempnode bigint;

//     insert into noxdbdemo.customer (name , age) values (
//         nox_getStr(noxinobj, 'name' , 'N/A'),
//         nox_getNum(noxinobj, 'age'  , 0 )
//     );

//     if sqlcode = 0 then
//         set tempnode = nox_setStr(noxoutobj, 'message' , 'Completed normally');
//     else
//         set tempnode = nox_setStr(noxoutobj, 'message' , 'Error occured - Sqlcode: ' || sqlcode );
//     end if;

// end;
// ------------------------------------------------------------------------------------
dcl-proc executeRoutine ;

    dcl-s pInput        pointer;
    dcl-s pOutput       pointer;
    dcl-s err	        ind;
    dcl-s msg           char(50);

    // Build parameter objects
    pInput  = json_newObject();
    json_SetStr(pInput: 'fromCurrencyCode': 'DKK');
    json_SetStr(pInput: 'toCurrencyCode' : 'USD');


    // Caling any SQL routine using nox nodes
    // Polymorphich is not supported. it this case it will fail
    // Let you use the noxDb object graph in SQL procedures
    pOutput = json_sqlExecuteRoutine ('udtfdemo.exchange_rate' : pInput : JSON_GRACEFUL_ERROR);

    // If  json_error (pOutput); use this if you want to catch the error
    If  pOutput = *NULL ; // use this if you use JSON_GRACEFUL_ERROR and want to confinue
        msg = json_Message();
        dsply msg;
    EndIf;

    json_WriteJsonStmf(pOutput:'/prj/noxdb/testout/exchange_rate.json':1208:*OFF);
    json_delete(pInput);
    json_delete(pOutput);

end-proc;
