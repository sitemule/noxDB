
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE');

        //------------------------------------------------------------- *
        
        /include 'headers/XMLPARSER.rpgle'

        Dcl-F qprint PRINTER;

        // Globals
        Dcl-S pXml         Pointer;
        Dcl-S id           Varchar(32);

      //' -----------------------------------------------------------
      //' Mainline
      //' -----------------------------------------------------------

        pXml  = nox_ParseFile('/udv/expert/XmlSample1.xml':'syntax=LOOSE');
        if nox_Error(pXml) ;
           Print(nox_Message(pXml));
        else;
           id = nox_Getvalue(pXml: '/invoice/com:id ': 'N/A');
           id = nox_Getvalue(pXml: '/Myroot/myelement[1]@myattribute1 ': 'N/A');
           print(id);
        endif;
        nox_Close(pXml);
        *inlr = *on;
       /end-free

        //------------------------------------------------------------- *

        Dcl-Proc Print;
          Dcl-PI Print;
            Str        Char(132)  const;
            End-DS;
            Dcl-DS Buf Char(132);
        Buf = str;
        write qprint Buf;
          End-Proc;

