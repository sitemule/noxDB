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

// Using the "data-gen"

// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') option(*nodebugio:*srcstmt:*nounref) ALWNULL(*USRCTL);
/include qrpgleRef,noxdb

dcl-ds employee_t    extname('CORPDATA/EMPLOYEE') qualified template end-ds;

    //example1();
    //example2();
    //example3();
    //example4();
    //example5();
    example6();

    *INLR = *ON;

// ------------------------------------------------------------------------------------
// Generating JSON or XML by placing the datastructure in the objectgraph
// ------------------------------------------------------------------------------------
dcl-proc example1;


    // This is he data structure we map the object graph into:
    // The name "rows" is in the data-into statement
    // The "dim" causes it to be an array:
    dcl-DS rows dim(2) qualified inz;
        id   int(10);
        name varchar(256);
    end-ds;

    dcl-s pJson     pointer;
    dcl-s i	        int(10);
    dcl-s handle	char(1);

    // Make some data we can play with
    for i = 1 to %elem(rows) ;
        rows(i).id = i;
        rows(i).name = 'John Smørrebrødspålæg' + %char(i);
    endfor;

    // Now the magic: the pJson pointer is send to the mapper and returns as an object graph
    data-gen rows %data(handle: '') %gen(json_DataGen(pJson));

    // Let's see what we got
    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/dump-payload.json':1208:*OFF);


    // Always remember to delete used memory !!
    json_delete(pJson);

end-proc;
// ------------------------------------------------------------------------------------
// Generating JSON or XML by placing the datastructure in the object graph
// Here we use all datatypes
// ------------------------------------------------------------------------------------
dcl-proc example2;


    dcl-s pJson     pointer;
    dcl-s i	        int(10);
    dcl-s handle	char(1);

    // This is the data structure we map the object graph into:
    // Some types requires 7.4 or new TR's
    dcl-ds alltypes qualified inz;
        id          int(10);
        isClient    ind;
        name        varchar(256);
        ucs2name    ucs2(256);
        utf8name    varchar(256) ccsid(*utf8);
        //utf16name   varchar(256) ccsid(*UTF16);
        myDate      date(*ISO);
        myTime      time(*ISO);
        myTimeStamp timestamp;
        canbenull   varchar(100) nullind;
        //dynarr      char(1) dim(*AUTO:100);
        dcl-ds substructure;
            itemno      int(10);
            itemName    varchar(256);
            price       packed (13:2);
            margin      zoned(5:3);
            pi          float(8);
        end-ds;
    end-ds;

    // Initialize with some fun:
    alltypes.id = 123;
    alltypes.isClient = *ON;
    alltypes.name = 'John';
    alltypes.ucs2name = u'4f605978'; // This will only work with noxDB2 since noxDB is in clean EBCDIC
    alltypes.utf8name = u'4f605978'; // This will only work with noxDB2 since noxDB is in clean EBCDIC
    //alltypes.utf16name = u'4f605978';
    alltypes.myDate    = %date();
    alltypes.myTime = %time();
    alltypes.myTimeStamp = %timestamp();
    //%nullind(alltypes.canbenull) = *ON;
    alltypes.substructure.itemno = 1234;
    alltypes.substructure.itemName = 'iPhone super XV';
    alltypes.substructure.price  = 12345.67;
    alltypes.substructure.margin = -22.5;
    alltypes.substructure.pi     = 22.0/7;

    //alltypes.dynarr(*next) = 'a';
    //alltypes.dynarr(*next) = 'b';
    //alltypes.dynarr(*next) = 'c';

    // Now the magic: the pJson pointer is send to the mapper and returns as an object graph
    data-gen alltypes %data(handle: '') %gen(json_DataGen(pJson));

    // Let's see what we got
    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/dump-payload2.json':1208:*OFF);

    // Always remember to delete used memory !!
    json_delete(pJson);

end-proc;
// ------------------------------------------------------------------------------------
// Generating JSON or XML by placing the datastructure in the objectgraph
// ------------------------------------------------------------------------------------
dcl-proc example3;


    // This is he data structure we map the object graph into:
    // The name "rows" is in the data-into statement
    // The "dim" causes it to be an array:
    dcl-DS row  qualified inz;
        id   int(10);
        name varchar(256);
    end-ds;

    dcl-s pArr	    pointer;
    dcl-s pRow      pointer;
    dcl-s i	        int(10);
    dcl-s handle	char(1);

    pArr = json_newArray();

    // Make some data we can play with
    for i = 1 to 10 ;
        row.id = i;
        row.name = 'John ' + %char(i);

        // Now the magic: the pJson pointer is send to the mapper and returns as an object graph
        data-gen row %data(handle: '') %gen(json_DataGen(pRow));
        json_arrayPush (pArr : pRow);

    endfor;


    // Let's see what we got
    json_WriteJsonStmf(pArr:'/prj/noxdb/testout/dump-payload3.json':1208:*OFF);


    // Always remember to delete used memory. pArr "owns" all object generated
    json_delete(pArr);

end-proc;

// ------------------------------------------------------------------------------------
// Generating JSON or XML by placing the datastructure in the objectgraph
// CCSID testing -  The test code is build for CCSID 500, so the job need to be the same
// Ensure you see the the right ccsid of the data:
// 1) Set your emullator to ccsid(500)
// 2) Logon to your 5250 emmulator
// 3) Use CHGJOB CCSID(500) BEFORE you load any program using noxDb
//        noxDb will initiate the delimiters at invocation time
// 4) Now call you program
// 5) use DSPF '/prj/noxdb/testout/ccsid-test.json'
// It will show the correct national chars
// ------------------------------------------------------------------------------------
dcl-proc example4;


    // This is he data structure we map the object graph into:
    // The name "row" is in the data-into statement
    // The *JOBRUN will ensure the "text" is in the running job ccsid that noxDb are using
    dcl-DS row qualified inz;
        text varchar(256) ccsid(*JOBRUN);
    end-ds;

    dcl-s pJson     pointer;
    dcl-s handle	char(1);

    row.text = 'Smørrebrødspålæg';

    // Now the magic: the pJson pointer is send to the mapper and returns as an object graph
    data-gen row %data(handle: '') %gen(json_DataGen(pJson));

    // Let's see what we got
    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/ccsid-test.json':1208:*OFF);


    // Always remember to delete used memory !!
    json_delete(pJson);

end-proc;
// ------------------------------------------------------------------------------------
// Generating JSON or XML by placing the datastructure in the objectgraph
// ------------------------------------------------------------------------------------
dcl-proc example5;


    dcl-ds rows qualified inz;
        counter_employee int(10);
        dcl-ds employee   likeds(employee_t) dim(100) ;
    end-ds;

	dcl-s pInputRows   pointer;
	dcl-s pOutputRows  pointer;
	dcl-s dummy        char(1);
    Dcl-DS list        likeds(json_iterator);

	pInputRows = json_sqlResultSet(' -
		select *                -
		from corpdata.employee  -
		limit 100               -
	');

    list = json_setIterator(pInputRows);
    DoW json_ForEach(list);
        rows.employee(list.count).EMPNO    = json_getStr(list.this : 'EMPNO');
        rows.employee(list.count).FIRSTNME = json_getStr(list.this : 'FIRSTNME');
    EndDo;

    rows.counter_employee = json_getLength(pInputRows);

    data-gen rows
        %data(dummy)
        %gen(json_DataGen(pOutputRows:'numprefix=counter_'));

    // Let's see what we got
    json_WriteJsonStmf(pOutputRows:'/prj/noxdb/testout/datagen5.json':1208:*OFF);


    // Always remember to delete used memory !!
    json_delete(pOutputRows);

end-proc;

// ------------------------------------------------------------------------------------
// Generating JSON or XML by placing the datastructure in the objectgraph
// ------------------------------------------------------------------------------------
dcl-proc example6;


    // dcl-ds employee   likeds(employee_t) dim(*AUTO:100) ;
    dcl-s names  varchar(256) dim(*var : 100) ;

	dcl-s pInputRows   pointer;
	dcl-s pOutputRows  pointer;
	dcl-s dummy        char(1);
    Dcl-DS list        likeds(json_iterator);

	pInputRows = json_sqlResultSet(' -
		select *                -
		from corpdata.employee  -
		limit 100               -
	');

    list = json_setIterator(pInputRows);
    DoW json_ForEach(list);
        names(*next) = json_getStr(list.this : 'FIRSTNME');
    EndDo;


    data-gen names
        %data(dummy)
        %gen(json_DataGen(pOutputRows));

    // Let's see what we got
    json_WriteJsonStmf(pOutputRows:'/prj/noxdb/testout/datagen6.json':1208:*OFF);


    // Always remember to delete used memory !!
    json_delete(pOutputRows);

end-proc;
