
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

        /include 'headers/XMLPARSER.rpgle'

        Dcl-S pXml         Pointer;
        Dcl-S pA           Pointer;
        Dcl-S lCount       Int(10);
        Dcl-S kCount       Int(10);
        Dcl-S countChildren Int(10);

        Dcl-S Result Varchar(50);

        Dcl-C OB Const(x'9E');
        Dcl-C CB Const(x'9F');

        //------------------------------------------------------------- *

        Dcl-Pi XML4;
          pResult Char(50);
        End-Pi;

        Result = '';

        pXml = xml_parseString('                   -
            <a>                                    -
               <l>1</l>                            -
               <l>2</l>                            -
               <k>x</k>                            -
               <l>3</l>                            -
            </a>                                   -
        ');

        // Count number of l and k tags
        lCount = xml_getNum(pXml : '/a/l' + OB + 'UBOUND' + CB);
        kCount = xml_getNum(pXml : '/a/k' + OB + 'UBOUND' + CB);

        Result += %Char(lCount) + %Char(kCount);

        // relative Count number of l and k tags
        pA = xml_locate(pXml : '/a');
        lCount = xml_getNum(pA   : 'l' + OB + 'UBOUND' + CB);
        kCount = xml_getNum(pA   : 'k' + OB + 'UBOUND' + CB);

        Result += %Char(lCount) + %Char(kCount);

        // relative Count number childrens of a
        pA = xml_locate(pXml : '/a');
        countChildren  =   xml_getNum(pA  : OB + 'UBOUND' + CB);

        Result += %Char(countChildren);

        pResult = Result;

        xml_Close(pXml);
        
        Return;