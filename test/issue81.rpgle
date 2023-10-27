**free
    Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

    /include 'headers/XMLPARSER.rpgle'

    Dcl-S pXml         Pointer;
    Dcl-S pA           Pointer;
    Dcl-S result        varchar(4096);


    //------------------------------------------------------------- *
    pXml = xml_parseString('                   -
        <a>                                    -
            <l>1<c>c</c></l>                    -
            <l>2</l>                            -
            <k>3</k>                            -
            <l>4</l>                            -
        </a>                                   -
    ');



    // Test serialization of only selected elements
    Result = xml_asXmlText (pXml);
    xml_WriteXmlStmf (pXml: '/prj/noxdb/testout/selected-1.xml' : 1208: *OFF);

    pA = xml_locate(pXml : '/a');
    Result = xml_asXmlText (pA);
    xml_WriteXmlStmf (pA: '/prj/noxdb/testout/selected-2.xml' : 1208: *OFF);

    pA = xml_locate(pXml : '/a/l');
    Result = xml_asXmlText (pA);
    xml_WriteXmlStmf (pA: '/prj/noxdb/testout/selected-3.xml' : 1208: *OFF);

    pA = xml_locate(pXml : '/a/l[0]');
    Result = xml_asXmlText (pA);
    xml_WriteXmlStmf (pA: '/prj/noxdb/testout/selected-4.xml' : 1208: *OFF);

    pA = xml_locate(pXml : '/a/l[1]');
    Result = xml_asXmlText (pA);
    xml_WriteXmlStmf (pA: '/prj/noxdb/testout/selected-5.xml' : 1208: *OFF);

    pA = xml_locate(pXml : '/a/l[2]');
    Result = xml_asXmlText (pA);
    xml_WriteXmlStmf (pA: '/prj/noxdb/testout/selected-6.xml' : 1208: *OFF);


    xml_delete(pXml);

    Return;