        //------------------------------------------------------------- *
        //This sample shows the use of the IceBreak JSON/XML parser

        //Using SQL cursors

        //------------------------------------------------------------- *
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
        Dcl-S pRow         Pointer;
        Dcl-S sqlHnd       Pointer;
        Dcl-S sql          Varchar(512);
        Dcl-S text         Varchar(512);
        Dcl-S ints         Int(10);
        Dcl-S numbers      Zoned(11:2);
        Dcl-S dates        Date;
        Dcl-S msg          Varchar(512);
      /include 'headers/JSONPARSER.rpgle'

        // Open our SQL cursor. Use a simple select
        sqlhnd  = json_sqlOpen(
           'Select * from product'
        );

        // Was there a problem ?
        if json_Error(sqlhnd);
           msg = json_Message(sqlhnd);
           json_sqlDisconnect();
           return;  // You can return, however the rest of the routines a roubust enough to just continue
        endif;

        // Now iterate on each row in the resultset
        pRow = json_sqlFetchNext(sqlhnd);
        dow (pRow <> *NULL );
           ints    = json_getNum (pRow : 'PRODKEY');
           text    = json_getStr (pRow : 'PRODID');
           text    = json_getStr (pRow : 'DESC');
           text    = json_getStr (pRow : 'MANUID');
           numbers = json_getNum (pRow : 'PRICE');
           ints    = json_getNum (pRow : 'STOCKCNT');
           dates   = %date(json_getStr (pRow : 'STOCKDATE'));
           json_NodeDelete(pRow); // Always dispose it before get the next
           pRow = json_sqlFetchNext(sqlhnd);
        enddo;


        // Finaly and always !! close the SQL cursor and dispose the json row object
        json_sqlClose(sqlhnd);
        json_sqlDisconnect();

        // That's it..
        *inlr = *on;



Skip to content
 
Search or jump to…

Pull requests
Issues
Marketplace
Explore
 @NielsLiisberg Sign out
1
2 0 NielsLiisberg/IceBreak-Samples
 Code  Issues 0  Pull requests 0  Projects 0  Wiki  Insights  Settings
IceBreak-Samples/msXlate.rpgle
2e3f8cc  on 23 Oct
@NielsLiisberg NielsLiisberg New version of Watson
     
62 lines (43 sloc)  1.82 KB
<%@ free="true" language="RPGLE" pgmtype="srvpgm" pgmopt="export(*ALL)" %>
<%
ctl-opt copyright('System & Method (C), 2018');
ctl-opt decEdit('0,') datEdit(*YMD.) nomain; 
ctl-opt bndDir('NOXDB' );
/* -----------------------------------------------------------------------------

  CRTICEPGM STMF('/www/IceBreak-Samples/msXlate.rpgle') SVRID(samples)


  By     Date       PTF     Description
  ------ ---------- ------- ---------------------------------------------------
  NLI    22.06.2018         New program
  ----------------------------------------------------------------------------- */
 /include noxdb
 
/* -------------------------------------------------------------------- *\ 
   	translate text using watson API:

	https://watson-api-explorer.mybluemix.net/
		
	dksrv133:60060/router?payload={
		"action"  : "msXlate.translate",
		"model_id": "en-es",
		"text"    : "Good afternoon my friends"
	}

\* -------------------------------------------------------------------- */
dcl-proc translate export;

	dcl-pi *n pointer;
		pInput 				pointer value;
	end-pi;

	dcl-s  pOutput      	pointer;
	dcl-s  pReq   	  		pointer;
	dcl-s  url  	  		varchar(1024);
	dcl-s  text 	  		varchar(4096);
	dcl-s  extraParms  		varchar(4096);
	dcl-c  appkey  		    'xZiVLkVMPE7-ECxvEaJIbZ5nD4QS63bUM63ww-ZxXOi_w'; // <<< Put your applicaton key here

	pReq  = json_newObject();
	
	json_copyValue (pReq : 'model_id' : pInput : 'model_id');
	json_copyValue (pReq : 'text'     : pInput : 'text');
	
	url = 'https://gateway.watsonplatform.net/language-translator/api/v3/translate?version=2018-05-01';
	
	extraParms = '-k --user apikey:' + appkey;
	pOutput = json_httpRequest  (url: pReq : extraParms);

	json_delete(pReq);

	// Just debug the response
	text = json_getStr(pOutput : 'translations[0].translation' : 'N/A');
	consoleLog(text);

	return (pOutput);

end-proc;

© 2018 GitHub, Inc.
Terms
Privacy
Security
Status
Help
Contact GitHub
Pricing
API
Training
Blog
About
Press h to open a hovercard with more details.