**free
// ------------------------------------------------------------------------------------
// noxDB - Not Only Xml - Its JSON, XML, SQL and more
//
// This tutorial will show how to use the SQL values to retrive
// simple math expresions to advanced object trees
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

    // Run the examples
    example1();
    example2();
    example3();


// Always remember to delete used memory !!
on-exit;
    nox_sqlDisconnect(pCon);
    if memuse <> nox_memuse();
        nox_joblog('Ups - forgot to clean something up');
    endif;

end-proc;
// ------------------------------------------------------------------------------------
// example1 simple return 2+2 = 4
// ------------------------------------------------------------------------------------
dcl-proc example1;

    Dcl-S pValues              Pointer;

    // return an simple element based on a math expression
    pValues = nox_sqlValues ( pCon:
        '2 + 2'
    ) ;

    // Produce a JSON stream file in the IFS
    nox_writeJsonStmf(pValues  :
       '/prj/noxDbUtf8/testout/ex25-values1.json' : 1208 :*OFF
    );

// Always remember to delete used memory !!
on-exit;
    nox_delete(pValues);

end-proc;
// ------------------------------------------------------------------------------------
// example2 return an array
// ------------------------------------------------------------------------------------
dcl-proc example2;

    Dcl-S pValues              Pointer;

    // return an simple array with elements of mixed data types
    pValues = nox_sqlValues (pCon:
        '1, 2, 3 , ''A'', ''B'', ''C'' '
    ) ;

    // Produce a JSON stream file in the IFS
    nox_writeJsonStmf(pValues  :
        '/prj/noxDbUtf8/testout/ex25-values2.json' : 1208 :*OFF
    );

// Always remember to delete used memory !!
on-exit;
    nox_delete(pValues);

end-proc;

// ------------------------------------------------------------------------------------
// sqlValues
// SQL statement to get the employee and project data into the noxdb Graph
// Note: the parameter object used in the template to avoid SQL injection
// ------------------------------------------------------------------------------------
dcl-proc example3;

    dcl-s pTree       pointer;
    dcl-s pSqlParms   pointer;

    // Build a parameter object for the sql statement
    pSqlParms = nox_Object (
        'employeeNumber': nox_int(170)
    );

    pTree = nox_sqlValues ( pCon:
        'json_array ( -
            ( -
                select json_object( -
                    ''employeeNumber'' : int(empno), -
                    ''Name'' :  rtrim(firstnme) || '' '' || midinit || '' '' || rtrim (lastname), -
                    ''workDepartment'' : workdept, -
                    ''phoneNumber''    : phoneno, -
                    ''hireDate''       : hiredate, -
                    ''jobTitle''       : job, -
                    ''educationLevel'' : edlevel, -
                    ''sex''            : case when sex=''M'' then ''Male'' when sex=''F'' then ''Female'' else ''Other'' end , -
                    ''birthDate''      : birthdate, -
                    ''salary''         : salary, -
                    ''bonus''          : bonus, -
                    ''commission''     : comm, -
                    ''projects''       : json_array( -
                        ( -
                            select json_object( -
                                ''projNumber''   : c.projno, -
                                ''projName''     : projname, -
                                ''actNumber''    : actno, -
                                ''empTime''      : emptime, -
                                ''emstDate''     : emstdate, -
                                ''emenDate''     : emendate, -
                                ''deptNumber''   : deptno, -
                                ''respEmployee'' : respemp, -
                                ''prstaff''      : prstaff, -
                                ''prstDate''     : prstdate, -
                                ''prenDate''     : prendate, -
                                ''majProj''      : majproj -
                            ) -
                            from corpdata.empprojact b -
                            left join corpdata.project c-
                                on b.projno = c.projno -
                            where b.empno = a.empno -
                        ) format json -
                    ) -
                ) -
                from corpdata.employee a-
                where empno = ${employeeNumber} -
            ) format json -
        )':
        pSqlParms :   // parameters
        NOX_SYSTEM_CASE    +  // Use the names as they are - no auto camelCase
        NOX_GRACEFUL_ERROR    // Errors are retuned as an error object
    );

    // Let's see what we got - both as JSON and XML
    nox_WriteJsonStmf(pTree:'/prj/noxDbUtf8/testout/ex25-values3.json': 1208 :*OFF);
    nox_WriteXmlStmf (pTree:'/prj/noxDbUtf8/testout/ex25-values3.xml' : 1208 :*OFF);


// Always remember to delete used memory !!
on-exit;
    nox_delete(pTree);
    nox_delete(pSqlParms);

end-proc;
