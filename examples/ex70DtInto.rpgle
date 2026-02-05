**FREE
// ------------------------------------------------------------------------------------
// noxDB - Not only XML. JSON, SQL and XML made easy for RPG
//
// Company . . . : System & Method A/S - Sitemule
// Design  . . . : Niels Liisberg
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
// Using the "data-into" RPG operation to map JSON data into RPG data structures
// This example shows several ways to do this. Look at the comments in each example
// for details.
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
//
// try/build:
// cd '/prj/NOXDBUTF8'
// addlible NOXDBUTF8
// chgjobccsid(500)
// call ...
// ------------------------------------------------------------------------------------
Ctl-Opt copyright('Sitemule - System & Method (C), 2025');
Ctl-Opt BndDir('NOXDBUTF8') CCSID(*CHAR:*JOBRUN); // CCSID(*CHAR:*UTF8);
Ctl-Opt dftactgrp(*NO) ACTGRP('QILE') option(*nodebugio:*srcstmt:*nounref) ALWNULL(*USRCTL);
Ctl-Opt main(main) ;

/include qrpgleref,noxDbUtf8

// Global connection pointer
dcl-s pCon         pointer;

// ------------------------------------------------------------------------------------
dcl-proc main;
    dcl-s memuse       int(20);

    // Take a snapshot of the memory usage before we start
    memuse = nox_memUse();

    // Setup trace/debugging ( or perhaps unit testing) for
    // your code if you like - this is optional
    // myTrace is defined in the bottom in the example
    // Note - you can disable the trace by setting it to *NULL
    nox_setTraceProc (%paddr(myTrace));

    // Connect to the database - using the noxDbUtf8 driver. This is global for all examples
    pCon = nox_sqlConnect();

    example1();
    example2();
    example3();
    example4();
    example5();
    example6();

// Always remember to delete used memory !!
on-exit;
    nox_sqlDisconnect(pCon);
    if memuse <> nox_memuse();
        nox_joblog( 'Ups - forgot to clean something up');
    endif;

end-proc;

// ------------------------------------------------------------------------------------
// Parse a string put into a datastructure
// ------------------------------------------------------------------------------------
dcl-proc example1;


    // This is the data structure we map the object graph into:
    // The name "rows" is in the data-into statement
    // The "dim" causes it to be an array:
    dcl-DS rows dim(100) qualified inz;
        name     varchar(256);
        id       int(10);
        country  varchar(256);
    end-ds;

    dcl-s pJson      pointer;
    dcl-s i	         int(10);

    // This is our array of objects:
    pJson = nox_ParseString(
        '[                                 -
            {"id":1,"name":"John"  },        -
            {"id":2,"name":"Doe","age":25} -
        ]'
    );

    // Now the magic: the pJson object graph is send to the mapper
    // Note the second parm of %data controls you mapping - look at:
    // https://www.ibm.com/support/knowledgecenter/en/ssw_ibm_i_74/rzasd/dataintoopts.htm
    // In this examples we have the extra "country" in
    // the json and are missing the "age" in the structure
    // So we set 'allowextra=yes allowmissing=yes'
    // However; Leave them out if You need a strictt mapping
    data-into rows %data('':'allowextra=yes allowmissing=yes') %parser(nox_DataInto(pJson));


    // Now we can use it from data structures:
    for i = 1 to %elem(rows) ;
        if rows(i).id = 0;
            leave;
        endif;
        nox_joblog(%char(rows(i).name));
    endfor;

// Always remember to delete used memory !!
on-exit;
    nox_delete(pJson);

end-proc;
// ------------------------------------------------------------------------------------
// Get a resultset and place it into a row structure - row by row
// This showcase that you dont neet to map the complete (json) object graph
// but can process row by row. Here we use strict mapping btw.
// ------------------------------------------------------------------------------------
dcl-proc example2;


    // This is the data structure we map the object graph into:
    // The name "rows" is in the data-into statement
    // The "dim" causes it to be an array:
    dcl-ds qcustcdt  extname('QIWS/QCUSTCDT') qualified inz  end-ds;
    dcl-ds list      likeds(nox_iterator);
    dcl-s  pJson     pointer;
    dcl-s  pRow      pointer;
    dcl-s  i	     int(10);


    pJson = nox_sqlResultSet (pCon: 'Select * from qiws.qcustcdt');

    list = nox_setIterator(pJson);
    dow  nox_ForEach(list);
        // Now the magic: the pJson object graph is send to the mapper
        myTrace ('Row' : list.this);
        data-into qcustcdt %data('':'') %parser(nox_DataInto(list.this));
    enddo;

// Always remember to delete used memory !!
on-exit;
    nox_delete(pJson);

end-proc;
// ------------------------------------------------------------------------------------
// Get a resultset and place it into a row structure - load an array
// This showcase that you dont neet to map the complete (json) object graph
// but can process row by row. Here we use strict mapping btw.
// ------------------------------------------------------------------------------------
dcl-proc example3;


    // This is the data structure we map the object graph into:
    // The name "rows" is in the data-into statement
    // The "dim" causes it to be an array:
    dcl-ds qcustcdt  extname('QIWS/QCUSTCDT') qualified dim(100) inz  end-ds;
    dcl-s  pJson     pointer;

    pJson = nox_sqlResultSet (pCon:'Select * from qiws.qcustcdt');
    myTrace ('Array' : pJson);

    // Now the magic: the pJson object graph is send to the mapper
    data-into qcustcdt %data('':'') %parser(nox_DataInto(pJson));

// Always remember to delete used memory !!
on-exit;
    nox_delete(pJson);

end-proc;
// ------------------------------------------------------------------------------------
// Get a resultrow and place it into a row structure - load an array
// This showcase that you dont neet to map the complete (json) object graph
// but can process row by row. Here we use strict mapping btw.
// ------------------------------------------------------------------------------------
dcl-proc example4;


    // This is the data structure we map the object graph into:
    // The name "rows" is in the data-into statement
    // The "dim" causes it to be an array:
    dcl-ds qcustcdt  extname('QIWS/QCUSTCDT') qualified  inz  end-ds;
    dcl-s  pJson     pointer;

    pJson = nox_sqlResultRow  (pCon:
        'select * from qiws.qcustcdt where cusnum = 389572'
    );

    myTrace ('Single row' : pJson);

    // Now the magic: the pJson object graph is send to the mapper
    data-into qcustcdt %data('':'') %parser(nox_DataInto(pJson));

// Always remember to delete used memory !!
on-exit;
    nox_delete(pJson);

end-proc;
// ------------------------------------------------------------------------------------
// Example of aliases
// Get a resultset and place it into a row structure - row by row
// This showcase that you dont neet to map the complete (json) object graph
// but can process row by row. Here we use strict mapping btw.
// ------------------------------------------------------------------------------------
dcl-proc example5;


    // This is the data structure we map the object graph into:
    dcl-ds customerTemplate extname('QIWS/QCUSTCDT') qualified end-ds;
    dcl-ds customerTemplate_Alias extname('QIWS/QCUSTCDT') alias qualified end-ds;
    dcl-ds customer likeds(customerTemplate) dim(1) inz;
    dcl-ds customer_Alias likeds(customerTemplate_Alias) dim(1) inz;

    dcl-s  pJson     pointer;
    dcl-s  pRow      pointer;
    dcl-s  i	     int(10);

    pJson = nox_sqlResultSet (pCon:
        'select * from qiws.qcustcdt where cusnum = 389572':
        *null:
        NOX_ROWNOX_ARRAY + NOX_SYSTEM_CASE:
        1:
        1
    );

    myTrace ('one row in array' : pJson);

    // Here we give it uppercase names ( lower is default but upper, lower or any works)
    data-into customer       %data('':'case=upper') %parser(nox_DataInto(pJson));
    data-into customer_Alias %data('':'case=any') %parser(nox_DataInto(pJson));

// Always remember to delete used memory !!
on-exit;
    nox_delete(pJson);

end-proc;
// ------------------------------------------------------------------------------------
// UTF-8
// 1) Here we use SYSTEM_CASE to get the exact names as in the database
// that is uppercase and we tell data-into to use upper case names  as well
// 2) we are using the "alias" to get the same structure but with alias names in
// that is provided by noxDb.
//
// this is the best practice
// ------------------------------------------------------------------------------------
dcl-proc example6;


    // This is the data structure we map the object graph into:
    // The name "rows" is in the data-into statement
    // The "dim" causes it to be an array:
    dcl-ds stock       extname('NOXDBDEMO/STOCK') qualified alias dim(100) inz  end-ds;
    dcl-s  pJson       pointer;
    dcl-s  pOutputRows pointer;
    dcl-s  handle      char(1);

    pJson = nox_sqlResultSet (pCon:
        'Select * from noxdbdemo.stock':
        *null:
        NOX_ROWNOX_ARRAY + NOX_SYSTEM_CASE
    );

    myTrace ('UTF-8' : pJson);

    // Now the magic: the pJson object graph is send to the mapper
    data-into stock
        %data('':'case=upper allowextra=yes allowmissing=yes')
        %parser(nox_DataInto(pJson));

    // and produce a output JSON file from the datastructure
    data-gen %subarr(stock:1:nox_GetLength(pJson))
        %data(handle:'')
        %gen (nox_DataGen(pOutputRows));
        //%gen (nox_DataGen(pOutputRows):'case=upper');

    nox_WriteJsonStmf(pOutputRows:'/prj/noxdbutf8/testout/ex70-Data-Into-1.json':1208:*OFF);



// Always remember to delete used memory !!
on-exit;
    nox_delete(pJson);

end-proc;

// ------------------------------------------------------------------------------------
// myTrace - an example of a trace procedure for debugging and unit test
// This will be called each time you interact with the objec graph - if set by
// nox_SetTraceProc ( %paddr(myTrace));
// ------------------------------------------------------------------------------------
dcl-proc myTrace;

    dcl-pi myTrace ;
        text  char(30) const;
        pNode pointer value;
    end-pi;

    dcl-s action char(30);
    dcl-s showme varchar(32000);

    // I could just have it in variables that i debug
    action = text;
    showme = nox_AsJsonText(pNode);

    // .. And I could put it into the joblog
    nox_joblog(Text);
    nox_joblog(showme);

    // Or maybe put it into a stream file
    //nox_WriteJsonStmf(pJson:'/prj/noxdbutf8/testout/trace.json':1208:*OFF);

    // Or place it into a trace table.. Up to you !!


end-proc;

