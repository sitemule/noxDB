
        //------------------------------------------------------------- *

        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include xmlParser
        Dcl-S pXml         Pointer;
        Dcl-S pA           Pointer;
        Dcl-S lCount       Int(10);
        Dcl-S kCount       Int(10);
        Dcl-S countChildren Int(10);

        //------------------------------------------------------------- *

        pXml  = nox_parseString('                  -
            <a>                                    -
               <l>1</l>                            -
               <l>2</l>                            -
               <k>x</k>                            -
               <l>3</l>                            -
            </a>                                   -
        ');

        // Count number of l and k tags
        lCount = nox_getNum(pXml : '/a/l[UBOUND]');
        kCount = nox_getNum(pXml : '/a/k[UBOUND]');

        // relative Count number of l and k tags
        pA = nox_locate(pXml : '/a');
        lCount = nox_getNum(pA   : 'l[UBOUND]');
        kCount = nox_getNum(pA   : 'k[UBOUND]');

        // relative Count number childrens of a
        pA = nox_locate(pXml : '/a');
        countChildren  =   nox_getNum(pA  : '[UBOUND]');

        nox_Close(pXml);
        *inlr = *on;
