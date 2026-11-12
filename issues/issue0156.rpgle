**FREE
// -------------------------------------------------------------
// noxDB UTF-8 - DATA-GEN array length smoke test
//
// This test covers the countsuffix and toplength generator options added to
// src/datagen.c for the NOXDBUTF8 service program.
// -------------------------------------------------------------
ctl-opt main(main)
         option(*srcstmt : *nodebugio : *showcpy : *expdds : *nounref)
         extbinint(*yes)
         decedit(',')
         bnddir('NOXDBUTF8/NOXDBUTF8')
         ccsid(*char:*jobrun);

/include noxdbutf8/qrpgleref,noxdbutf8

dcl-proc main;

    dcl-ds project_t qualified template;
        id int(10);
    end-ds;

    dcl-ds empproj_t qualified template;
        projects_length int(5);
        projects likeds(project_t) dim(5);
    end-ds;

    dcl-ds response qualified;
        employees_length int(5);
        employees likeds(empproj_t) dim(4);
    end-ds;

    dcl-ds rows qualified dim(4);
        id int(10);
        items_length int(5);
        items char(10) dim(20);
    end-ds;

    dcl-s pJson pointer;
    dcl-s pOutput pointer;
    dcl-s pEmployee pointer;
    dcl-s pProjects pointer;
    dcl-s handle char(1);
    dcl-s rowCount int(10);
    dcl-s i int(10);

    // Example 1: nested arrays controlled by sibling *_length fields.
    response.employees_length = 2;
    response.employees(1).projects_length = 1;
    response.employees(1).projects(1).id = 101;
    response.employees(2).projects_length = 2;
    response.employees(2).projects(1).id = 201;
    response.employees(2).projects(2).id = 202;

    data-gen response
        %data(handle)
        %gen(nox_DataGen(pOutput:'countsuffix=_length'));

    pEmployee = nox_Locate(pOutput : 'employees[0]');
    pProjects = nox_Locate(pEmployee : 'projects');
    nox_Assert('employees array uses countsuffix' :
        nox_GetLength(nox_Locate(pOutput : 'employees')) = 2);
    nox_Assert('first projects array uses countsuffix' : nox_GetLength(pProjects) = 1);
    nox_Assert('employeesLength is removed' :
        nox_Locate(pOutput : 'employeesLength') = *NULL);
    nox_Assert('projectsLength is removed' :
        nox_Locate(pEmployee : 'projectsLength') = *NULL);
    nox_delete(pOutput);

    // Example 2: a runtime-built option string for a root array.
    rowCount = 2;
    for i = 1 to rowCount;
        rows(i).id = i;
        rows(i).items_length = i;
        rows(i).items(1) = 'item ' + %char(i) + '-1';
        rows(i).items(2) = 'item ' + %char(i) + '-2';
    endfor;

    data-gen rows
        %data(handle)
        %gen(nox_DataGen(pJson):
            'countsuffix=_length,toplength=' + %char(rowCount));

    nox_Assert('root array limited by toplength' : nox_GetLength(pJson) = 2);
    pEmployee = nox_Locate(pJson : '[0]');
    pProjects = nox_Locate(pEmployee : 'items');
    nox_Assert('first items array uses countsuffix' : nox_GetLength(pProjects) = 1);
    nox_Assert('first itemsLength is removed' :
        nox_Locate(pEmployee : 'itemsLength') = *NULL);

    pEmployee = nox_Locate(pJson : '[1]');
    pProjects = nox_Locate(pEmployee : 'items');
    nox_Assert('second items array uses countsuffix' : nox_GetLength(pProjects) = 2);
    nox_Assert('second itemsLength is removed' :
        nox_Locate(pEmployee : 'itemsLength') = *NULL);

    nox_delete(pJson);
    nox_joblog('issue0156 done');

end-proc;
