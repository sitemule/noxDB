
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pObj         Pointer;
        Dcl-S pA           Pointer;
        Dcl-S pA2          Pointer;
        Dcl-S pB           Pointer;
        Dcl-S pB2          Pointer;
        Dcl-S pB3          Pointer;

        //------------------------------------------------------------- *

        Dcl-Pi JSON10;
          pResult Char(50);
        End-Pi;

        // Create two objects, and move the conent of b into the root
        pObj = json_newObject();
        pA   = json_locateOrCreate(pObj : 'aValue');
        pA2  = json_setStr(pA : '' : 'Value for a');

        pB   = json_newObject();
        pB2  = json_locateOrCreate(pB   : 'bValue');
        pB3  = json_setStr(pB2: '' : 'Value for b');

        json_MoveObjectInto(pObj : 'bObject' : pB);

        pResult = json_asJsonText(pObj);

        json_close(pObj);

        *Inlr = *on;
        return;