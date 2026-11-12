**FREE
// -------------------------------------------------------------
// noxDB - Not only XML. JSON, SQL and XML made easy for RPG

// Company . . . : System & Method A/S - Sitemule
// Design  . . . : Niels Liisberg

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

// This test, issue0151, is a smoke/regression test for the data-gen limits
// added in src/datagen.c:
//   * toplength limits the root array while it is generated
//   * countsuffix uses a sibling <array><suffix> field as the array length
//     and removes that field from the generated object
//
// Run it in a CCSID(500) job (see issues/Makefile) and look for
// "ASSERT FAILED" in the joblog - none means OK.
// -------------------------------------------------------------
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') main(main);
/include qrpgleRef,noxdb

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
        %gen(json_dataGen(pOutput:'countsuffix=_length'));

    assert ('employees array uses countsuffix' :
        json_getLength(json_locate(pOutput : 'employees')) = 2);
    pEmployee = json_locate(pOutput : 'employees[0]');
    pProjects = json_locate(pEmployee : 'projects');
    assert ('first projects array uses countsuffix' : json_getLength(pProjects) = 1);
    assert ('employees_length is removed' :
        json_locate(pOutput : 'employees_length') = *NULL);
    assert ('projects_length is removed' :
        json_locate(pEmployee : 'projects_length') = *NULL);
    json_delete(pOutput);

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
        %gen(json_dataGen(pJson):
            'countsuffix=_length,toplength=' + %char(rowCount));

    assert ('root array limited by toplength' : json_getLength(pJson) = 2);

    pEmployee = json_locate(pJson : '[0]');
    pProjects = json_locate(pEmployee : 'items');
    assert ('first items array uses countsuffix' : json_getLength(pProjects) = 1);
    assert ('first items_length is removed' :
        json_locate(pEmployee : 'items_length') = *NULL);

    pEmployee = json_locate(pJson : '[1]');
    pProjects = json_locate(pEmployee : 'items');
    assert ('second items array uses countsuffix' : json_getLength(pProjects) = 2);
    assert ('second items_length is removed' :
        json_locate(pEmployee : 'items_length') = *NULL);

    json_delete(pJson);
    json_joblog('issue0151 done');

end-proc;

dcl-proc assert;

    dcl-pi *n;
        text varchar(256) value;
        ok   ind value;
    end-pi;

    if not ok;
        json_joblog('ASSERT FAILED: ' + text);
    endif;
end-proc;
