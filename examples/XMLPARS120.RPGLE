        //------------------------------------------------------------- *
        //This sample shows the use of the buildin XML parser in
        //IceBreak

        //Look at the header source file "qAspHdr" in the IceBreak   library
        //for a complete description of the functionality

        //Step 1)
        //When using the XML parser - always bind your program to the XMLPARSER
        //bind directory - either by the CRTPGM command or add the "H" spec below:

        //Step 2)
        //Include the prototypes for the xml parser found in member "XMLPARSER"
        //in the source file "qAspHdr" in the IceBreak   library

        //Step 3)
        //Parse your XML file by caling the "xml_Parse" function. It returns
        //logical *ON if the parser completed ok - When an error occures
        //use the function "xml_GetMsg" to retrive the error and/or
        //use the function "xml_Dump"   to display the xml-tree contents

        //Step 4)
        //Locate each element node by the function "xml_Locate".
        //the location can be relative or from the root by prefixinig the location
        //with an "/". Each level is separated by a "/" e.g.
        //"/MyRoot/MyElement"  is "myelement" found within "myroot"

        //Step 5)
        //When a element node is sucessfully fetched, then you can
        //can retrieve its value by "xml_GetElemValue"  and it attributes
        //with "xml_GetAttr". Note that you can supply a default
        //value for both - if the node/attribute is not found.
        //Enshure that your result variable is big enough to hold the result
        //- otherwise unpredictble results may occure.

        //Step 6)
        //Itterate through all elements by returning the next element
        //with "xml_Next" until it returns *NULL

        //Step 7)
        //Last - remember to close the XML tree with "xml_Close"


        //The XML file we want to parse in this sample look like:

        //<?xml version="1.0" encoding="ISO-8859-1"?>
        //<Myroot>
        //<Myelement Myattribute1="My Company name" Myattribute2="1">abc</Mye
        //<Myelement Myattribute1="Another name"    Myattribute2="0">def</Mye
        //</Myroot>

        //------------------------------------------------------------- *
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
        Dcl-F qprint PRINTER;
        Dcl-PR Print;
          Str        Char(132)  const;
          Dcl-PR TraverseTree;
            pElem      Pointer;
          End-PR;

          Dcl-S ok           Ind;
          Dcl-S pXml         Pointer;
          Dcl-S pRoot        Pointer;
      /include xmlparser
        pXml  = xml_ParseFile('/expert/xmlsample1.xml');
        if xml_Error(pXml) ;
           Print(xml_Message(pXml));
        else;
           pRoot = xml_locate(pXml:'/');    // Returns pointer to tree root
           pRoot = xml_getElemChild(pRoot); // Now convert it to the first and only root element
           TraverseTree( pRoot);
        endif;
        xml_Close(pXml);
        *inlr = *on;
       /end-free
          //------------------------------------------------------------- *
          Dcl-Proc TraverseTree;
            Dcl-PI TraverseTree;
              pElem      Pointer;
            End-PI;

            Dcl-S pChild       Pointer;
            Dcl-S pAttr        Pointer;
       dow (pElem <> *NULL);
          print('Name : ' + xml_getElemName(pElem));
          print('Value: ' + xml_getElemValue(pElem : 'N/A'));
          pAttr   = xml_getAttrFirst(pElem);
          dow (pAttr <> *NULL);
             print('  Attribute Name : ' + xml_getAttrName(pAttr));
             print('  Attribute Value: ' + xml_GetAttrValue(pAttr : 'N/A'));
             pAttr   = xml_getAttrNext(pAttr);
          enddo;
          pChild   = xml_getElemChild(pElem);
          TraverseTree( pChild);
          pElem = xml_getElemNext(pElem);
       enddo;
          End-Proc;
          //------------------------------------------------------------- *
          Dcl-Proc Print;
            Dcl-PI Print;
              Str        Char(132)  const;
              End-DS;
              Dcl-DS Buf Char(132);
        Buf = str;
        write qprint Buf;
            End-Proc;

