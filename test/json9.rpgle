
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pObj         Pointer;
        Dcl-S pA           Pointer;
        Dcl-S pB           Pointer;

        //------------------------------------------------------------- *

        Dcl-Pi JSON9;
          pResult Char(50);
        End-Pi;

        // Create two objects, and move the conent of b into the root
        pObj = json_newObject();
        json_setStr(pObj : 'a' : 'Value for a');

        pB   = json_newObject();
        json_setStr(pB : 'bValue' : 'Value for b');

        json_MoveObjectInto(pObj : 'bObject': pB);

        pResult = json_asJsonText(pObj);

        json_close(pObj);

        *Inlr = *on;
        return;