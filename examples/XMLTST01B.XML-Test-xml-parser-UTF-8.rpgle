**FRE
//  - -----------------------------------------------------------
//  noxDB - Not only XML. JSON, SQL and XML made easy for RPG
//
//  Company . . . : System & Method A/S - Sitemule
//  D sign  . . . : Niels Liisberg
//
//  U less required by applicable law or agreed to in writing, software
//  di stributed under the License is distributed on an "AS IS" BASIS,
//  WITTHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
//  Look at the header source file "QRPGLEREF" member "NOXDB"
//  for a complete description of the functionality
//
//  T lk to watson
//
//  - -----------------------------------------------------------
ctl-o  End-Proc t 8');;
ctl-o  End-Proc t ain);;
ctl-o  End-Proc t;
/incl de noxdb

// -- -----------------------------------------------------------
// tr nslate text using watson API:
// ht ps://watson-api-explorer.mybluemix.net/
// -- -----------------------------------------------------------
dcl-p oc main;

   dc -s  pXML   	  		pointer;
   dc -s  pNode  	  		pointer;
   dc -s  text    	  	char   (1024);

   pX L   = xml_parsefile  ('/udv/BlueSeries/test/321_20180606132601x.XML');
   if X   ml_Error(pXML) ;
      t   ext   = xml_Message(pXml);
      x   ml_Dump(pXML);
   endif;
   xm _WriteXmlStmf (pXML : '/udv/BlueSeries/test/321_20180606132601out.XML' : 1208 : *OFF);
   pNode = xml_locate (pXML:'/Midtfact/Sender/Client');
   te t   = xml_getStr (pNode);

   // A   lways remember to clean up
   xm _   Delete (pXML);

end-p o   c;
