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
// Look at the header source file "QRPGLEREF" member "NOXDB"
// for a complete description of the functionality
//
//
// -------------------------------------------------------------

// Step 1)
// When using the XML parser - always bind your program to the NOXDB
// bind directory - either by the CRTPGM command or add the "H" spec below:

// Step 2)
// Include the prototypes for the xml parser found in member "NOXDB"
// in the source file "QRPGLEREF" in the IceBreak   library

// Step 3)
// Parse your XML file by caling the "xml_Parse" function. It returns
// logical *ON if the parser completed ok - When an error occures
// use the function "xml_GetMsg" to retrive the error and/or
// use the function "xml_Dump"   to display the xml-tree contents

// Step 4)
// Locate each element node by the function "xml_Locate".
// the location can be relative or from the root by prefixinig the location
// with an "/". Each level is separated by a "/" e.g.
// "/MyRoot/MyElement"  is "myelement" found within "myroot"

// Step 5)
// When a element node is sucessfully fetched, then you can
// can retrieve its value by "xml_GetElemValue" and it attributes
// with "xml_GetAttr". Note that you can supply a default
// value forboth - if the node/attribute is not found.
// Enshure that your result variable is big enough to hold the result
// - otherwise unpredictble results may occure.

// Step 6)
// Itterate through all elements by returning the next element
// with "xml_GetElemNext" until it returns *NULL

// Step 7)
// Last - remember to close the XML tree with "xml_delete"


// The XML file we want to parse in this sample look like:

// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
/include qrpgleRef,noxdb

Dcl-S  pXml      Pointer;
Dcl-S  pA        Pointer;
Dcl-S  pB        Pointer;
Dcl-S  pC        Pointer;
Dcl-S  msg       VarChar(50);
Dcl-S  value     VarChar(50);
Dcl-S  xml       VarChar(4096);
Dcl-S  i         int(5);
Dcl-S  lenC      int(5);
Dcl-DS list      likeds(xml_iterator);

   // To acces the graph, delimiter has to be the the same in to noxDb and you code
   xml_setDelimitersByCcsid (0); // 0=Current job, but has to be the same as you CCSID on your *SRCPF
   
   // A simple XML document;
   xml = '<a>Value for a'
      +    '<b> value for b'
      +       '<c>Value for first c'
      +          '<cA>11</cA>'
      +          '<cB>12</cB>'
      +          '<cC>13</cC>'
      +       '</c>'
      +       '<c>Value for next c'
      +          '<cA>21</cA>'
      +          '<cB>22</cB>'
      +       '</c>'
      +    '</b>'
      + '</a>';


   // First parse the XML string
   pXml = xml_ParseString(xml);
   If xml_Error(pXml) ;
      msg = xml_Message(pXml);
      xml_delete(pXml);
      Return;
   EndIf;

   // Print out the parser value:
   xml_WriteXmlStmf (pXml: '/prj/noxdb/testout/simple-abc.xml' : 1208: *OFF);

   // To to the top
   // note: pXml and pA is not the same:
   // pXml is the document, pA is the a element
   pA = xml_locate (pXml : '/a');
   value = xml_getStr(pA);
   xml_joblog(value);

   // relative: from a find b
   pB = xml_locate (pA : 'b');
   value = xml_getStr(pB);
   xml_joblog(value);

   // relative: find first c from b
   pC = xml_locate (pB : 'c[0]');
   value = xml_getStr(pC:'cA');
   xml_joblog(value);
   value = xml_getStr(pC:'cB');
   xml_joblog(value);

   // relative: find next c from b
   pC = xml_locate (pB : 'c[1]');
   value = xml_getStr(pC:'cA');
   xml_joblog(value);
   value = xml_getStr(pC:'cB');
   xml_joblog(value);

   // -------------------------------------
   // More simple than above with iterator:
   // However: Since XML can have a mixture 
   // of child elements, we need to filter 
   // only "c" nodes, so the iterator
   // need to locate the "b" element
   // Remember that the iterator runs through each child: c is child of b
   // A future xml_setXmlIterator will handle this more elegantly
   list = xml_setIterator(pXml : '/a/b');  
   DoW xml_ForEach(list);
      if xml_getName(list.this) = 'c';
         value = xml_getStr  (list.this: 'cA');
         xml_joblog(value);
         value = xml_getStr  (list.this: 'cB');
         xml_joblog(value);
      endif;
   EndDo;

   // -------------------------------------
   // By element number:
   // Note: in the loop we have to state which "c"
   // So we need to do that from absolute - like: /a/b/c[0]
   // or relative from "b" then c[0]
   lenC = xml_getInt (pC:'/a/b/c[UBOUND]');

   for i = 0 to lenC -1;
      pC = xml_locate (pXml : '/a/b/c[' + %char(i) + ']');
      value = xml_getStr  (pC : 'cA');
      xml_joblog(value);
      value = xml_getStr  (pC : 'cB');
      xml_joblog(value);
   EndFor;

// always clean up to avoid memory leakage
xml_delete(pXml);
*inlr = *on;
