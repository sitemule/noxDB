      * ------------------------------------------------------------- *
      * This sample shows array handleing
      *
      *
      * ------------------------------------------------------------- *
     H BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' )
     D pObj            s               *
     D pA              s               *
     D pAval           s               *
     D pA2             s               *
     D pB              s               *
     D pB2             s               *
     D pB3             s               *
     D pBval           s               *

     D t               s            512a   varying
      /include JsonParser
      /free
        // ---------------------------------------
        // Step 1:
        // Create two objects, and move the conent of b into the root
        pObj = json_newObject();
        json_setStr(pObj : 'a' : 'Value for a');

        pB   = json_newObject();
        json_setStr(pB : 'bValue' : 'Value for b');

        json_MoveObjectInto(pObj : 'bObject': pB);

        t =   json_asJsonText(pObj);
        // done
        json_close(pObj);

        // ---------------------------------------
        // Step 2:
        // Do the same with lo-level functions
        pObj = json_newObject();
        pA   = json_locateOrCreate(pObj : 'aValue');
        pA2  = json_setStr(pA : '' : 'Value for a');

        pB   = json_newObject();
        pB2  = json_locateOrCreate(pB   : 'bValue');
        pB3  = json_setStr(pB2: '' : 'Value for b');

        json_MoveObjectInto(pObj : 'bObject' : pB);

        t =   json_asJsonText(pObj);

        // done
        json_close(pObj);


        // ---------------------------------------
        // Step 3:
        // Do the same as abowe but by
        // moving a value into the the root
        // note: it works like renaming the value inserting
        // it into the destinaiton object
        pObj = json_newObject();
        json_setStr(pObj : 'a' : 'Value for a');

        pB    = json_newObject();
        pBval = json_setStr(pB : 'bValue' : 'Value for b');

        json_MoveObjectInto(pObj : 'newBvalue' : pBval);

        // Note : pB is now dangerling since it is a empty object
        // atfer the move it is allone in the world,
        // So we need to delete it by hand
        json_close(pB);

        t =   json_asJsonText(pObj);
        json_close(pObj);

        // ---------------------------------------
        // Step 4:
        // Do the same as abowe but - the "moveInto" will
        // always replace the desitnation node is it exists
        // it will not try to merge the nodes ( rather look at the "merge" feature)
        // Note the memory location for the values ramain the same after the "move"
        pObj = json_newObject();
        json_setStr(pObj : 'a' : 'Value for a');

        pA    = json_newObject();
        pAval = json_setStr(pA : 'MyInitialName' : 'New value for a');

        // replae the "a" node
        json_MoveObjectInto(pObj : 'a'  : pAval);

        // Note : pA is now dangerling since it is a empty object
        // atfer the move it is allone in the world,
        // We need to delete it by hand
        json_close(pA);

        t =   json_asJsonText(pObj);
        json_close(pObj);
        *inlr = *on;
