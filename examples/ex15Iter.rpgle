**free
// ------------------------------------------------------------------------------------
// noxDB - Not Only Xml - Its JSON, XML, SQL and more
//
// This tutorial will show iterators
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
//
// try/build:
// cd '/prj/NOXDBUTF8'
// addlible NOXDBUTF8
// chgjobccsid(500)
// call
// ------------------------------------------------------------------------------------
Ctl-Opt copyright('Sitemule - System & Method (C), 2025');
Ctl-Opt BndDir('NOXDBUTF8') CCSID(*CHAR:*UTF8);
Ctl-Opt dftactgrp(*NO) ACTGRP('QILE') option(*nodebugio:*srcstmt:*nounref) ALWNULL(*USRCTL);
Ctl-Opt main(main) ;

/include qrpgleref,noxDbUtf8

// ------------------------------------------------------------------------------------
dcl-proc main;

  // Run the examples
  iterKeys();
  iterValues();
  iterArray();

end-proc;
// --------------------------------------------------------------------------------------
dcl-proc iterArray export;
  dcl-s json pointer;
  dcl-ds iterator likeds(nox_iterator);
  dcl-s value varchar(50);

  json = nox_parseString('[ "alpha", "beta", "gamma" ]');
  nox_WriteJsonStmf(json : '/prj/NOXDBUTF8/testout/ex15iter-01.json' : 1208 : *OFF);


  iterator = nox_setIterator(json);
  dow (nox_forEach(iterator));
    value = nox_getStr(iterator.this);
    nox_joblog( value);
  enddo;

  on-exit;
    nox_delete(json);
end-proc;

// --------------------------------------------------------------------------------------
dcl-proc iterValues export;
  dcl-s json pointer;
  dcl-ds iterator likeds(nox_iterator);
  dcl-s value varchar(50);

  json = nox_parseString('{ "values" : [ "alpha", "beta", "gamma" ] }');
  nox_WriteJsonStmf(json : '/prj/NOXDBUTF8/testout/ex15iter-02.json' : 1208 : *OFF);


  iterator = nox_setIterator(json : 'values');
  dow (nox_forEach(iterator));
    value = nox_getValueStr(iterator.this);
    nox_joblog( value);
  enddo;

  on-exit;
    nox_delete(json);
end-proc;

// --------------------------------------------------------------------------------------
dcl-proc iterKeys export;
  dcl-s json pointer;
  dcl-ds iterator likeds(nox_iterator);
  dcl-s value varchar(50);

  json = nox_parseString('{ "value1" : "alpha", "value2" : "beta", "value3" : "gamma" }');
  nox_WriteJsonStmf(json : '/prj/NOXDBUTF8/testout/ex15iter-03.json' : 1208 : *OFF);

  iterator = nox_setIterator(json);
  dow (nox_forEach(iterator));
    value = nox_getName(iterator.this);
    nox_joblog( value);
    value = nox_getValueStr(iterator.this);
    nox_joblog( value);
  enddo;

  on-exit;
    nox_delete(json);
end-proc;