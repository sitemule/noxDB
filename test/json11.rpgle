
        Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pObj         Pointer;
        Dcl-S pB           Pointer;
        Dcl-S pBval        Pointer;

        //------------------------------------------------------------- *

        Dcl-Pi JSON11;
          pResult Char(50);
        End-Pi;

        pObj = json_newObject();
        json_setStr(pObj : 'a' : 'Value for a');

        pB    = json_newObject();
        pBval = json_setStr(pB : 'bValue' : 'Value for b');

        json_MoveObjectInto(pObj : 'newBvalue' : pBval);

        // Note : pB is now dangerling since it is a empty object
        // atfer the move it is allone in the world,
        // So we need to delete it by hand
        json_close(pB);

        pResult = json_asJsonText(pObj);
        json_close(pObj);

        *Inlr = *on;
        return;