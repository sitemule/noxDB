**free
// ------------------------------------------------------------------------------------
// noxDB - Not Only Xml - Its JSON, XML, SQL and more
//
// This tutorial will show how the get data with SQL in noxDb
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
// This sample uses the demo SQL schema made from ACS run SQL scripts:
// call qsys.create_sql_sample('CORPDATA');
//
//
// try/build:
// cd '/prj/NOXDBUTF8'
// addlible NOXDBUTF8
// chgjobccsid(500)
// call
// ------------------------------------------------------------------------------------
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

// ------------------------------------------------------------------------------------
// Load a graph with data from a Db2 table and export it as JSON and XML
// Default is a simple array of rows
// ------------------------------------------------------------------------------------
dcl-proc example1;


    dcl-s pEmployees   pointer;
    dcl-s Msg          varchar(1024) ccsid(*jobrun);

    // Load all employees into a graph and return the pointer to the graph object
    pEmployees = nox_sqlResultSet(pCon:
        'select *                -
         from corpdata.employee  -
    ');

    // Was there a problem ?   If so - write the message to the joblog and return
    // Note we use an on-error to clean up
    if Nox_Error(pEmployees) ;
        msg = nox_Message(pEmployees);
        nox_joblog ( msg );
        return;
    endif;

    // Let's see what we got - both as JSON and XML
    // note the 1208 is the UTF-8 CCSID and optional.
    // note the *OFF for indented output. When *ON to get a condensed output
    nox_WriteJsonStmf(pEmployees:'/prj/noxDbUtf8/testout/ex20-employees1.json':1208:*OFF);
    nox_WriteXmlStmf (pEmployees:'/prj/noxDbUtf8/testout/ex20-employees1.xml' :1208:*OFF);


// Always remember to delete used memory !!
on-exit;
    nox_delete(pEmployees);

end-proc;
// ------------------------------------------------------------------------------------
// Load a graph with data from a Db2 table and export it as JSON and XML
// note - by default columns are in camelCase
// ------------------------------------------------------------------------------------
dcl-proc example2;


    dcl-s pStock   pointer;
    dcl-s Msg          varchar(1024) ccsid(*jobrun);

    // Load all employees into a graph and return the pointer to the graph object
    pStock = nox_sqlResultSet(pCon:
        'select -
          sku,-
          department ,-
          main_category,-
          sub_category -
        from noxdbdemo.stock '
    );

    // Was there a problem ?   If so - write the message to the joblog and return
    // Note we use an on-error to clean up
    if Nox_Error(pStock) ;
        msg = nox_Message(pStock);
        nox_joblog ( msg );
        return;
    endif;


    // Let's see what we got - both as JSON and XML - detault is 1208 and condensed
    // note: here we use UTF-8 with BOM code. That is CCSID 1208
    // note: *ON is condensed output
    nox_WriteJsonStmf(pStock:'/prj/noxDbUtf8/testout/ex20-stock1.json':NOX_UTF8_BOM:*ON);
    nox_WriteXmlStmf (pStock:'/prj/noxDbUtf8/testout/ex20-stock1.xml' :NOX_UTF8_BOM:*ON);


// Always remember to delete used memory !!
on-exit;
    nox_delete(pStock);

end-proc;
// ------------------------------------------------------------------------------------
// Load a graph with data from a Db2 table and export it as JSON and XML
// note - use the NOX_SYSTEM_CASE aka we give them by the select statement
// ------------------------------------------------------------------------------------
dcl-proc example3;

    dcl-s pStock   pointer;

    // Load all employees into a graph and return the pointer to the graph object
    // Note - we have implicit error hadling . If there is an error we get an error object back
    pStock = nox_sqlResultSet(pCon:
        'select -
          sku "SKU",-
          department "departmentName",-
          main_category "mainCategory",-
          sub_category "subCategory"-
        from noxdbdemo.stock':
        *null: // no parameters
        NOX_SYSTEM_CASE    +  // Use the names as they are - no camelCase
        NOX_GRACEFUL_ERROR +  // Errors are retuned as an error object
        NOX_META           +  // Include meta data about the result set
        NOX_FIELDS         +  // Include field descriptions
        NOX_TOTALROWS      :  // Include total rows in the meta data
        2 : // From row 2
        15  // Max 15 rows
    );


    // Let's see what we got
    // note here we use the default: CCSID 1208 aka UTF-8 and condensed output

    nox_WriteJsonStmf(pStock:'/prj/noxDbUtf8/testout/ex20-stock3.json');
    nox_WriteXmlStmf (pStock:'/prj/noxDbUtf8/testout/ex20-stock3.xml' );


// Always remember to delete used memory !!
on-exit;
    nox_delete(pStock);

end-proc;

// ------------------------------------------------------------------------------------
// NOX_SYSTEM_NAMES
// This shows the "for system name" feature of Db2 that is not available
// in other frameworks.
// ------------------------------------------------------------------------------------
dcl-proc example4;

    dcl-s pRows   pointer;

    // Load all employees into a graph and return the pointer to the graph object
    // Note - we have implicit error hadling . If there is an error we get an error object back
    pRows = nox_sqlResultSet(pCon:
        'select * from noxdbdemo.sysnames':
        *null: // no parameters
        NOX_SYSTEM_NAMES   +  // Use the "for system name" names and not the comlumn name
        NOX_SYSTEM_CASE    +  // Use the names as they are - no camelCase
        NOX_GRACEFUL_ERROR +  // Errors are retuned as an error object
        NOX_META           +  // Include meta data about the result set
        NOX_FIELDS         +  // Include field descriptions
        NOX_TOTALROWS         // Include total rows in the meta data
    );

    // Let's see what we got - both as JSON and XML - using default condensed UTF8
    nox_WriteJsonStmf(pRows:'/prj/noxDbUtf8/testout/ex20-sysnames.json');
    nox_WriteXmlStmf (pRows:'/prj/noxDbUtf8/testout/ex20-sysnames.xml' );


// Always remember to delete used memory !!
on-exit;
    nox_delete(pRows);

end-proc;


