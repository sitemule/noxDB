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


    // This is not neede, but illustrates that you can pull the meta data as PCML (XML)
    getTheMeta();

    // This is not neede, but illustrates that you can pull the meta data as JSON (converted)
    getTheMetaJson();

    // this does the real job
    callProcedureByObject();

    // another way to do the same:
    callProcedureByString();

    // Datatypes supported
    callProcedureAllTypes();

    // Level of complexity supported
    callProcedureComplex();

    // Structure in - structure out
    callProcedureEcho();

    // External described ds
    callProcedureCustomer();


    // That's it..
    *inlr = *on;


// ------------------------------------------------------------------------------------
// getTheMeta
// ------------------------------------------------------------------------------------
dcl-proc getTheMeta;

    Dcl-S pMeta      Pointer;

    // Get meta info from a ILE program:
    // Note - this will be in PCML format a.k.a XML, but in the object graph
    pMeta = json_ProcedureMeta ('*LIBL' : 'HELOSRVPGM': '*ALL');

    // Just dump the result to both joblog and IFS stream file since it is XML by nature:
    json_WriteXMLStmf(pMeta:'/prj/noxdb/testout/srvpgmmeta.xml':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pMeta);

end-proc;
// ------------------------------------------------------------------------------------
// getTheMeta
// ------------------------------------------------------------------------------------
dcl-proc getTheMetaJson;

    Dcl-S pMeta      Pointer;

    // Get meta info from a ILE program:
    // Note - this will be in PCML format a.k.a XML, but in the object graph
    pMeta = json_ApplicationMetaJson ('*LIBL' : 'HELOSRVPGM': '*SRVPGM');

    // Just dump the result to both joblog and IFS stream file since it is XML by nature:
    json_WriteJsonStmf(pMeta:'/prj/noxdb/testout/srvpgmmeta.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pMeta);

end-proc;
// ------------------------------------------------------------------------------------
// callProcedureByObject
// ------------------------------------------------------------------------------------
dcl-proc callProcedureByObject;

    Dcl-S pIn        Pointer;
    Dcl-S pOut       Pointer;
    Dcl-s msg        char(50);

    // Setup an object and call
    pIn = json_newObject();
    json_setStr (pIn: 'name': 'John');
    json_setInt (pIn: 'age' : 25);


    pOut  = json_CallProcedure  ('*LIBL' : 'HELOSRVPGM' : 'NAMEAGE' : pIn : JSON_GRACEFUL_ERROR);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
        return;
    EndIf;


    // Dump the result to both joblog and IFS stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/srvpgmNameAge1.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pIn);
    json_delete (pOut);

end-proc;
// ------------------------------------------------------------------------------------
// call Procedure By String
// ------------------------------------------------------------------------------------
dcl-proc callProcedureByString;

    Dcl-S pOut       Pointer;
    Dcl-s msg        char(50);

   // Set your delimiter according to your CCSID of your source file if you parse any strings.
   // Note the "makefile" is set to international - ccsid 500 for all source files in the examples
   json_setDelimitersByCcsid(500);


    pOut  = json_CallProcedure  ('*LIBL' : 'HELOSRVPGM' : 'NAMEAGE' :
        '{"name":"John","age":41}':
        JSON_GRACEFUL_ERROR
    );
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
        return;
    EndIf;

    // Dump the result to both joblog and IFS stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/srvpgmNameAge2.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete (pOut);

end-proc;
// ------------------------------------------------------------------------------------
// callProcedureAllTypes
// ------------------------------------------------------------------------------------
dcl-proc callProcedureAllTypes;

    Dcl-S pIn        Pointer;
    Dcl-S pOut       Pointer;
    Dcl-s msg        char(50);

    // Setup an object and call
    pIn = json_newObject();
    json_setStr  (pIn: 'char'   : 'abc');
    json_setStr  (pIn: 'varchar': 'hello');
    json_setInt  (pIn: 'int8'   : -1234);
    json_setInt  (pIn: 'int4'   : -1234);
    json_setInt  (pIn: 'int2'   : -1234);
    json_setInt  (pIn: 'uns8'   : 1234);
    json_setInt  (pIn: 'uns4'   : 1234);
    json_setInt  (pIn: 'uns2'   : 123);
    json_setNum  (pIn: 'packed' : -2345.67);
    json_setNum  (pIn: 'zoned'  : -123456.7891);
    json_setBool (pIn: 'bool'   : *ON);
    json_setDate (pIn: 'date'   : %date());
    json_setTime (pIn: 'time'   : %time());
    json_setTimeStamp  (pIn: 'timestamp'   : %timestamp());

    pOut  = json_CallProcedure  ('*LIBL' : 'HELOSRVPGM' : 'ALLTYPES' : pIn : JSON_GRACEFUL_ERROR);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
        return;
    EndIf;

    // Dump the result to both joblog and IFS stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/srvpgmalltypes.json':1208:*OFF);


// Always clean up
on-exit;
    json_delete(pIn);
    json_delete (pOut);

end-proc;

// ------------------------------------------------------------------------------------
// Structure as input/output
// ------------------------------------------------------------------------------------
dcl-proc callProcedureComplex;

    Dcl-S pIn        Pointer;
    Dcl-S pOut       Pointer;
    Dcl-s msg        char(50);

    // Setup an object and call
    pIn = json_parseString (
        '{-
            "id" : 9876543210, -
    	    "employee":{ -
    	    	"id":123456789, -
    	    	"name":"John Doe", -
    	    	"age":25, -
    	    	"income":12345.67, -
    	    	"birthDate":"2025-07-08", -
    	    	"birthTime":"15.36.26", -
    	    	"updated":"2025-07-08-15.36.26.416393", -
    	    	"isMale":true -
    	    } -
    	}'
    );

    pOut  = json_CallProcedure  ('*LIBL' : 'HELOSRVPGM' : 'COMPLEX' : pIn : JSON_GRACEFUL_ERROR);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
    EndIf;

    // Dump the result to both joblog and IFS stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/srvpgmcomplex.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pIn);
    json_delete (pOut);

end-proc;

// ------------------------------------------------------------------------------------
// Structure input / Structure output
// ------------------------------------------------------------------------------------
dcl-proc callProcedureEcho;

    Dcl-S pIn        Pointer;
    Dcl-S pOut       Pointer;
    Dcl-s msg        char(50);

    // Setup an object and call
    pIn = json_parseString (
        '{-
    	    "employee_in":{ -
    	    	"id":123456789, -
    	    	"name":"John Doe", -
    	    	"age":25, -
    	    	"income":12345.67, -
    	    	"birthDate":"2025-07-08", -
    	    	"birthTime":"15.36.26", -
    	    	"updated":"2025-07-08-15.36.26.416393", -
    	    	"isMale":true -
    	    } -
    	}'
    );

    pOut  = json_CallProcedure  ('*LIBL' : 'HELOSRVPGM' : 'ECHO' : pIn : JSON_GRACEFUL_ERROR);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
    EndIf;

    // Dump the result to both joblog and IFS stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/srvpgmecho.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pIn);
    json_delete (pOut);

end-proc;

// ------------------------------------------------------------------------------------
// External described datastructures
// ------------------------------------------------------------------------------------
dcl-proc callProcedureCustomer;

    Dcl-S pIn        Pointer;
    Dcl-S pOut       Pointer;
    Dcl-s msg        char(50);

    pIn = json_newObject();
    // Move the result set from a SQL statement into the JSON object
    // This result in an array of object with customers
    json_moveObjectInto (pIn : 'customer_in' :json_sqlResultSet ('select * from QIWS/QCUSTCDT'));
    json_WriteJsonStmf(pIb:'/prj/noxdb/testout/srvpgmCustomerIn.json':1208:*OFF);


    pOut  = json_CallProcedure  ('*LIBL' : 'HELOSRVPGM' : 'CUSTOMER' : pIn : JSON_GRACEFUL_ERROR);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
    EndIf;

    // Dump the result to both joblog and IFS stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/srvpgmCustomerOut.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pIn);
    json_delete (pOut);

end-proc;
