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
     // translate text using watson API:
     // https://watson-api-explorer.mybluemix.net/
     // --------------------------------------------------------------
     dcl-proc main;

        dcl-s  pReq   	  		pointer;
        dcl-s  pResponse 		pointer;
        dcl-s  url  	  	  	varchar(1024);
        dcl-s  text 	  	  	varchar(4096);
        dcl-s  dsp     	  	char   (52);

        pReq = json_newObject();
        json_setStr (pReq : 'source'   : 'en');
        json_setStr (pReq : 'target'   : 'es');
        json_setStr (pReq : 'text'     : 'Good afternoon my friends');

        url = 'https://watson-api-explorer.mybluemix.net/language-translator/api/v2/translate';

        // Do the http request to watson.
        // Use YUM to install curl, which is the tool used by httpRequest
        pResponse = json_httpRequest (url: pReq);

        // Just debug the response
        text = json_getStr(pResponse : 'translations[0].translation' : 'N/A');
        dsp = text;
        dsply (dsp);

        // Always remember to clean up
        json_delete(pReq);
        json_delete(pResponse);

     end-proc;
