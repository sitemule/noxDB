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
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE')  main(main);
/include qrpgleRef,noxdb

dcl-proc main;

    // Set your delimiter according to your CCSID of your source file if you parse any strings.
    // This is only requires if job ccsid and source file ccsid is not the same.
    // Note the "makefile" is set to international - ccsid 500 for all source files in the examples
    json_setDelimitersByCcsid(500);

    // This is not neede, but illustrates that you can pull the meta data as PCML (XML)
    getTheMeta();

    // This is not neede, but illustrates that you can pull the meta data as JSON (converted)
    getTheMetaJson();

    // Arrays
    callSimpleArray();

    // Nested Arrays
    callNestedArray();

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

    // External described ds and *VAR structures
    // Need some stuff from IBM
    callProcedureCustomerVar();

    // Nested datastructure
    callProcedureCustomerNested();

    // Nested array of datastructure
    callProcedureCustomerNestedList();

on-exit;
    // Disconnect from the database
    json_sqlDisconnect();

    // Reset delimiters to default when you are done: 0= job ccsid
    json_setDelimitersByCcsid(0);


end-proc;
// ------------------------------------------------------------------------------------
// getTheMeta - is not need but show the PCML we have in the noxDb graph
// ------------------------------------------------------------------------------------
dcl-proc getTheMeta;

    dcl-s pMeta      pointer;

    // Get meta info from a ILE program:
    // Note - this will be in PCML format a.k.a XML, but in the object graph
    pMeta = json_ProcedureMeta ('*LIBL' : 'JSONPGM00B': '*ALL');

    // Just dump the result to IFS stream file since it is XML by nature:
    json_WriteXMLStmf(pMeta:'/prj/noxdb/testout/jsonpgm01b-meta.xml':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pMeta);

end-proc;
// ------------------------------------------------------------------------------------
// getTheMeta as JSON - is not need but show the nested JSON-like graph
// This is based on the PCML, but put in a nested JSON-like graph for easy
// use and works for both service programs and "normal" programs.
// ------------------------------------------------------------------------------------
dcl-proc getTheMetaJson;

    dcl-s pMeta      pointer;

    // Get meta info from a ILE program:
    // Note - this is based on the PCML, but put in a nested JSON-like graph for easy use
    // and works for both service programs and "normal" programs.
    pMeta = json_ApplicationMeta ('*LIBL' : 'JSONPGM00B': '*SRVPGM');

    // Just dump the result to IFS JSON stream file since it is JSON by nature:
    json_WriteJsonStmf(pMeta:'/prj/noxdb/testout/jsonpgm01b-meta.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pMeta);

end-proc;
// ------------------------------------------------------------------------------------
// callProcedureByObject
// ------------------------------------------------------------------------------------
dcl-proc callProcedureByObject;

    dcl-s pIn        pointer;
    dcl-s pOut       pointer;
    dcl-s msg        char(50);

    // Setup an object and call
    pIn = json_newObject();
    json_setStr (pIn: 'name': 'John');
    json_setInt (pIn: 'age' : 25);


    pOut  = json_CallProcedure  ('*LIBL' : 'JSONPGM00B' : 'nameAge' : pIn : JSON_GRACEFUL_ERROR);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
        return;
    EndIf;


    // Dump the result to both joblog and IFS stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/jsonpgm01b-NameAge1.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pIn);
    json_delete (pOut);

end-proc;
// ------------------------------------------------------------------------------------
// call Procedure By String
// ------------------------------------------------------------------------------------
dcl-proc callProcedureByString;

    dcl-s pOut       pointer;
    dcl-s msg        char(50);



    pOut  = json_CallProcedure  ('*LIBL' : 'JSONPGM00B' : 'nameAge' :
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
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/jsonpgm01b-NameAge2.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete (pOut);

end-proc;
// ------------------------------------------------------------------------------------
// Simple array
// ------------------------------------------------------------------------------------
dcl-proc callSimpleArray;

    dcl-s pIn        pointer;
    dcl-s pOut       pointer;
    dcl-s msg        char(50);

    pIn = json_parseString ('{"myArrayIn":[1,2,3,4,5]}');
    json_WriteJsonStmf(pIn:'/prj/noxdb/testout/jsonpgm01b-SimpleArrayIn.json':1208:*OFF);

    pOut  = json_CallProcedure  ('*LIBL' : 'JSONPGM00B' : 'simpleArray' : pIn : JSON_GRACEFUL_ERROR);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
    EndIf;

    // Dump the result to both joblog and IFS stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/jsonpgm01b-SimpleArrayOut.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pIn);
    json_delete (pOut);

end-proc;

// ------------------------------------------------------------------------------------
// Simple array
// ------------------------------------------------------------------------------------
dcl-proc callNestedArray;

    dcl-s pIn        pointer;
    dcl-s pOut       pointer;
    dcl-s msg        char(50);

    pIn = json_parseString ('-
    {-
       "myArrayIn":[-
           {"intArray":[1,2]}, -
           {"intArray":[3,4]}, -
           {"intArray":[5,6]}, -
           {"intArray":[7,8]}, -
           {"intArray":[9,0]}, -
        ] -
    }');
    json_WriteJsonStmf(pIn:'/prj/noxdb/testout/jsonpgm01b-SimpleNestedArrayIn.json':1208:*OFF);

    pOut  = json_CallProcedure  ('*LIBL' : 'JSONPGM00B' : 'simpleNestedArray' : pIn : JSON_GRACEFUL_ERROR);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
    EndIf;

    // Dump the result to both joblog and IFS stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/jsonpgm01b-SimpleNestedArrayOut.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pIn);
    json_delete (pOut);

end-proc;

// ------------------------------------------------------------------------------------
// callProcedureAllTypes
// ------------------------------------------------------------------------------------
dcl-proc callProcedureAllTypes;

    dcl-s pIn        pointer;
    dcl-s pOut       pointer;
    dcl-s msg        char(50);

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

    pOut  = json_CallProcedure  ('*LIBL' : 'JSONPGM00B' : 'allTypes' : pIn : JSON_GRACEFUL_ERROR);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
        return;
    EndIf;

    // Dump the result to both joblog and IFS stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/jsonpgm01b-alltypes.json':1208:*OFF);


// Always clean up
on-exit;
    json_delete(pIn);
    json_delete (pOut);

end-proc;

// ------------------------------------------------------------------------------------
// Structure as input/output
// ------------------------------------------------------------------------------------
dcl-proc callProcedureComplex;

    dcl-s pIn        pointer;
    dcl-s pOut       pointer;
    dcl-s msg        char(50);

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

    pOut  = json_CallProcedure  ('*LIBL' : 'JSONPGM00B' : 'complex' : pIn : JSON_GRACEFUL_ERROR);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
    EndIf;

    // Dump the result to both joblog and IFS stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/jsonpgm01b-complex.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pIn);
    json_delete (pOut);

end-proc;

// ------------------------------------------------------------------------------------
// Structure input / Structure output
// ------------------------------------------------------------------------------------
dcl-proc callProcedureEcho;

    dcl-s pIn        pointer;
    dcl-s pOut       pointer;
    dcl-s msg        char(50);

    // Setup an object and call
    pIn = json_parseString (
        '{-
    	    "employeeIn":{ -
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
    json_WriteJsonStmf(pIn:'/prj/noxdb/testout/jsonpgm01b-echoIn.json':1208:*OFF);

    pOut  = json_CallProcedure  ('*LIBL' : 'JSONPGM00B' : 'echo' : pIn : JSON_GRACEFUL_ERROR);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
    EndIf;

    // Dump the result to both joblog and IFS stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/jsonpgm01b-echoOut.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pIn);
    json_delete (pOut);

end-proc;

// ------------------------------------------------------------------------------------
// External described datastructures
// ------------------------------------------------------------------------------------
dcl-proc callProcedureCustomer;

    dcl-s pIn        pointer;
    dcl-s pOut       pointer;
    dcl-s msg        char(50);

    pIn = json_newObject();
    // Move the result set from a SQL statement into the JSON object
    // This result in an array of object with customers
    json_moveObjectInto (pIn : 'customerIn' :json_sqlResultSet ('select * from QIWS/QCUSTCDT'));
    json_WriteJsonStmf(pIn:'/prj/noxdb/testout/jsonpgm01b-CustomerIn.json':1208:*OFF);


    pOut  = json_CallProcedure  ('*LIBL' : 'JSONPGM00B' : 'customer' : pIn : JSON_GRACEFUL_ERROR);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
    EndIf;

    // Dump the result to both joblog and IFS stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/jsonpgm01b-CustomerOut.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pIn);
    json_delete (pOut);

end-proc;

// ------------------------------------------------------------------------------------
// External described datastructures
// ------------------------------------------------------------------------------------
dcl-proc callProcedureCustomerVar;

    dcl-s pIn        pointer;
    dcl-s pOut       pointer;
    dcl-s msg        char(50);

    pIn = json_newObject();
    // Move the result set from a SQL statement into the JSON object
    // This result in an array of object with customers
    json_moveObjectInto (pIn : 'customerIn' :json_sqlResultSet ('select * from QIWS/QCUSTCDT'));
    json_WriteJsonStmf(pIn:'/prj/noxdb/testout/jsonpgm01b-CustomerVarIn.json':1208:*OFF);


    pOut  = json_CallProcedure  ('*LIBL' : 'JSONPGM00B' : 'customerVar' : pIn : JSON_GRACEFUL_ERROR);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
    EndIf;

    // Dump the result to both joblog and IFS stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/jsonpgm01b-CustomerVarOut.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pIn);
    json_delete (pOut);

end-proc;

// ------------------------------------------------------------------------------------
// Nested datastructures
// ------------------------------------------------------------------------------------
dcl-proc callProcedureCustomerNested;

    dcl-s pRow      pointer;
    dcl-s pCust      pointer;
    dcl-s pIn        pointer;
    dcl-s pOut       pointer;
    dcl-s msg        char(50);

    pRow = json_sqlResultRow ('select * from QIWS.QCUSTCDT');

    // reformat the flat list in t array with objects
    pCust = json_newObject();
    json_setInt (pCust:'id'  : json_getInt(pRow:'CUSNUM'));
    json_setStr (pCust:'name': json_getStr(pRow:'LSTNAM'));
    json_setStr (pCust:'address.Street': json_getStr(pRow:'STREET'));
    json_setStr (pCust:'address.City': json_getStr(pRow:'CITY'));
    json_setStr (pCust:'address.State': json_getStr(pRow:'STATE'));
    json_setStr (pCust:'address.Postal': json_getStr(pRow:'ZIPCOD'));
    json_setInt (pCust:'cmsInfo.creditLimit': json_getInt(pRow:'CDTLMT'));
    json_setInt (pCust:'cmsInfo.chargeCode': json_getInt(pRow:'CHGCOD'));
    json_setNum (pCust:'cmsInfo.balanceDue': json_getNum(pRow:'BALDUE'));
    json_setNum (pCust:'cmsInfo.creditDue': json_getNum(pRow:'CDTDUE'));

    pIn = json_newObject();

    // Move the result set from a SQL statement into the JSON object
    // This result in an object with a customer
    json_moveObjectInto (pIn : 'customerIn' :pCust);
    json_WriteJsonStmf(pIn:'/prj/noxdb/testout/jsonpgm01b-CustomerNestedIn.json':1208:*OFF);


    pOut  = json_CallProcedure  ('*LIBL' : 'JSONPGM00B' : 'customerNested' : pIn : JSON_GRACEFUL_ERROR);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
        return;
    EndIf;

    // Dump the result to both joblog and IFS stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/jsonpgm01b-CustomerNestedOut.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pRow);
    json_delete(pIn);
    json_delete (pOut);

end-proc;

// ------------------------------------------------------------------------------------
// Nested datastructures
// ------------------------------------------------------------------------------------
dcl-proc callProcedureCustomerNestedList;

    dcl-s pRows      pointer;
    dcl-s pCust      pointer;
    dcl-s pCustArray pointer;
    dcl-s pIn        pointer;
    dcl-s pOut       pointer;
    dcl-s msg        char(50);
    dcl-ds list               likeds(json_iterator);

    pRows = json_sqlResultSet ('select * from QIWS.QCUSTCDT');
    pCustArray = json_newArray();

    // reformat the flat list in t array with objects
    list = json_setIterator(pRows);
    DoW json_ForEach(list);
        pCust = json_newObject();
        json_setInt (pCust:'id'  : json_getInt(list.this:'CUSNUM'));
        json_setStr (pCust:'name': json_getStr(list.this:'LSTNAM'));
        json_setStr (pCust:'address.Street': json_getStr(list.this:'STREET'));
        json_setStr (pCust:'address.City': json_getStr(list.this:'CITY'));
        json_setStr (pCust:'address.State': json_getStr(list.this:'STATE'));
        json_setStr (pCust:'address.Postal': json_getStr(list.this:'ZIPCOD'));
        json_setInt (pCust:'cmsInfo.creditLimit': json_getInt(list.this:'CDTLMT'));
        json_setInt (pCust:'cmsInfo.chargeCode': json_getInt(list.this:'CHGCOD'));
        json_setNum (pCust:'cmsInfo.balanceDue': json_getNum(list.this:'BALDUE'));
        json_setNum (pCust:'cmsInfo.creditDue': json_getNum(list.this:'CDTDUE'));
        json_arrayPush (pCustArray : pCust);
    EndDo;

    pIn = json_newObject();

    // Move the result set from a SQL statement into the JSON object
    // This result in an array of object with customers
    json_moveObjectInto (pIn : 'customerIn' :pCustArray);
    json_WriteJsonStmf(pIn:'/prj/noxdb/testout/jsonpgm01b-CustomerNestedListIn.json':1208:*OFF);


    pOut  = json_CallProcedure  ('*LIBL' : 'JSONPGM00B' : 'customerNestedList' : pIn : JSON_GRACEFUL_ERROR);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
        return;
    EndIf;

    // Dump the result to both joblog and IFS stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/jsonpgm01b-CustomerNestedListOut.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pRows);
    json_delete(pIn);
    json_delete (pOut);

end-proc;
