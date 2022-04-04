**FREE
//  -------------------------------------------------------------
//  noxDB - Not only XML. JSON, SQL and XML made easy for RPG
//
//  Company . . . : System & Method A/S - Sitemule
//  Design  . . . : Niels Liisberg
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
//  Look at the header source file "QRPGLEREF" member "NOXDB"
//  for a complete description of the functionality
//
//  Talk to watson
//
//  -------------------------------------------------------------
ctl-opt copyright('System & Method (C), 2018');
ctl-opt decEdit('0,') datEdit(*YMD.) main(main);
ctl-opt bndDir('NOXDB' );
/include qrpgleRef,noxdb

// --------------------------------------------------------------
// Next departure from Mols Linien
// --------------------------------------------------------------
dcl-proc main;

   dcl-s  pReq   	  		pointer;
   dcl-s  pResponse 		pointer;
   dcl-s  url  	  	  	varchar(1024);

   // Always set your ccsid for constants: 
   json_setDelimitersByCcsid(500);

   // parameters on URL
   url = 'https://www.molslinjen.dk/umbraco/api/departure/getnextdepartures?departureRegionId=JYL';

   // Do the http request to get next depature
   // Use YUM to install curl, which is the tool used by httpRequest
   pResponse = json_httpRequest (url: pReq);

   json_WriteJsonStmf(pResponse:'/prj/noxdb/testout/httpdump.json':1208:*OFF);

   json_delete(pReq);
   json_delete(pResponse);

end-proc;
