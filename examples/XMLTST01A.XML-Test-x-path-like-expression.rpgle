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
   dc -s  val     	  	char   (52);

   pX L   = xml_parseString('-
      <    root> -
            <elm key="1">v1<n k="1" v="11"/><n k="2" v="12"/></elm> -
            <elm key="2">v2<n k="1" v="21"/><n k="2" v="22"/></elm> -
            <elm key="3">v3<n k="1" v="31"/><n k="2" v="32"/></elm> -
      <    /root> -
   ')
   va      = xml_getStr(pXml: '/root/elm[1]@key');
   va     = xml_getStr(pXml: '/root/elm[@key=3]/n[@k=2]@v');

   // A   lways remember to clean up
   xm _   Delete (pXML);

end-p o   c;
