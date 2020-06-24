       // ------------------------------------------------------------- *
       // noxDB - Not only XML. JSON, SQL and XML made easy for RPG

       // Company . . . : System & Method A/S - Sitemule
       // Design  . . . : Niels Liisberg

       // Unless required by applicable law or agreed to in writing, software
       // distributed under the License is distributed on an "AS IS" BASIS,
       // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

       // Look at the header source file "QRPGLEREF" member "NOXDB"
       // for a complete description of the functionality

       // When using noxDB you need two things:
       //  A: Bind you program with "NOXDB" Bind directory
       //  B: Include the noxDB prototypes from QRPGLEREF member NOXDB


       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pObj               Pointer;
       Dcl-S pA                 Pointer;
       Dcl-S pAval              Pointer;
       Dcl-S pA2                Pointer;
       Dcl-S pB                 Pointer;
       Dcl-S pB2                Pointer;
       Dcl-S pB3                Pointer;
       Dcl-S pBval              Pointer;

       Dcl-S t                  VarChar(512);
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
          json_delete(pObj);

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
          json_delete(pObj);


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
          json_delete(pB);

          t =   json_asJsonText(pObj);
          json_delete(pObj);

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
          json_delete(pA);

          t =   json_asJsonText(pObj);
          json_delete(pObj);
          *inlr = *on;
