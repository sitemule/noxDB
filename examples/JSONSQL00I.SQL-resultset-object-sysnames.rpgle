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
// This showcase the differenct combinations of the "option" 
// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') option(*nodebugio:*srcstmt:*nounref) main(main);
/include qrpgleRef,noxdb

dcl-proc main;

    // Run the examples
    example1();
    example2();
    example3();
    example4();

    // Cleanup: disconnect from database
    json_sqlDisconnect();

end-proc;
// ------------------------------------------------------------------------------------
// example1 - Meta tag with fields
// ------------------------------------------------------------------------------------
dcl-proc example1;

    Dcl-S pRows              Pointer;

    // return a object with all rows
    pRows = json_sqlResultSet(
        'Select * from noxdbdemo.sysnames':
        1:                  // Position: Starting from row
        JSON_ALLROWS:       // Limit   : Number of rows to read
        JSON_META +         // Option  : Produce a result object with a "meta" object   
        JSON_FIELDS         // Option  : The "meta" object will contain column atributes 
    );         


    // Produce a JSON stream file in the IFS
    json_writeJsonStmf(pRows  :
        '/prj/noxdb/testout/resultset-object-fields.json' : 1208 : *ON
    );

    // Cleanup: Dispose the rows, arrays
    json_delete(pRows);

end-proc;  
// ------------------------------------------------------------------------------------
// example2 - Meta tag with fields and system names 
// ------------------------------------------------------------------------------------
dcl-proc example2;

    Dcl-S pRows              Pointer;

    // return a object with all rows
    pRows = json_sqlResultSet(
        'Select * from noxdbdemo.sysnames':
        1:                  // Position: Starting from row
        JSON_ALLROWS:       // Limit   : Number of rows to read
        JSON_META +         // Option  : Produce a result object with a "meta" object   
        JSON_FIELDS +       // Option  : The "meta" object will contain column atributes 
        JSON_SYSTEM_NAMES   // Option  : the names will be "for column" system name 
    );         


    // Produce a JSON stream file in the IFS
    json_writeJsonStmf(pRows  :
        '/prj/noxdb/testout/resultset-object-sysnames.json' : 1208 : *ON
    );

    // Cleanup: Dispose the rows, arrays
    json_delete(pRows);

end-proc;  
// ------------------------------------------------------------------------------------
// example3 - Meta tag with fields and column text 
// ------------------------------------------------------------------------------------
dcl-proc example3;

    Dcl-S pRows              Pointer;

    // return a object with all rows
    pRows = json_sqlResultSet(
        'Select * from noxdbdemo.sysnames':
        1:                  // Position: Starting from row
        JSON_ALLROWS:       // Limit   : Number of rows to read
        JSON_META +         // Option  : Produce a result object with a "meta" object   
        JSON_FIELDS +       // Option  : The "meta" object will contain column atributes 
        JSON_COLUMN_TEXT    // Option  : the "meta" will also contain the extra text/label info
    );         


    // Produce a JSON stream file in the IFS
    json_writeJsonStmf(pRows  :
        '/prj/noxdb/testout/resultset-object-column-text.json' : 1208 : *ON
    );

    // Cleanup: Dispose the rows, arrays
    json_delete(pRows);

end-proc;
// ------------------------------------------------------------------------------------
// example4 - Meta tag with fields,  system names AND column text 
// ------------------------------------------------------------------------------------
dcl-proc example4;

    Dcl-S pRows              Pointer;

    // return a object with all rows
    pRows = json_sqlResultSet(
        'Select * from noxdbdemo.sysnames':
        1:                  // Position: Starting from row
        JSON_ALLROWS:       // Limit   : Number of rows to read
        JSON_META +         // Option  : Produce a result object with a "meta" object   
        JSON_FIELDS +       // Option  : The "meta" object will contain column atributes 
        JSON_SYSTEM_NAMES + // Option  : the names will be "for column" system name 
        JSON_COLUMN_TEXT    // Option  : the "meta" will also contain the extra text/label info
    );         

    // Produce a JSON stream file in the IFS
    json_writeJsonStmf(pRows  :
        '/prj/noxdb/testout/resultset-object-sysnames-column-text.json' : 1208 : *ON
    );

    // Cleanup: Dispose the rows, arrays
    json_delete(pRows);

end-proc;
