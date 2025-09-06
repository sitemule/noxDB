
        //------------------------------------------------------------- *

        //The XML file we want to parse in this sample look like:

        //<?xml version="1.0" encoding="ISO-8859-1"?>
        //<Myroot>
        //<Myelement Myattribute1="My Company name" Myattribute2="1">abc</Mye
        //<Myelement Myattribute1="Another name"    Myattribute2="0">def</Mye
        //</Myroot>

        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *

        /include xmlparser

        Dcl-F qprint PRINTER;
        Dcl-PR Print;
          Str        Char(132)  const;
        End-Pr;
        Dcl-PR TraverseTree;
          pElem      Pointer;
        End-PR;

        Dcl-S ok           Ind;
        Dcl-S pXml         Pointer;
        Dcl-S pRoot        Pointer;

        //------------------------------------------------------------- *

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
          End-Pi;
          Dcl-DS Buf Char(132);
          End-DS;
          Buf = str;
          write qprint Buf;
        End-Proc;

