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

    // This is not neede, but illustrates that you can pull the meta data as PCML (XML)
    getTheMeta();

    // This is not neede, but illustrates that you can pull the meta data as JSON (converted)
    getTheMetaJson();

    // Arrays
    // Nested datastructure
    callProcedureCustomerNested();

on-exit;
    // Disconnect from the database
    json_sqlDisconnect();

end-proc;
// ------------------------------------------------------------------------------------
// getTheMeta
// ------------------------------------------------------------------------------------
dcl-proc getTheMeta;

    dcl-s pMeta      pointer;

    // Get meta info from a ILE program:
    // Note - this will be in PCML format a.k.a XML, but in the object graph
    pMeta = json_ProcedureMeta ('*LIBL' : 'JSONPGM00C': '*ALL');

    // Just dump the result to IFS stream file since it is XML by nature:
    json_WriteXMLStmf(pMeta:'/prj/noxdb/testout/srvpgmmeta.xml':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pMeta);

end-proc;
// ------------------------------------------------------------------------------------
// getTheMeta
// ------------------------------------------------------------------------------------
dcl-proc getTheMetaJson;

    dcl-s pMeta      pointer;

    // Get meta info from a ILE program:
    // Note - this is based on the PCML, but put in a nested JSON-like graph for easy use
    // and works for both service programs and "normal" programs.
    pMeta = json_ApplicationMeta ('*LIBL' : 'JSONPGM00C': '*SRVPGM');

    // Just dump the result to IFS JSON stream file since it is JSON by nature:
    json_WriteJsonStmf(pMeta:'/prj/noxdb/testout/srvpgmmeta.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pMeta);

end-proc;
// ------------------------------------------------------------------------------------
// Nested datastructures
// ------------------------------------------------------------------------------------
dcl-proc callProcedureCustomerNested;

    dcl-s pRows      pointer;
    dcl-s pCust      pointer;
    dcl-s pCustArray pointer;
    dcl-s pIn        pointer;
    dcl-s pOut       pointer;
    dcl-s msg        char(50);
    dcl-ds list               likeds(json_iterator);

    pRows = json_sqlResultSet ('select * from QIWS/QCUSTCDT');
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
    json_WriteJsonStmf(pIn:'/prj/noxdb/testout/srvpgmCustomerNestedIn.json':1208:*OFF);


    pOut  = json_CallProcedure  ('*LIBL' : 'JSONPGM00C' : 'customerNested' : pIn : JSON_GRACEFUL_ERROR);
    If json_Error(pOut) ;
        msg = json_Message(pOut);
        dsply msg;
        return;

    EndIf;

    // Dump the result to both joblog and IFS stream file
    json_joblog(pOut);
    json_WriteJsonStmf(pOut:'/prj/noxdb/testout/srvpgmCustomerNestedOut.json':1208:*OFF);

// Always clean up
on-exit;
    json_delete(pRows);
    json_delete(pIn);
    json_delete (pOut);

end-proc;
