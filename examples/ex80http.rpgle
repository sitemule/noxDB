**FREE
// ------------------------------------------------------------------------------------
// noxDB - Not only XML. JSON, SQL and XML made easy for RPG
//
// Company . . . : System & Method A/S - Sitemule
// Design  . . . : Niels Liisberg
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
// Using the http request
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
// call ...
// ------------------------------------------------------------------------------------
Ctl-Opt copyright('Sitemule - System & Method (C), 2025');
Ctl-Opt BndDir('NOXDBUTF8') CCSID(*CHAR:*JOBRUN); // CCSID(*CHAR:*UTF8);
Ctl-Opt dftactgrp(*NO) ACTGRP('QILE') option(*nodebugio:*srcstmt:*nounref) ALWNULL(*USRCTL);
Ctl-Opt main(main) ;

/include qrpgleref,noxDbUtf8

// ------------------------------------------------------------------------------------
dcl-proc main;

    dcl-s memuse       int(20);

    // Take a snapshot of the memory usage before we start
    memuse = nox_memUse();

    // Setup trace/debugging ( or perhaps unit testing) for
    // your code if you like - this is optional
    // myTrace is defined in the bottom in the example
    // Note - you can disable the trace by setting it to *NULL
    nox_setTraceProc (%paddr(myTrace));


    // Run the examples
    example1();
    example2();
    example3();
    example4();
    example5();

// Always remember to delete used memory !!
on-exit;
    if memuse <> nox_memuse();
        nox_joblog( 'Ups - forgot to clean something up');
    endif;

end-proc;

// --------------------------------------------------------------
// Flowrates - JSON request
// Use YUM to install curl, which is the tool used by httpRequest
// --------------------------------------------------------------
dcl-proc example1;

   dcl-s  pResponse 	pointer;

   // Do the http request to get exchangerates from floatrates.com
   pResponse = nox_httpRequest (
      'http://www.floatrates.com/daily/dkk.json':
      *null:   // request - none
      *null:   // options - none
      'JSON'   // we expect a JSON response
   );

   nox_WriteJsonStmf(pResponse:'/prj/noxdbutf8/testout/ex80-floatrates.json':1208:*OFF);

// Always remember to delete used memory !!
on-exit;

   nox_delete(pResponse);

end-proc;
// --------------------------------------------------------------
// Currencies from National Bank of Denmark - XML
// --------------------------------------------------------------
dcl-proc example2;

   dcl-s  pResponse 	pointer;
   dcl-s  url  	  	varchar(1024);

   // parameters on URL
   url = 'https://www.nationalbanken.dk/api/currencyratesxml?lang=en';

   // Note: No payload in the request. use *null - here we pass a null

   // Do the http request to get exchangerates from the Danish National bank
   // Use YUM to install curl, which is the tool used by httpRequest
   // The request object with XML and JSON has to be a NoxDb node or *null
   pResponse = nox_httpRequest (url: *null :*null:'XML');

   nox_WriteXmlStmf(pResponse:'/prj/noxdbutf8/testout/ex80-national-bank.xml':1208:*OFF);

// Always remember to delete used memory !!
on-exit;

   nox_delete(pResponse);

end-proc;
// --------------------------------------------------------------
// Google search
// --------------------------------------------------------------
dcl-proc example3;

   dcl-s  pResponse 	pointer;
   dcl-s  response   like(UTF8) based(pResponse) ; // Note: this have to be UTF-8  size 4!!


   // Do the http request to get simple text response
   // Use YUM to install curl, which is the tool used by httpRequest
   // It is: Url is given, No request = GET , No options = simple get
   // The request object with XML and JSON has to be a NoxDb node or *null
   pResponse = nox_httpRequest (
      'https://google.com':
      *null :
      *null :
      'TEXT'
   );

   // Note: When using 'TEXT' mode, then the  response is not a node, but a pointer to a varchar(xx:4) in UTF-8.
   // After use, the correct way to dispose the memory is with nox_delete()
   nox_WriteStrStmf(response:'/prj/noxdbutf8/testout/ex80-google.txt');


// Always remember to delete used memory !!
on-exit;

   nox_delete(pResponse);

end-proc;
// --------------------------------------------------------------
// Post a form
// Note: Both request and response are here plain text
// The request have to be UTF-8 ( size 4) - and the response is also UTF-8 (size 4) !!
// the response memory is build by nox_httpRequest - so it have to be deleted with nox_delete ()
// --------------------------------------------------------------
dcl-proc example4;

   dcl-s  request    varchar(256:4) ccsid(*UTF8); // Note: for form post - this have to be UTF-8  size 4!!
   dcl-s  options    varchar(2048);
   dcl-s  pResponse 	pointer;
   dcl-s  response   like(UTF8) based(pResponse) ; // Note: for form post - this have to be UTF-8  size 4!!
   dcl-s  url  	  	varchar(1024);


   // The URL to the text resource:
   url = 'https://www.w3schools.com/action_page.php';

   // Note: This is a form request.
   // For "TEXT" mode this have to be a varchar(xx:4) utf8
   request = 'fname=John&lname=Doe';

   options = ('-
     -H ''content-type: application/x-www-form-urlencoded'' -
   ');

   // Do the http request to post a form
   // Use YUM to install curl, which is the tool used by httpRequest
   pResponse = nox_httpRequest (url : %addr(request) : options : 'TEXT');

   // Note: When using 'TEXT' mode, then the  response is not a node, but pointer to a varchar(xx:4) in UTF-8.
   // After use, the correct way to dispose the memory is with nox_delete()
   nox_WriteStrStmf(response:'/prj/noxdbutf8/testout/ex80-text.txt');

   nox_joblog (response);

// Always remember to delete used memory !!
on-exit;

   nox_delete(pResponse);


end-proc;

// --------------------------------------------------------------
// json PUT request
// --------------------------------------------------------------
dcl-proc example5;

   dcl-s  url  	  	varchar(1024);
   dcl-s  pReq   	  	pointer;
   dcl-s  options    varchar(2048);
   dcl-s  pResponse 	pointer;

   // the service URL
   url = 'http://www.icebreak.org/services/appstore/getrows';

   // Build a JSON object for the request
   pReq = nox_Object(
      'Request' :
         nox_Object(
            'AppId'   : nox_Int(1234567890):
            'Version' : nox_Str('1.0.0')   :
            'Params'  :
               nox_Object(
                  'search' : nox_Str('*ALL')
               )
         )
   );

   // This service expect a PUT method
   options = ('-
     -X PUT    -
   ');

   // Do the http request to get next depature
   // Use YUM to install curl, which is the tool used by httpRequest
   pResponse = nox_httpRequest (url: pReq: options :'JSON');

   nox_WriteJsonStmf(pResponse:'/prj/noxdbutf8/testout/ex80-Put.json':1208:*OFF);

// Always remember to delete used memory !!
on-exit;
   nox_delete(pReq);
   nox_delete(pResponse);

end-proc;
// ------------------------------------------------------------------------------------
// myTrace - an example of a trace procedure for debugging and unit test
// This will be called each time you interact with the objec graph - if set by
// nox_SetTraceProc ( %paddr(myTrace));
// ------------------------------------------------------------------------------------
dcl-proc myTrace;

    dcl-pi myTrace ;
        text  char(30) const;
        pNode pointer value;
    end-pi;

    dcl-s action char(30);
    dcl-s showme varchar(32000);

    // I could just have it in variables that i debug
    action = text;
    showme = nox_AsJsonText(pNode);

    // .. And I could put it into the joblog
    nox_joblog(Text);
    nox_joblog(showme);

    // Or maybe put it into a stream file
    //nox_WriteJsonStmf(pJson:'/prj/noxdbutf8/testout/trace.json':1208:*OFF);

    // Or place it into a trace table.. Up to you !!


end-proc;

