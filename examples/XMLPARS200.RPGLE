
        //------------------------------------------------------------- *
        
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/XMLPARSER.rpgle'
        Dcl-S pXml1        Pointer;
        Dcl-S msg          Varchar(50);

        //------------------------------------------------------------- *

        // first we run the paser on an empty string giving us an empty tree
        pXml1 = xml_ParseString('':'syntax=LOOSE,keys=/[@].');
        if Xml_Error(pXml1) ;
           msg = xml_Message(pXml1);
           xml_Close(pXml1);
           return;
        endif;

        xml_SetValue(pXml1: '/root/first@atr1' : 'value for atr1');
        xml_SetValue(pXml1: '/root/first@atr2' : 'value for atr2');
        xml_SetValue(pXml1: '/root/next@nextAtr' : 'value for next atr');
        xml_SetValue(pXml1: '/root/next' : 'value for next  element');

        xml_SetValue(pXml1: '/root/row[NEW]' : 'value for next  element');
        xml_SetValue(pXml1: '/root/row[LAST]@nextAtr' : 'value for next atr');
        xml_SetValue(pXml1: '/root/row[LAST]@atr' : 'value for next atr');

        xml_SetValue(pXml1: '/root/row[NEW]' : 'value for next  element');
        xml_SetValue(pXml1: '/root/row[LAST]@nextAtr' : 'value for next atr');
        xml_SetValue(pXml1: '/root/row[LAST]@atr' : 'value for next atr');

        xml_SetValue(pXml1: '/root/row[NEW]' : 'value for next  element');
        xml_SetValue(pXml1: '/root/row[LAST]@nextAtr' : 'value for next atr');
        xml_SetValue(pXml1: '/root/row[LAST]@atr' : 'value for next atr');
        // Finally we can produce the XML file
        xml_writeStmf(pXml1 : '/udv/expert/sampleout6a.xml' : 1208);
        xml_Close(pXml1);
        *inlr = *on;
