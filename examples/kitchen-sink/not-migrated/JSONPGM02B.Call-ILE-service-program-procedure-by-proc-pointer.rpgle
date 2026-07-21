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

// ------------------------------------------------------------- *


// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') ;
/include qrpgleRef,noxdb


    // this does the real job
    callNameAndAge();

    // That's it..
    *inlr = *on;


// ------------------------------------------------------------------------------------
// call My Procedure
// ------------------------------------------------------------------------------------
dcl-proc callNameAndAge;

    dcl-pr NameAndAge pointer extproc(pNameAndAge);
	    name char (10) const;
        text char(200);
        age  packed(5:0);
    end-pr;

    dcl-s text char(200);
    dcl-s age  packed(5:0);
    dcl-s msg  char(50);

    dcl-s pNameAndAge			pointer (*PROC) static;

    pNameAndAge = json_loadServiceProgramProc ( '*LIBL' : 'HELOSRVPGM' : 'NAMEAGE');
    if pNameAndAge = *null;
        json_joblog('Could not load program HELOSRVPGM');
        return;
    endif;

    // Now we have an efficient dynamic procedure pointer to the service program
    // We can call it with the parameters we want,using prototype
    // Note that text and age parameters are passed by reference, so we can change them
    text = 'Hello world from RPG';
    age  = 55;
    NameAndAge ('Niels': text: age);
    json_joblog ('Called HELOSRVPGM/NAMEAGE returns: "text": ' + %trim(text) + ', "age": ' + %char(age));

end-proc;
