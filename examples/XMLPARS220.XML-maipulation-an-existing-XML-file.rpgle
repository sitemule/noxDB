**free
// -------------------------------------------------------------
// noxDB - Not only XML. JSON, SQL and XML made easy for RPG
//
// Company . . . : System & Method A/S - Sitemule
// Design  . . . : Niels Liisberg
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
//
// -------------------------------------------------------------

// -------------------------------------------------------------
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
Dcl-S pXml               Pointer;
Dcl-S pElem              Pointer;
Dcl-S pHives             Pointer;
Dcl-S pMenu              Pointer;
Dcl-S msg                VarChar(50);
/include qrpgleRef,noxdb

   *INLR = *ON;

   xml_setDelimiters('/\@[] .{}''"$');

   // first we run the paser on a input file
   pXml = xml_ParseFile ('/prj/noxdb/testdata/webconfig.xml');
   If xml_Error(pXml) ;
      msg = xml_Message(pXml);
      xml_joblog(pXml);
      xml_delete(pXml);
      Return;
   EndIf;

   // Handle a structure like this:
   //  <configuration>
   //     <hives>
   //        <map alias="menu"
   //           path="/prj/icecap/client"
   //           lib="*LIBL"
   //        />
   //  ..

   // Now we retrive an element pointer from the root
   pHives = xml_locate(pXml:'/configuration/hives');
   If pHives  = *NULL;
      xml_joblog('Missing hive tag in webconfig');
      xml_delete(pXml);
      Return;
   endif;

   // If we have an element called "map" with atribute "alias" set to "menu"
   pMenu  = xml_locate(pHives:'map[@alias=menu]');
   if pMenu = *NULL;
      pMenu = xml_elementAdd(pHives:xml_LAST_CHILD:'map':'');
      xml_SetAttrValue  (pMenu : 'alias' : 'menu');
   endif;

   // Set new values:
   xml_SetAttrValue  (pMenu : 'path'  : '/www/icecap/client');
   xml_SetAttrValue  (pMenu : 'lib'   : 'ICECAP');

   // Produce the output: Not the *OFF for trim causes the formating to retain
   xml_writeStmf(pXml : '/prj/noxdb/testout/webconfig.xml': 1208: *OFF);
   xml_delete(pXml);
