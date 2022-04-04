**free
// ------------------------------------------------------------- *
// noxDB - Not only XML. JSON, SQL and XML made easy for RPG
//
// Company . . . : System & Method A/S - Sitemule
// Design  . . . : Niels Liisberg
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// Look at the header source file "QRPGLEREF" member "NOXDB"
// for a complete description of the functionality
//
// Basic features example: build, save, load manipulate JSON
// ill only compile on >= 7.4 because of using overloads  
//
// Step 1)
// When using noxDB you need two things:
//  A: Bind you program with "NOXDB" Bind directory
//  B: Include the noxDB prototypes from QRPGLEREF member NOXDB
//
// Step 2)
// Include the prototypes for noxDB and bind with bibddir NOXDB
//
// Step 3)
// Now you can use all the JSON, SQL and XML features
//
// Step 4)
// Finally remember to cleanup otherwise you will have a memory leak
// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) actgrp('QILE') option(*nodebugio:*srcstmt:*nounref) main(main);
/include qrpgleRef,noxdb

// ------------------------------------------------------------------------------------
// main
// ------------------------------------------------------------------------------------
dcl-proc main;

    // Always set your ccsid for constants: 
    json_setDelimitersByCcsid(500);

    // Setup trace/debugging ( or perhaps unit testing) for 
    // your code if you like - this is optional
    // myTrace is defined in the bottom in the example 
    // Note - you can disable the trace by setting it to *NULL
    json_SetTraceProc (%paddr(myTrace));

    // Run the examples:
    example1();
    example2();

end-proc;
// ------------------------------------------------------------------------------------
// example1
// ------------------------------------------------------------------------------------
dcl-proc example1;

    Dcl-S pJson       Pointer;
    Dcl-S pArr        Pointer;
    Dcl-S i           int(10);
    Dcl-S name        varchar(256);
    Dcl-S age         int(10);
    Dcl-S income      packed(15:2);
    Dcl-S birthDate   date(*EUR);
    Dcl-S birthTime   time(*EUR);
    Dcl-S updated     timestamp;
    Dcl-S isMale      ind;
    
    // Step 1) 
    // Produce a JSON object and write it to a file: 
    // Let start with an object: 
    pJson = json_newObject();

    // Now lets place some elements in that object:
    // Note: we use all the basic datatype in RPG
    json_setStr       (pJson: 'name' : 'John');
    json_setInt       (pJson: 'age' : 23);
    json_setNum       (pJson: 'income' : 2345.67);
    json_setDate      (pJson: 'birthDate' : d'1997-02-16');
    json_setTime      (pJson: 'birthTime' : t'12.34.56');
    json_setTimeStamp (pJson: 'updated' : %timestamp());
    json_setBool      (pJson: 'isMale' : *ON);

    // Put the node in the joblog (max 512 is shown)
    myTrace ('The final object':pJson); 

    // Play with arrays
    pArr = json_newArray();
    for i = 1 to 100;
        json_arrayPush (pArr : pJson : JSON_COPY_CLONE);
    endfor;

    myTrace ('After the loop':pArr); 

    // Write to the IFS, Note date/time will be stored in *ISO always
    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/simple0.json':1208:*OFF);

    // And always remember to cleanup
    json_delete (pJson);
    json_delete (pArr);


end-proc; 
// ------------------------------------------------------------------------------------
// example2
// Load and parse a JSON object from IFS and extract data from the object
// ------------------------------------------------------------------------------------
dcl-proc example2;

    Dcl-S pJson       Pointer;
    Dcl-S msg         varchar(256);
    Dcl-S name        varchar(256);
    Dcl-S age         int(10);
    Dcl-S income      packed(15:2);
    Dcl-S birthDate   date(*EUR);
    Dcl-S birthTime   time(*EUR);
    Dcl-S updated     timestamp;
    Dcl-S isMale      ind;

    // Now let's load it from the disk and have fun with it:
    // Note the error detection: It will return *NULL if errors 
    pJson = json_ParseFile ('/prj/noxdb/testout/simple0.json');
    If json_Error(pJson) ;
        msg = json_Message(pJson);
        myTrace (msg :pJson); 
        json_delete(pJson);
        Return;
    EndIf;

    // pull out the data from the json object:
    // Note: date and time here is in *EUR but the object graph uses *ISO
    // so it is atomatically converted.
    name      = json_getStr       (pJson: 'name');
    age       = json_getInt       (pJson: 'age');
    income    = json_getNum       (pJson: 'income');
    birthDate = json_getDate      (pJson: 'birthDate');
    birthTime = json_getTime      (pJson: 'birthTime');
    updated   = json_getTimeStamp (pJson: 'updated');
    isMale    = json_getBool      (pJson: 'isMale');

    // You can now debug the variables
    json_joblog('Name     : ' + name);
    json_joblog('age      : ' + %char(age      ));
    json_joblog('income   : ' + %char(income   ));
    json_joblog('birthDate: ' + %char(birthDate));
    json_joblog('birthTime: ' + %char(birthTime));
    json_joblog('updated  : ' + %char(updated  ));
    json_joblog('isMale   : ' + %char(isMale   ));

    // And always remember to cleanup
    json_delete (pJson);

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
