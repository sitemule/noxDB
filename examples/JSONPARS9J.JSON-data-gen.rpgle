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

// This sample uses the demo SQL schema made from ACS run SQL scripts:
// call qsys.create_sql_sample('CORPDATA');

// Set your job ccsid to 500 - just for the example:
// CHGJOB ccsid(500)

// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') option(*nodebugio:*srcstmt:*nounref) ALWNULL(*USRCTL);
/include qrpgleRef,noxdb

// Templates can be used
dcl-ds employee_t    extname('CORPDATA/EMPLOYEE')   qualified template end-ds;
dcl-ds empprojact_t  extname('CORPDATA/EMPPROJACT') qualified template end-ds;

    example1();
    example2();
    example3();
    example4();
    example5();
    example6();
    example7();
    json_sqlDisconnect();

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
    data-gen rows %data(handle) %gen(json_DataGen(pJson));

    // Let's see what we got
    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/datagen1.json':1208:*OFF);


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
    data-gen alltypes %data(handle) %gen(json_DataGen(pJson));

    // Let's see what we got
    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/datagen2.json':1208:*OFF);

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
        data-gen row %data(handle) %gen(json_DataGen(pRow));
        json_arrayPush (pArr : pRow);

    endfor;


    // Let's see what we got
    json_WriteJsonStmf(pArr:'/prj/noxdb/testout/datagen3.json':1208:*OFF);


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
    data-gen row %data(handle) %gen(json_DataGen(pJson));

    // Let's see what we got
    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/datagen4.json':1208:*OFF);


    // Always remember to delete used memory !!
    json_delete(pJson);

end-proc;

// ------------------------------------------------------------------------------------
// Generating JSON simple *AUTO array
// ------------------------------------------------------------------------------------
dcl-proc example5;

    dcl-s names  varchar(256) dim(*auto: 100) ;

	dcl-s pInputRows   pointer;
	dcl-s pOutputRows  pointer;
	dcl-s handle       char(1);
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
        %data(handle)
        %gen(json_DataGen(pOutputRows));

    // Let's see what we got
    json_WriteJsonStmf(pOutputRows:'/prj/noxdb/testout/datagen5.json':1208:*OFF);


    // Always remember to delete used memory !!
    json_delete(pOutputRows);

end-proc;

// ------------------------------------------------------------------------------------
// Generating JSON complex array
// First level is *AUTO
// Next level is using the number prefix
// note the "countprefix" on data-gen : %data(handle:'countprefix=num_')
// ------------------------------------------------------------------------------------
dcl-proc example6;


    dcl-ds employee  qualified  dim(*AUTO:100) ;
        name varchar(256);
        num_projects int(5);
        dcl-ds projects  dim(50) ;
            projNo varchar(256);
        end-ds;
    end-ds;

	dcl-s pEmp         pointer;
	dcl-s pProj        pointer;
	dcl-s pOutputRows  pointer;
	dcl-s handle        char(1);
    Dcl-DS empList     likeds(json_iterator);
    Dcl-DS projList    likeds(json_iterator);

	pEmp = json_sqlResultSet(' -
		select *                -
		from corpdata.employee  -
		limit 100               -
	');

    empList = json_setIterator(pEmp);
    DoW json_ForEach(empList);
        employee(*next).name = json_getStr(empList.this : 'FIRSTNME');
   	    pProj = json_sqlResultSet('  -
   		    select PROJNO                 -
   		    from corpdata.empprojact -
            where empNo = ' + quote(json_getStr(emplist.this:'EMPNO')) + '-
   		    limit 50                -
   	    ');
        projList = json_setIterator(pProj);
        DoW json_ForEach(projList);
            employee(%elem(employee)).projects(projList.count).projNo = json_getStr(projList.this:'PROJNO');
        Enddo;
        employee(%elem(employee)).num_projects = json_getLength(pProj);
        json_delete(pProj);

    EndDo;


    data-gen employee
        %data(handle:'countprefix=num_')
        %gen(json_DataGen(pOutputRows));

    // Let's see what we got
    json_WriteJsonStmf(pOutputRows:'/prj/noxdb/testout/datagen6.json':1208:*OFF);

on-exit;
    // Always remember to delete used memory !!
	json_delete(pEmp);
	json_delete(pProj);
	json_delete(pOutputRows);


end-proc;
// ------------------------------------------------------------------------------------
// Generating JSON complex array
// All levels are using the number prefix
// note the "countprefix" on data-gen : %data(handle:'countprefix=num_')
// ------------------------------------------------------------------------------------
dcl-proc example7;

    dcl-ds empproj_t  qualified template;
        info likeds(employee_t) ;
        num_projects int(5);
        projects  likeds(empprojact_t) dim(50) ;
    end-ds;


    dcl-ds response qualified ;
        num_employees int(5);
        employees likeds(empproj_t) dim(100) ;
    end-ds;


	dcl-s pEmp         pointer;
	dcl-s pProj        pointer;
	dcl-s pOutputRows  pointer;
	dcl-s handle        char(1);
    Dcl-DS empList     likeds(json_iterator);
    Dcl-DS projList    likeds(json_iterator);

	pEmp = json_sqlResultSet(' -
		select *                -
		from corpdata.employee  -
		limit 100               -
	');

    empList = json_setIterator(pEmp);
    DoW json_ForEach(empList);
        clear response.employees(empList.count).info;
        response.employees(empList.count).info.firstnme  = json_getStr(empList.this : 'FIRSTNME');
        response.employees(empList.count).info.lastname  = json_getStr(empList.this : 'LASTNAME');
   	    pProj = json_sqlResultSet('  -
   		    select PROJNO                 -
   		    from corpdata.empprojact -
            where empNo = ' + quote(json_getStr(emplist.this:'EMPNO')) + '-
   		    limit 50                -
   	    ');
        projList = json_setIterator(pProj);
        DoW json_ForEach(projList);
            clear response.employees(empList.count).projects(projList.count);
            response.employees(empList.count).projects(projList.count).projNo = json_getStr(projList.this:'PROJNO');
        Enddo;
        response.employees(empList.count).num_projects = json_getLength(pProj);
        json_delete(pProj);
    EndDo;
    response.num_employees = json_getLength(pEmp);


    data-gen response
        %data(handle:'countprefix=num_')
        %gen(json_DataGen(pOutputRows));

    // Let's see what we got
    json_WriteJsonStmf(pOutputRows:'/prj/noxdb/testout/datagen7.json':1208:*OFF);

on-exit;
    // Always remember to delete used memory !!
	json_delete(pEmp       );
	json_delete(pProj      );
	json_delete(pOutputRows);


end-proc;
// -------------------------------------------------------------
// quote helper function to ensure sql injection is not possible
// This function will add quotes around the string and escape any quotes inside the string
// --------------------------------------------------------------
dcl-proc quote;
    dcl-pi *n varchar(256);
        str varchar(256) const options(*varsize);
    end-pi;
    dcl-c  q '''';

    return q + %scanrpl (q:q+q:str) + q;

end-proc;
