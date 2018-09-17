        // ------------------------------------------------------------------------- 
        // noxDB samples - Handeling of Dangling  pointers to Dangling  objects
        // ------------------------------------------------------------------------- 
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pObj         Pointer;
        Dcl-S pDangling    Pointer;
        Dcl-S pString      Pointer;
        Dcl-s s            varchar(256);
        

        // Build an object
        pObj  = json_newObject();
        pString = json_setStr(pObj:  'title'    : 'Just some text');

        // Let a pointer - point to an object we wil delete
        pDangling   = pString;
        json_delete (pString);

        // Now: Dangling will return a blank - and not the original object since it is deleted" 
        s  = json_getStr(pDangling);

        if s <> '';
                dsply 'Dangling does not work as supposed';
        endif;

        json_delete (pObj);
        *inlr = *on;
