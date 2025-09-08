
        //------------------------------------------------------------- *

        //This sample shows array handling
        Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE' );

        //------------------------------------------------------------- *

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pObj         Pointer;
        Dcl-S pA           Pointer;
        Dcl-S pAval        Pointer;
        Dcl-S pA2          Pointer;
        Dcl-S pB           Pointer;
        Dcl-S pB2          Pointer;
        Dcl-S pB3          Pointer;
        Dcl-S pBval        Pointer;

        Dcl-S t            Varchar(512);

        //------------------------------------------------------------- *

        // Step 1:
        // Create two objects, and move the conent of b into the root
        pObj = nox_newObject();
        nox_setStr(pObj : 'a' : 'Value for a');

        pB   = nox_newObject();
        nox_setStr(pB : 'bValue' : 'Value for b');

        nox_MoveObjectInto(pObj : 'bObject': pB);

        t =   nox_asJsonText(pObj);
        // done
        nox_close(pObj);

        //------------------------------------------------------------- *

        // Step 2:
        // Do the same with lo-level functions
        pObj = nox_newObject();
        pA   = nox_locateOrCreate(pObj : 'aValue');
        pA2  = nox_setStr(pA : '' : 'Value for a');

        pB   = nox_newObject();
        pB2  = nox_locateOrCreate(pB   : 'bValue');
        pB3  = nox_setStr(pB2: '' : 'Value for b');

        nox_MoveObjectInto(pObj : 'bObject' : pB);

        t =   nox_asJsonText(pObj);

        // done
        nox_close(pObj);

        //------------------------------------------------------------- *
        // Step 3:
        // Do the same as abowe but by
        // moving a value into the the root
        // note: it works like renaming the value inserting
        // it into the destinaiton object

        pObj = nox_newObject();
        nox_setStr(pObj : 'a' : 'Value for a');

        pB    = nox_newObject();
        pBval = nox_setStr(pB : 'bValue' : 'Value for b');

        nox_MoveObjectInto(pObj : 'newBvalue' : pBval);

        // Note : pB is now dangerling since it is a empty object
        // atfer the move it is allone in the world,
        // So we need to delete it by hand
        nox_close(pB);

        t =   nox_asJsonText(pObj);
        nox_close(pObj);

        //------------------------------------------------------------- *
        // Step 4:
        // Do the same as abowe but - the "moveInto" will
        // always replace the desitnation node is it exists
        // it will not try to merge the nodes ( rather look at the "merge" feature)
        // Note the memory location for the values ramain the same after the "move"
        pObj = nox_newObject();
        nox_setStr(pObj : 'a' : 'Value for a');

        pA    = nox_newObject();
        pAval = nox_setStr(pA : 'MyInitialName' : 'New value for a');

        // replae the "a" node
        nox_MoveObjectInto(pObj : 'a'  : pAval);

        // Note : pA is now dangerling since it is a empty object
        // atfer the move it is allone in the world,
        // We need to delete it by hand
        nox_close(pA);

        t =   nox_asJsonText(pObj);
        nox_close(pObj);
        *inlr = *on;
