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
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
/include qrpgleRef,noxdb

    Dcl-PR jx_asXmlTextMem uns(10) extproc(*CWIDEN : 'jx_AsXmlTextMem');
      node pointer value;
      buffer pointer value;
    End-PR;


    dcl-ds xmlBugBufds qualified;
      varcharbuf  varchar(960000:4);
      len  int(10) pos(1);
      buf char(960000) pos(5);
    end-ds;

    dcl-s pInput pointer;


    pInput = json_sqlResultSet  (
        'select * from qiws.qcustcdt'
    );


    xmlBugBufds.len = jx_asXmlTextMem(pInput : %addr(xmlBugBufds.buf));

    json_delete(pInput);

   // That's it..
   *inlr = *on;
