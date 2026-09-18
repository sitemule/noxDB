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


  dcl-s pInput  pointer;
  dcl-s toParseA   varchar(256) ccsid(1208);
  dcl-s toParseE   varchar(256);
  dcl-s Athens  varchar(256) ccsid(1208);
  dcl-s Danish  varchar(256) ;

  dcl-ds xmlBugBufds qualified;
    varcharbuf  varchar(960000:4);
    len  int(10) pos(1);
    buf char(960000) pos(5);
  end-ds;

  // Test the XML - UTF-8 input
  Athens = x'CE88CEB8CEB8CE86CEBDCEB1CEB9';
  toParseA = '<xml>' + Athens + '</xml>' + x'00';
  pInput = json_parseString ( %addr(toParseA:*data));
  xmlBugBufds.len = json_asXmlTextMem(pInput : %addr(xmlBugBufds.buf));
  json_delete(pInput);


  // Test the XML - SBCS strings
  Danish = 'Smørrebrødspålæg';
  toParseE = '<xml>' + Danish + '</xml>';
  pInput = json_ParseString (toParseE);
  xmlBugBufds.len = json_asXmlTextMem(pInput : %addr(xmlBugBufds.buf));
  json_delete(pInput);


  // Test the JSON  - UTF-8 input - only works if job runs in ccsid 500 as compiled obj 
  Athens = x'CE88CEB8CEB8CE86CEBDCEB1CEB9';
  toParseA = '{"key":"' + Athens + '"}' + x'00';
  pInput = json_parseString ( %addr(toParseA:*data));
  xmlBugBufds.len = json_asJsonTextMem(pInput : %addr(xmlBugBufds.buf));
  json_delete(pInput);


  // Test the JSON - SBCS strings
  Danish = 'Smørrebrødspålæg';
  toParseE = '{"key":"' + Danish + '"}' + x'00';
  pInput = json_ParseString (toParseE);
  xmlBugBufds.len = json_asJsonTextMem(pInput : %addr(xmlBugBufds.buf));
  json_delete(pInput);


   // That's it..
   *inlr = *on;
