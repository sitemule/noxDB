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

// Using the "data-into"

// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');

/include qrpgleRef,noxdb

    // Setup trace/debugging ( or perhaps unit testing) for 
    // your code if you like - this is optional
    // myTrace is defined in the bottom in the example 
    // Note - you can disable the trace by setting it to *NULL
    json_SetTraceProc (%paddr(myTrace));

    // Set the delimiters used to access the graph selector
    json_setDelimitersByCcsid();
 
    example1();
    example2();
    example3();
    example4();
    example5();
    
    
    *INLR = *ON;

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
    pJson = json_ParseString(   
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
    data-into rows %data('':'allowextra=yes allowmissing=yes') %parser(json_DataInto(pJson));
    
    
    // Now we can use it from data structures:
    for i = 1 to %elem(rows) ;
        if rows(i).id = 0;
            leave;
        endif;
        json_joblog(%char(rows(i).name));
    endfor;   

    
    // Always remember to delete used memory !!
    json_delete(pJson);

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
    dcl-ds list      likeds(json_iterator);
    dcl-s  pJson     pointer;
    dcl-s  pRow      pointer;
    dcl-s  i	     int(10);    


    pJson = json_sqlResultSet ('Select * from qiws.qcustcdt');

    list = json_setIterator(pJson);
    dow  json_ForEach(list);
        // Now the magic: the pJson object graph is send to the mapper
        myTrace ('Row' : list.this);
        data-into qcustcdt %data('':'') %parser(json_DataInto(list.this));
    enddo;

    // Always remember to delete used memory !!
    json_delete(pJson);

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

    pJson = json_sqlResultSet ('Select * from qiws.qcustcdt');
    myTrace ('Array' : pJson);

    // Now the magic: the pJson object graph is send to the mapper
    data-into qcustcdt %data('':'') %parser(json_DataInto(pJson));

    // Always remember to delete used memory !!
    json_delete(pJson);

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

    pJson = json_sqlResultRow  (
        'select * from qiws.qcustcdt where cusnum = 389572'
    ); 

    myTrace ('Single row' : pJson);

    // Now the magic: the pJson object graph is send to the mapper
    data-into qcustcdt %data('':'') %parser(json_DataInto(pJson));

    // Always remember to delete used memory !!
    json_delete(pJson);

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

    pJson = json_sqlResultSet (
        'select * from qiws.qcustcdt where cusnum = 389572':
        1:
        1:
        JSON_ROWARRAY + JSON_UPPERCASE
    );

    myTrace ('First' : pJson);

    // Here we give it uppercase names ( lower is default but upper, lower or any works)
    data-into customer       %data('':'case=upper') %parser(json_DataInto(pJson));
    data-into customer_Alias %data('':'case=any') %parser(json_DataInto(pJson));
    
 

    // Always remember to delete used memory !!
    json_delete(pJson);

end-proc;
// ------------------------------------------------------------------------------------
// myTrace - an example of a trace procedure for debugging and unit test
// This will be called each time you interact with the objec graph - if set by  
// json_SetTraceProc ( %paddr(myTrace));
// ------------------------------------------------------------------------------------
dcl-proc myTrace;

    dcl-pi myTrace ;
        text  char(30) const;
        pNode pointer value;
    end-pi;

    dcl-s action char(30);
    dcl-s showme varchar(32000);

    // I could put it into the joblog
    json_joblog(Text); 
    json_joblog(pNode); 

    // Or I could just have it in variables that i debug
    action = text;
    showme = json_AsJsonText(pNode);

    // Or maybe put it into a stream file
    //json_WriteJsonStmf(pJson:'/prj/noxdb/testout/trace.json':1208:*OFF);

    // Or place it into a trace table.. Up to you !! 


end-proc;

