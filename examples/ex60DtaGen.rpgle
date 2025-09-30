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
// Using the "data-gen"
//
// This sample uses the demo SQL schema made from ACS run SQL scripts:
// call qsys.create_sql_sample('CORPDATA');
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
Ctl-Opt BndDir('NOXDBUTF8');  // CCSID(*CHAR:*UTF8);
Ctl-Opt dftactgrp(*NO) ACTGRP('QILE') option(*nodebugio:*srcstmt:*nounref) ALWNULL(*USRCTL);
Ctl-Opt main(main);
/include qrpgleref,noxDbUtf8

// Global connection pointer
dcl-s pCon         pointer;


// Templates can be used
dcl-ds employee_t    extname('CORPDATA/EMPLOYEE')   qualified template end-ds;
dcl-ds empprojact_t  extname('CORPDATA/EMPPROJACT') qualified template end-ds;

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
    example5();
    example6();
    example7();

on-exit;
    // Always remember to delete used memory !!
    nox_sqlDisconnect(pCon);
    if memuse <> nox_memuse();
        nox_joblog('Ups - forgot to clean something up');
    endif;

end-proc;
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

    dcl-s pGraph     pointer;
    dcl-s i	        int(10);
    dcl-s handle	char(1);

    // Make some data we can play with
    for i = 1 to %elem(rows) ;
        rows(i).id = i;
        rows(i).name = 'John Smørrebrødspålæg' + %char(i);
    endfor;

    // Now the magic: the pGraph pointer is send to the mapper and returns as an object graph
    data-gen rows %data(handle:'') %gen(nox_DataGen(pGraph));

    // Let's see what we got
    nox_WriteJsonStmf(pGraph:'/prj/noxDbUtf8/testout/datagen1.json':1208:*OFF);

on-exit;
    // Always remember to delete used memory !!
    nox_delete(pGraph);

end-proc;
// ------------------------------------------------------------------------------------
// Generating JSON or XML by placing the datastructure in the object graph
// Here we use all datatypes
// ------------------------------------------------------------------------------------
dcl-proc example2;


    dcl-s pGraph     pointer;
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
    alltypes.ucs2name = u'4f605978'; // This will only work with noxDbUtf8 since noxDB is in clean EBCDIC
    alltypes.utf8name = u'4f605978'; // This will only work with noxDbUtf8 since noxDB is in clean EBCDIC
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

    // Now the magic: the pGraph pointer is send to the mapper and returns as an object graph
    data-gen alltypes %data(handle) %gen(nox_DataGen(pGraph));

    // Let's see what we got
    nox_WriteJsonStmf(pGraph:'/prj/noxDbUtf8/testout/datagen2.json':1208:*OFF);

on-exit;
    // Always remember to delete used memory !!
    nox_delete(pGraph);

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

    pArr = nox_newArray();

    // Make some data we can play with
    for i = 1 to 10 ;
        row.id = i;
        row.name = 'John ' + %char(i);

        // Now the magic: the pGraph pointer is send to the mapper and returns as an object graph
        data-gen row %data(handle) %gen(nox_DataGen(pRow));
        nox_arrayPush (pArr : pRow);

    endfor;


    // Let's see what we got
    nox_WriteJsonStmf(pArr:'/prj/noxDbUtf8/testout/datagen3.json':1208:*OFF);

on-exit;
    // Always remember to delete used memory. pArr "owns" all object generated
    nox_delete(pArr);

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
// 5) use DSPF '/prj/noxDbUtf8/testout/datagen4.json'
// It will show the correct national chars
// ------------------------------------------------------------------------------------
dcl-proc example4;


    // This is he data structure we map the object graph into:
    // The name "row" is in the data-into statement
    // The *JOBRUN will ensure the "text" is in the running job ccsid that noxDb are using
    dcl-DS row qualified inz;
        text varchar(256) ccsid(*JOBRUN);
    end-ds;

    dcl-s pGraph     pointer;
    dcl-s handle	char(1);

    row.text = 'Smørrebrødspålæg';

    // Now the magic: the pGraph pointer is send to the mapper and returns as an object graph
    data-gen row %data(handle) %gen(nox_DataGen(pGraph));

    // Let's see what we got
    nox_WriteJsonStmf(pGraph:'/prj/noxDbUtf8/testout/datagen4.json':1208:*OFF);

on-exit;
    // Always remember to delete used memory !!
    nox_delete(pGraph);

end-proc;

// ------------------------------------------------------------------------------------
// Generating JSON simple *AUTO array
// ------------------------------------------------------------------------------------
dcl-proc example5;

/IF DEFINED(*V7R5M0)
    dcl-s names  varchar(256) dim(*auto: 100) ;

	dcl-s pInputRows   pointer;
	dcl-s pOutputRows  pointer;
	dcl-s handle       char(1);
    Dcl-DS list        likeds(nox_iterator);

	pInputRows = nox_sqlResultSet(pCon:'-
		select *                -
		from corpdata.employee  -
		limit 100               -
	');

    list = nox_setIterator(pInputRows);
    DoW nox_ForEach(list);
        names(*next) = nox_getStr(list.this : 'FIRSTNME');
    EndDo;


    data-gen names
        %data(handle)
        %gen(nox_DataGen(pOutputRows));

    // Let's see what we got
    nox_WriteJsonStmf(pOutputRows:'/prj/noxDbUtf8/testout/datagen5.json':1208:*OFF);

on-exit;
    // Always remember to delete used memory !!
    nox_delete(pOutputRows);
/ENDIF
end-proc;

// ------------------------------------------------------------------------------------
// Generating JSON complex array
// First level is *AUTO
// Next level is using the number prefix
// note the "countprefix" on data-gen : %data(handle:'countprefix=num_')
// ------------------------------------------------------------------------------------
dcl-proc example6;

/IF DEFINED(*V7R5M0)

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
    Dcl-DS empList     likeds(nox_iterator);
    Dcl-DS projList    likeds(nox_iterator);

	pEmp = nox_sqlResultSet(pCon:'-
		select *                -
		from corpdata.employee  -
		limit 100               -
	');

    // note - here we also pick the EMPNO from the iterator graph done by ${EMPNO}
    empList = nox_setIterator(pEmp);
    DoW nox_ForEach(empList);
        employee(*next).name = nox_getStr(empList.this : 'FIRSTNME');
   	    pProj = nox_sqlResultSet( pCon:'-
   		    select PROJNO            -
   		    from corpdata.empprojact -
            where empNo = ${EMPNO} -
   		    limit 50':
            emplist.this
        );
        projList = nox_setIterator(pProj);
        DoW nox_ForEach(projList);
            employee(%elem(employee)).projects(projList.count).projNo = nox_getStr(projList.this:'PROJNO');
        Enddo;
        employee(%elem(employee)).num_projects = nox_getLength(pProj);
        nox_delete(pProj);

    EndDo;


    data-gen employee
        %data(handle:'countprefix=num_')
        %gen(nox_DataGen(pOutputRows));

    // Let's see what we got
    nox_WriteJsonStmf(pOutputRows:'/prj/noxDbUtf8/testout/datagen6.json':1208:*OFF);

on-exit;
    // Always remember to delete used memory !!
	nox_delete(pEmp);
	nox_delete(pProj);
	nox_delete(pOutputRows);
/ENDIF


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


    dcl-ds response qualified inz;
        num_employees int(5);
        employees likeds(empproj_t) dim(100) ;
    end-ds;


	dcl-s pEmp         pointer;
	dcl-s pProj        pointer;
	dcl-s pOutputRows  pointer;
	dcl-s handle       char(1);
    dcl-s Msg          varchar(1024) ;
    Dcl-DS empList     likeds(nox_iterator);
    Dcl-DS projList    likeds(nox_iterator);

	pEmp = nox_sqlResultSet(pCon:
        'select *                -
		 from corpdata.employee  -
		 limit 100               -
	');

    if Nox_Error(pEmp) ;
        msg = nox_Message(pEmp);
        nox_joblog ( msg );
        return;
    endif;

    // note - here we also pick the EMPNO from the iterator graph done by ${EMPNO}
    empList = nox_setIterator(pEmp);
    DoW nox_ForEach(empList);
        clear response.employees(empList.count).info;
        response.employees(empList.count).info.EMPNO  = nox_getStr(empList.this : 'EMPNO');
        response.employees(empList.count).info.FIRSTNME  = nox_getStr(empList.this : 'FIRSTNME');
        response.employees(empList.count).info.MIDINIT  = nox_getStr(empList.this : 'MIDINIT');
        response.employees(empList.count).info.LASTNAME  = nox_getStr(empList.this : 'LASTNAME');
        response.employees(empList.count).info.WORKDEPT  = nox_getStr(empList.this : 'WORKDEPT');
        response.employees(empList.count).info.PHONENO  = nox_getStr(empList.this : 'PHONENO');
        response.employees(empList.count).info.HIREDATE  = nox_getDate(empList.this : 'HIREDATE');
        response.employees(empList.count).info.JOB  = nox_getStr(empList.this : 'JOB');
        response.employees(empList.count).info.EDLEVEL  = nox_getInt(empList.this : 'EDLEVEL');
        response.employees(empList.count).info.SEX  = nox_getStr(empList.this : 'SEX');
        response.employees(empList.count).info.BIRTHDATE  = nox_getDate(empList.this : 'BIRTHDATE');
        response.employees(empList.count).info.SALARY  = nox_getDec(empList.this : 'SALARY');
        response.employees(empList.count).info.BONUS  = nox_getDec(empList.this : 'BONUS');
        response.employees(empList.count).info.COMM  = nox_getDec(empList.this : 'COMM');

   	    pProj = nox_sqlResultSet(pCon:'-
   		    select PROJNO              -
   		    from corpdata.empprojact -
            where empNo = ${ EMPNO } -
   		    limit 50 ':
            emplist.this
        );

        if Nox_Error(pProj) ;
            msg = nox_Message(pProj);
            nox_joblog ( msg );
            return;
        endif;

        projList = nox_setIterator(pProj);
        DoW nox_ForEach(projList);
            clear response.employees(empList.count).projects(projList.count);
            response.employees(empList.count).projects(projList.count).EMPNO    = nox_getStr(projList.this:'EMPNO');
            response.employees(empList.count).projects(projList.count).PROJNO   = nox_getStr(projList.this:'PROJNO');
            response.employees(empList.count).projects(projList.count).ACTNO    = nox_getInt(projList.this:'ACTNO');
            response.employees(empList.count).projects(projList.count).EMPTIME  = nox_getDec(projList.this:'EMPTIME');
            response.employees(empList.count).projects(projList.count).EMSTDATE = nox_getDate(projList.this:'EMSTDATE');
            response.employees(empList.count).projects(projList.count).EMENDATE = nox_getDate(projList.this:'EMENDATE');
        Enddo;
        response.employees(empList.count).num_projects = nox_getLength(pProj);
        nox_delete(pProj);
    EndDo;
    response.num_employees = nox_getLength(pEmp);


    data-gen response
        %data(handle:'countprefix=num_')
        %gen (nox_DataGen(pOutputRows):'case=default');

    // Let's see what we got
    nox_WriteJsonStmf(pOutputRows:'/prj/noxDbUtf8/testout/datagen7.json':1208:*OFF);

on-exit;
    // Always remember to delete used memory !!
	nox_delete(pEmp       );
	nox_delete(pProj      );
	nox_delete(pOutputRows);

end-proc;
