**free
// ------------------------------------------------------------- *
// noxDB - Not only XML. JSON, SQL and XML made easy for RPG
//
// Company . . . : System & Method A/S - Sitemule
// Design  . . . : Niels Liisberg
//
// Using nullind
// Note: the use of Ctl-Opt alwnull(*USRCTL)
// Note: the cast i.e. %time(%char(..)) is required since passing nullmap
//       fields fails to convert in procedure calls.
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
Ctl-Opt alwnull(*USRCTL);
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) actgrp('QILE') option(*nodebugio:*srcstmt:*nounref) main(main);
/include qrpgleRef,noxdb

dcl-ds employee extname('NOXDBDEMO/ICEMPLOYEE') qualified end-ds;

dcl-c nullTime t'00.00.00';
dcl-c nullDate d'0001-01-01';
dcl-c nullTimestamp z'0001-01-01-00.00.00';

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

    // have an object to play with
    pJson = json_newObject();

    // First set values "normally"
    employee.name        = 'John';
    employee.age         = 23;
    employee.income      = 12345.67;
    employee.birthDate   = d'1997-02-16';
    employee.birthTime   = t'12.34.56';
    employee.updated     = %timestamp();
    employee.isMale      = 1;


    // Creat an object with that data
    // Note: we use all the basic datatype in RPG
    json_setStr       (pJson: 'name'      :%char(employee.name));
    json_setInt       (pJson: 'age'       :%int(employee.age));
    json_setNum       (pJson: 'income'    :%dec(employee.income));
    json_setDate      (pJson: 'birthDate' :%date(%char(employee.birthDate):*ISO));
    json_setTime      (pJson: 'birthTime' :%time(%char(employee.birthTime):*ISO));
    json_setTimeStamp (pJson: 'updated'   :%timestamp(employee.updated));
    json_setBool      (pJson: 'isMale'    :employee.isMale=1);

    // Put the node in the joblog (max 512 is shown)
    myTrace ('The final object - all set ':pJson);
    // Write to the IFS, Note date/time will be stored in *ISO always
    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/nullind1.json':1208:*OFF);

    // Step2: Set all to null:
    %nullind(employee.name)      = *ON;
    %nullind(employee.age)       = *ON;
    %nullind(employee.income)    = *ON;
    %nullind(employee.birthDate) = *ON;
    %nullind(employee.birthTime) = *ON;
    %nullind(employee.updated)   = *ON;
    %nullind(employee.isMale)    = *ON;

    // Now set with the nullind
    json_setStr       (pJson: 'name'      :%char(employee.name)     : %nullind(employee.name));
    json_setInt       (pJson: 'age'       :%int(employee.age)       : %nullind(employee.age));
    json_setNum       (pJson: 'income'    :%dec(employee.income)    : %nullind(employee.income));
    json_setDate      (pJson: 'birthDate' :%date(%char(employee.birthDate):*ISO): %nullind(employee.birthDate));
    json_setTime      (pJson: 'birthTime' :%time(%char(employee.birthTime):*ISO): %nullind(employee.birthTime));
    json_setTimeStamp (pJson: 'updated'   :%timestamp(employee.updated): %nullind(employee.updated));
    json_setBool      (pJson: 'isMale'    :employee.isMale=1        : %nullind(employee.isMale));

    // Put the node in the joblog (max 512 is shown)
    myTrace ('The final object - all null':pJson);
    // Write to the IFS, Note date/time will be stored in *ISO always
    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/nullind2.json':1208:*OFF);


    // Step2: Set all to null:
    %nullind(employee.name)      = *OFF;
    %nullind(employee.age)       = *OFF;
    %nullind(employee.income)    = *OFF;
    %nullind(employee.birthDate) = *OFF;
    %nullind(employee.birthTime) = *OFF;
    %nullind(employee.updated)   = *OFF;
    %nullind(employee.isMale)    = *OFF;

    // Now set with the nullind
    json_setStr       (pJson: 'name'      :%char(employee.name)     : %nullind(employee.name));
    json_setInt       (pJson: 'age'       :%int(employee.age)       : %nullind(employee.age));
    json_setNum       (pJson: 'income'    :%dec(employee.income)    : %nullind(employee.income));
    json_setDate      (pJson: 'birthDate' :%date(%char(employee.birthDate):*ISO): %nullind(employee.birthDate));
    json_setTime      (pJson: 'birthTime' :%time(%char(employee.birthTime):*ISO): %nullind(employee.birthTime));
    json_setTimeStamp (pJson: 'updated'   :%timestamp(employee.updated): %nullind(employee.updated));
    json_setBool      (pJson: 'isMale'    :employee.isMale=1        : %nullind(employee.isMale));

    // Put the node in the joblog (max 512 is shown)
    myTrace ('The final object - all NOT null':pJson);
    // Write to the IFS, Note date/time will be stored in *ISO always
    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/nullind3.json':1208:*OFF);


    // And always remember to cleanup
    json_delete (pJson);

end-proc;
// ------------------------------------------------------------------------------------
// example2 - user defined reasons for null
// ------------------------------------------------------------------------------------
dcl-proc example2;

    Dcl-S pJson       Pointer;
    Dcl-S name        varchar(256);
    Dcl-S age         int(5);
    Dcl-S income      packed(15:2);
    Dcl-S birthDate   date;
    Dcl-S birthTime   time;
    Dcl-S updated     timestamp;
    Dcl-S isMale      ind;
    Dcl-S sex         char(1) inz('M');

    // have an object to play with
    pJson = json_newObject();

    // First set values "normally"
    name        = 'John';
    age         = 23;
    income      = 12345.67;
    birthDate   = d'1997-02-16';
    birthTime   = t'12.34.56';
    updated     = %timestamp();
    isMale      = *ON;


    // Creat an object with that data
    // Note: we use all the basic datatype in RPG
    json_setStr       (pJson: 'name'      :name);
    json_setInt       (pJson: 'age'       :age);
    json_setNum       (pJson: 'income'    :income);
    json_setDate      (pJson: 'birthDate' :birthDate);
    json_setTime      (pJson: 'birthTime' :birthTime);
    json_setTimeStamp (pJson: 'updated'   :updated);
    json_setBool      (pJson: 'isMale'    :*ON);

    // Put the node in the joblog (max 512 is shown)
    myTrace ('User reasons for null: final object - all set ':pJson);
    // Write to the IFS, Note date/time will be stored in *ISO always
    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/nullind11.json':1208:*OFF);


    // NOW!! userdefined reasons - all good:
    json_setStr       (pJson: 'name'      :name      : name = '');
    json_setInt       (pJson: 'age'       :age       : age  = 0);
    json_setNum       (pJson: 'income'    :income    : income = 0);
    json_setDate      (pJson: 'birthDate' :birthDate : birthDate <= nullDate);
    json_setTime      (pJson: 'birthTime' :birthTime : birthTime =  nullTime );
    json_setTimeStamp (pJson: 'updated'   :updated   : updated   <= nullTimeStamp);
    json_setBool      (pJson: 'isMale'    :sex = 'M' : sex <> 'M' and sex <> 'F');



    // Put the node in the joblog (max 512 is shown)
    myTrace ('User reasons for null:  The final object - all good':pJson);
    // Write to the IFS, Note date/time will be stored in *ISO always
    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/nullind12.json':1208:*OFF);


    // Step2: Set all to null:
    name        = '';
    age         = 0;
    income      = 0;
    birthDate   = nullDate;
    birthTime   = nullTime;
    updated     = nullTimestamp;
    sex         = ' ';

    // NOW!! userdefined reasons - all has userdefined values for null result:
    json_setStr       (pJson: 'name'      :name      : name = '');
    json_setInt       (pJson: 'age'       :age       : age  = 0);
    json_setNum       (pJson: 'income'    :income    : income = 0);
    json_setDate      (pJson: 'birthDate' :birthDate : birthDate <= nullDate);
    json_setTime      (pJson: 'birthTime' :birthTime : birthTime =  nullTime );
    json_setTimeStamp (pJson: 'updated'   :updated   : updated   <= nullTimeStamp);
    json_setBool      (pJson: 'isMale'    :sex = 'M' : sex <> 'M' and sex <> 'F');


    // Put the node in the joblog (max 512 is shown)
    myTrace ('User reasons for null:  The final object - all userdefined as null':pJson);
    // Write to the IFS, Note date/time will be stored in *ISO always
    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/nullind13.json':1208:*OFF);

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
