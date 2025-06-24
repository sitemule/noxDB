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


    //callHelloProgram1();
    callHelloProgram2();

    // That's it..
    *inlr = *on;


// ------------------------------------------------------------------------------------
// call Hello Program - new version of RPG allowing functionpointer for programs
// Note: This will not work on older versions of RPG, however will compile
// ------------------------------------------------------------------------------------
dcl-proc callHelloProgram1;

    dcl-pr HelloProgram pointer extproc(pHelloProgram);
	    name char (10) const;
        text char(200);
        age  packed(5:0);
    end-pr;

    dcl-s text char(200);
    dcl-s age  packed(5:0);
    dcl-s msg  char(50);

    dcl-s pHelloProgram	pointer (*PROC) static;

    pHelloProgram = json_LoadProgram ('*LIBL' : 'HELLOPGM');
    if pHelloProgram = *null;
        json_joblog('Could not load program HELLOPGM');
        return;
    endif;

    // Now we have an efficient dynamic procedure pointer to the program
    // We can call it with the parameters we want
    text = 'Hello world from RPG';
    age  = 25;
    HelloProgram ('Niels': text: age);
    json_joblog ('Called HELLOPGM returns: text: ' + %trim(text) + ', age: ' + %char(age));


end-proc;

// ------------------------------------------------------------------------------------
// call Hello Program
// ------------------------------------------------------------------------------------
dcl-proc callHelloProgram2;

    dcl-s pHelloProgram			pointer (*PROC) static;
    dcl-s pHelloParms pointer dim(3) static;
    dcl-s name char(10)  inz('John');
    dcl-s text char(200) inz('Hello world from RPG');
    dcl-s age  packed(5:0) inz(55);
    dcl-s msg  char(50);


    pHelloProgram = json_LoadProgram ('*LIBL' : 'HELLOPGM');
    if pHelloProgram = *null;
        json_joblog('Could not load program HELLOPGM');
        return;
    endif;

    // Now we have an efficient dynamic procedure pointer to the program
    // We can call it with the parameters we want
    // Note: Old version or RPG only allow passing parameters by array, so we need to create an array of pointers
    pHelloParms(1) = %addr(name);
    pHelloParms(2) = %addr(text);
    pHelloParms(3) = %addr(age);

    text = 'Hello world from RPG';
    age  = 25;
    json_callPgm ( pHelloProgram : %addr(pHelloParms) : 3); // 3 is the number of parameters
    json_joblog ('Called HELLOPGM returns: text: ' + %trim(text) + ', age: ' + %char(age));


end-proc;
