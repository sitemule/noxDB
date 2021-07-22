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
Dcl-S err        Ind;
Dcl-S pIn        Pointer;
Dcl-S pOut       Pointer;
Dcl-s msg        char(50);
Dcl-s i          int(10);

    // Call stored procedures
    add();
    inc();
    commonTypes();
    commonTypesNegative();
    commonTypesNull();
    performance();


    // That's it..
    *inlr = *on;

// ------------------------------------------------------------------------------------
// Use case of  in, in and out parameter
// Create the procedure from ACS. Maybe change the schema location 
//
// create or replace procedure qgpl.add (
//     in  a int,
//     in  b int,
//     out c dec(5,2)
// ) 
// begin 
//     set c = (a + b) / 100.0;
// end;
// call add (a=>123, b=>456 , c=>?);
// ------------------------------------------------------------------------------------
dcl-proc add;
      
    // Build input parameter object
    pIn  = json_newObject();
    json_SetInt(pIn: 'a': 123);
    json_SetInt(pIn: 'b': 456);


    // Call the procedure
    pOut = json_sqlCall ('qgpl.add' : pIn);

    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
    EndIf;


    // Dump the result
    json_joblog(pOut);  

    json_delete(pIn);
    json_delete(pOut);


end-proc;
          
// ------------------------------------------------------------------------------------
// inc - inout parameter usecase 
// 
// Create the procedure from ACS. Maybe change the schema location 
// 
// create or replace procedure qgpl.inc (
//     inout a int
// ) 
// begin 
//     set a = a + 1;
// end;
// call inc (a=>123);
// ------------------------------------------------------------------------------------
dcl-proc inc;

    // Build input parameter object
    pIn  = json_newObject();
    json_SetInt(pIn: 'a': 123);

    // Call the procedure
    pOut = json_sqlCall ('qgpl.inc' : pIn);

    If json_Error(pOut) ;
      msg = json_Message(pOut);
      dsply msg;
    EndIf;


    // Dump the result
    json_joblog(pOut);  

    json_delete(pIn);
    json_delete(pOut);

end-proc;

// ------------------------------------------------------------------------------------
// commonTypes 
// ------------------------------------------------------------------------------------
// Using all supported types by noxDB - 
// Notice: CLOB, BLOB and GRAPHIC is not supported yet in call to stored procedure in noxDB
// 
// Create the procedure from ACS. Maybe change the schema location 
// 
// drop procedure qgpl.common_types;
// create or replace procedure qgpl.common_types  (
//     in ismallint smallint default null,
//     in iinteger integer default null,
//     in ibigint bigint default null,
//     in idecimal decimal (30, 10) default null,
//     in inumeric numeric (30, 10) default null,
//     in ifloat float default null,
//     in ireal real default null,
//     in idouble double default null,
//     in ichar char (256) default null,
//     in ivarchar varchar (256) default null,
//     in idate date default null,
//     in itime time default null,
//     in itimestamp timestamp default null, 
//     out osmallint smallint,
//     out ointeger integer ,
//     out obigint bigint ,
//     out odecimal decimal (30, 10) ,
//     out onumeric numeric (30, 10) ,
//     out ofloat float ,
//     out oreal real ,
//     out odouble double ,
//     out ochar char (256) ,
//     out ovarchar varchar (256) ,
//     out odate date ,
//     out otime time ,
//     out otimestamp timestamp , 
//     inout iosmallint smallint default null,
//     inout iointeger integer default null,
//     inout iobigint bigint default null,
//     inout iodecimal decimal (30, 10) default null,
//     inout ionumeric numeric (30, 10) default null,
//     inout iofloat float default null,
//     inout ioreal real default null,
//     inout iodouble double default null,
//     inout iochar char (256) default null,
//     inout iovarchar varchar (256) default null,
//     inout iodate date default null,
//     inout iotime time default null,
//     inout iotimestamp timestamp default null
// )
// set option output=*print, commit=*none, dbgview = *list 
// begin 

//     set iinteger = ismallint;
//     set ibigint = ismallint;
//     set idecimal  = ismallint;
//     set inumeric  = ismallint;
//     set ifloat = ismallint;
//     set ireal = ismallint;
//     set idouble = ismallint;
//     set ichar = ismallint;
//     set ivarchar = ismallint;
//     set idate = now();
//     set itime = now();
//     set itimestamp = now();
//     set osmallint = ismallint;
//     set ointeger = ismallint;
//     set obigint = ismallint;
//     set odecimal  = ismallint;
//     set onumeric  = ismallint;
//     set ofloat = ismallint;
//     set oreal = ismallint;
//     set odouble = ismallint;
//     set ochar = ismallint;
//     set ovarchar = ismallint;
//     set odate = now();
//     set otime = now();
//     set otimestamp = now();
//     set iosmallint = ismallint;
//     set iointeger = ismallint;
//     set iobigint = ismallint;
//     set iodecimal  = ismallint;
//     set ionumeric  = ismallint;
//     set iofloat = ismallint;
//     set ioreal = ismallint;
//     set iodouble = ismallint;
//     set iochar  = ismallint;
//     set iovarchar = ismallint;
//     set iodate = now();
//     set iotime = now();
//     set iotimestamp = now();
// end;
         
// call  qgpl.common_types  (
//     ismallint => 123,
//     osmallint =>?,
//     ointeger =>?,
//     obigint =>?,
//     odecimal  =>?,
//     onumeric  =>?,
//     ofloat =>?,
//     oreal =>?,
//     odouble =>?,
//     ochar =>?,
//     ovarchar =>?,
//     odate =>?,
//     otime =>?,
//     otimestamp =>?
// );

// ------------------------------------------------------------------------------------
dcl-proc commonTypes;

    // Build input parameter object
    pIn  = json_newObject();
    json_SetInt(pIn: 'ismallint' :   1);
    json_SetInt(pIn: 'iinteger' :   1);
    json_SetInt(pIn: 'ibigint' :   1);
    json_SetInt(pIn: 'idecimal' :    1);
    json_SetInt(pIn: 'inumeric' :    1);
    json_SetInt(pIn: 'ifloat' :   1);
    json_SetInt(pIn: 'ireal' :   1);
    json_SetInt(pIn: 'idouble' :   1);
    json_SetInt(pIn: 'ichar' :   1);
    json_SetInt(pIn: 'ivarchar' :   1);
    json_SetStr(pIn: 'idate' :   %char(%date()));
    json_SetStr(pIn: 'itime' :   %char(%time()));
    json_SetStr(pIn: 'itimestamp' :   %char(%timestamp()));
    json_SetInt(pIn: 'iosmallint' :   1);
    json_SetInt(pIn: 'iointeger' :   1);
    json_SetInt(pIn: 'iobigint' :   1);
    json_SetInt(pIn: 'iodecimal' :    1);
    json_SetInt(pIn: 'ionumeric' :    1);
    json_SetInt(pIn: 'iofloat' :   1);
    json_SetInt(pIn: 'ioreal' :   1);
    json_SetInt(pIn: 'iodouble' :   1);
    json_SetInt(pIn: 'iochar' :   1);
    json_SetInt(pIn: 'iovarchar' :   1);
    json_SetStr(pIn: 'iodate' :   %char(%date()));
    json_SetStr(pIn: 'iotime' :   %char(%time()));
    json_SetStr(pIn: 'iotimestamp' :   %char(%timestamp()));
  
    // Call the procedure
    pOut = json_sqlCall ('qgpl.common_types' : pIn);

    If json_Error(pOut) ;
      msg = json_Message(pOut);
      dsply msg;
    EndIf;
    
    // Dump the result
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/procparms.json':1208:*OFF);

    json_delete(pIn);
    json_delete(pOut);

end-proc;

dcl-proc commonTypesNegative;

    // Build input parameter object
    pIn  = json_newObject();
    json_SetInt(pIn: 'ismallint' :   -1);
  
    // Call the procedure
    pOut = json_sqlCall ('qgpl.common_types' : pIn);

    If json_Error(pOut) ;
      msg = json_Message(pOut);
      dsply msg;
    EndIf;
    
    // Dump the result
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/procparms.json':1208:*OFF);

    json_delete(pIn);
    json_delete(pOut);

end-proc;

dcl-proc commonTypesNull;

    // Build input parameter object
    pIn  = json_newObject();
    json_SetNull(pIn: 'ismallint' );
  
    // Call the procedure
    pOut = json_sqlCall ('qgpl.common_types' : pIn);

    If json_Error(pOut) ;
      msg = json_Message(pOut);
      dsply msg;
    EndIf;
    
    // Dump the result
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/procparms.json':1208:*OFF);

    json_delete(pIn);
    json_delete(pOut);

end-proc;

// ------------------------------------------------------------------------------------
// performance  - inout parameter usecase 
// 
// Create the procedure from ACS. Maybe change the schema location 
// 
// create or replace procedure qgpl.inc (
//     inout a int
// ) 
// begin 
//     set a = a + 1;
// end;
// call inc (a=>123);
// ------------------------------------------------------------------------------------
dcl-proc performance;

    dcl-s i	            int(10);
    dcl-s iterations	int(10);
    dcl-s elapsed       int(20);
    dcl-s before	    timestamp;

    // Build input parameter object
    pIn  = json_newObject();
    json_SetInt(pIn: 'a': 1);

    // Call the procedure a numer of times
    before = %timestamp(); 
    iterations = 1000;

    for i = 1 to iterations;
        pOut = json_sqlCall ('qgpl.inc' : pIn);

        If json_Error(pOut) ;
            msg = json_Message(pOut);
            dsply msg;
            leave;
        EndIf;
        // json_joblog(pOut);
        json_copyvalue (pIn : 'a' : pOut : 'a');
        // Always delte the output object, it will produce a new in next iteration       
        json_delete(pOut);
    endfor;

    elapsed = %diff (%timestamp() : before : *MSECONDS );
    json_joblog(%char (iterations) + ' iteratinons in ' + %char(elapsed / 1000.0) + ' milliseconds');
		

    json_delete(pIn);

end-proc;

