
        //------------------------------------------------------------- *
        
        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/XMLPARSER.rpgle'
        Dcl-S pXml1        Pointer;
        Dcl-S msg          Varchar(50);

        //------------------------------------------------------------- *

        // first we run the paser on an empty string giving us an empty tree
        pXml1 = nox_ParseString('':'syntax=LOOSE,keys=/[@].');
        if nox_Error(pXml1) ;
           msg = nox_Message(pXml1);
           nox_Close(pXml1);
           return;
        endif;

        nox_SetValue(pXml1: '/root/first@atr1' : 'value for atr1');
        nox_SetValue(pXml1: '/root/first@atr2' : 'value for atr2');
        nox_SetValue(pXml1: '/root/next@nextAtr' : 'value for next atr');
        nox_SetValue(pXml1: '/root/next' : 'value for next  element');

        nox_SetValue(pXml1: '/root/row[NEW]' : 'value for next  element');
        nox_SetValue(pXml1: '/root/row[LAST]@nextAtr' : 'value for next atr');
        nox_SetValue(pXml1: '/root/row[LAST]@atr' : 'value for next atr');

        nox_SetValue(pXml1: '/root/row[NEW]' : 'value for next  element');
        nox_SetValue(pXml1: '/root/row[LAST]@nextAtr' : 'value for next atr');
        nox_SetValue(pXml1: '/root/row[LAST]@atr' : 'value for next atr');

        nox_SetValue(pXml1: '/root/row[NEW]' : 'value for next  element');
        nox_SetValue(pXml1: '/root/row[LAST]@nextAtr' : 'value for next atr');
        nox_SetValue(pXml1: '/root/row[LAST]@atr' : 'value for next atr');
        // Finally we can produce the XML file
        nox_writeStmf(pXml1 : '/udv/expert/sampleout6a.xml' : 1208);
        nox_Close(pXml1);
        *inlr = *on;
