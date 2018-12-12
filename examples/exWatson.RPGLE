**free
// -----------------------------------------------------------------------------
//
//  Examples  - Watson and curl
//  
//	https://watson-api-explorer.mybluemix.net/
// 
//  Translate text using watson API:
// -----------------------------------------------------------------------------
ctl-opt copyright('System & Method (C), 2018');
ctl-opt decEdit('0,') datEdit(*YMD.) main(main); 
ctl-opt bndDir('NOXDB');

/include ./headers/jsonparser.rpgle

dcl-proc main;

    dcl-s  pInput 			pointer;
    dcl-s  pOutput      	pointer;
    dcl-s  url  	  		varchar(1024);
    dcl-s  text 	  		char (50);
    dcl-s  extraParms  		varchar(4096);
    dcl-c  appkey  		    'xZiVLkVMPE7-ECxvEaJIbZ5nD4QS63bUM63ww-ZxXOi_w'; // <<< Put your applicaton key here

    // Setup the json object for watson service
	pInput  = json_newObject();
	json_setStr(pInput : 'model_id' : 'en-es');
	json_setStr(pInput : 'text'     : 'Good afternoon my friends');
	
	url = 'https://gateway.watsonplatform.net/language-translator/api/v3/translate?version=2018-05-01';

    // do the Watson magic
	extraParms = '-k --user apikey:' + appkey;
	pOutput = json_httpRequest (url: pInput : extraParms);

	// Just debug the response
	text = json_getStr(pOutput : 'translations[0].translation' : 'N/A');
	dsply text;

    // Done 
    json_delete (pInput);
    json_delete (pOutput);

end-proc;