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
//  HTTP request examples
//
//  -------------------------------------------------------------
ctl-opt copyright('System & Method (C), 2018');
ctl-opt decEdit('0,') datEdit(*YMD.) main(main);
ctl-opt bndDir('NOXDB' );
/include qrpgleRef,noxdb

// --------------------------------------------------------------
dcl-proc main;

   jsonRequest();
   xmlRequest();
   textGetRequest();
   textPostRequest();   

end-proc;

// --------------------------------------------------------------
// Next departure from Mols Linien
// --------------------------------------------------------------
dcl-proc jsonRequest;

   dcl-s  pReq   	  	pointer;
   dcl-s  pResponse 	pointer;
   dcl-s  url  	  	varchar(1024);

   // parameters on URL
   url = 'https://www.molslinjen.dk/umbraco/api/departure/getnextdepartures?departureRegionId=JYL';

   // Note: No payload in the request. use *null - here we pass a null pointer  
   // Note: No options in the request. use *null - here we pass the *null literal value
   
   // Do the http request to get next depature
   // Use YUM to install curl, which is the tool used by httpRequest
   pResponse = json_httpRequest (url: pReq:*null:'JSON');

   json_WriteJsonStmf(pResponse:'/prj/noxdb/testout/httpdump.json':1208:*OFF);

   json_delete(pReq);
   json_delete(pResponse);

end-proc;
// --------------------------------------------------------------
// Currencies from national bank of Denmark
// --------------------------------------------------------------
dcl-proc xmlRequest;

   dcl-s  pReq   	  	pointer;
   dcl-s  pResponse 	pointer;
   dcl-s  url  	  	  	varchar(1024);

   // parameters on URL
   url = 'https://www.nationalbanken.dk/_vti_bin/DN/DataService.svc/CurrencyRatesXML?lang=en';

   // Note: No payload in the request. use *null - here we pass a null pointer  
   // Note: No options in the request. use *null - here we pass the *null literal value

   // Do the http request to get exchangerates from the Danish National bank
   // Use YUM to install curl, which is the tool used by httpRequest
   // The request object with XML and JSON has to be a NoxDb node or *null
   pResponse = json_httpRequest (url: pReq:*null:'XML');

   json_WriteXmlStmf(pResponse:'/prj/noxdb/testout/httpdump.xml':1208:*OFF);

   json_delete(pReq);
   json_delete(pResponse);

end-proc;
// --------------------------------------------------------------
// Google search 
// --------------------------------------------------------------
dcl-proc textGetRequest;

   dcl-s  pResponse 	pointer;
   dcl-s  url  	  	varchar(1024);
   dcl-s  text  	  	varchar(1024);

   // The URL to the text resource:
   url = 'https://google.com';

   // Do the http request to get simple text response
   // Use YUM to install curl, which is the tool used by httpRequest
   // It is: Url is given, No request = GET , No options = simple get
   // The request object with XML and JSON has to be a NoxDb node or *null
   pResponse = json_httpRequest (url: *null : *null :'TEXT');

   // Note: When using 'TEXT' mode, then the response is not a node, but a string.
   // After use, the correct way to dispose the memory is with json_delete()
   text = %str(pResponse);
   
   json_joblog (text);

   json_delete(pResponse);

end-proc;
// --------------------------------------------------------------
// Post a form
// --------------------------------------------------------------
dcl-proc textPostRequest;

   dcl-s  req        varchar(256);
   dcl-s  options    varchar(2048);
   dcl-s  pResponse 	pointer;
   dcl-s  url  	  	varchar(1024);
   dcl-s  text  	  	varchar(1024);


   // The URL to the text resource:
   url = 'https://www.w3schools.com/action_page.php';

   // Note: This is a form request.
   // For "TEXT" mode this have to be a string  
   req = 'fname=John&lname=Doe';

   options = ('-
     -H ''content-type: application/x-www-form-urlencoded'' -
   '); 

   // Do the http request to post a form 
   // Use YUM to install curl, which is the tool used by httpRequest
   pResponse = json_httpRequest (url : req : options : 'TEXT');

   // Note: When using 'TEXT' mode, then tre response is not a node, but a string.
   // After use, the correct way to dispose the memory is with json_delete()
   text = %str(pResponse);
   json_joblog (text);
   json_delete(pResponse);

end-proc;

