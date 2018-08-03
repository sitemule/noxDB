      * ------------------------------------------------------------- *
      * This sample shows the use of the build in Xml parser in
      * IceBreak
      *
      * ------------------------------------------------------------- *
     H BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' )
     D pXml            s               *
     D pA              s               *
     D lCount          s             10i 0
     D kCount          s             10i 0
     D countChildren   s             10i 0
      /include xmlParser
      /free
        pXml  = xml_parseString('                  -
            <a>                                    -
               <l>1</l>                            -
               <l>2</l>                            -
               <k>x</k>                            -
               <l>3</l>                            -
            </a>                                   -
        ');

        // Count number of l and k tags
        lCount = xml_getNum(pXml : '/a/l[UBOUND]');
        kCount = xml_getNum(pXml : '/a/k[UBOUND]');

        // relative Count number of l and k tags
        pA = xml_locate(pXml : '/a');
        lCount = xml_getNum(pA   : 'l[UBOUND]');
        kCount = xml_getNum(pA   : 'k[UBOUND]');

        // relative Count number childrens of a
        pA = xml_locate(pXml : '/a');
        countChildren  =   xml_getNum(pA  : '[UBOUND]');

        xml_Close(pXml);
        *inlr = *on;
