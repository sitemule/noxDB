      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      *
      * ------------------------------------------------------------- *
     H BndDir('JSONPARSER') dftactgrp(*NO) ACTGRP('QILE' )
      /include JsonParser
     D pJson1          s               *
     D pJson2          s               *
     D msg             s             50    varying
      /free
        *inlr = *on;

        pJson1 = Json_ParseString ('                            -
           {                                                    -
              a : [                                             -
                  { b : 1 }                                     -
              ],                                                -
              x : {                                             -
                a : 1                                           -
              }                                                 -
           }                                                    -
        ');

        pJson2 = Json_ParseString ('                            -
           {                                                    -
              c : [                                             -
                  { d : 1 }                                     -
              ],                                                -
              x : {                                             -
                b : 2                                           -
              }                                                 -
           }                                                    -
        ');

        Json_merge (pJson1 : pJson2  : Json_DONTREPLACE);

        Json_WriteStmf (pJson1:'/samples/json/jsonout-merge-6i.json':1208:*OFF);
        Json_Close(pJson1);
        Json_Close(pJson2);
