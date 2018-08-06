        //------------------------------------------------------------- *
        //This sample shows the use of the buildin JSONparser in
        //IceBreak

        //------------------------------------------------------------- *
        Ctl-Opt BndDir('JSONXML') dftactgrp(*NO) ACTGRP('QILE' );
      /include 'headers/JSONPARSER.rpgle'
        Dcl-S pJson1       Pointer;
        Dcl-S pJson2       Pointer;
        Dcl-S msg          Varchar(50);
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
              b : [                                             -
                  { d : 1 }                                     -
              ],                                                -
              x : {                                             -
                b : 2                                           -
              }                                                 -
           }                                                    -
        ');

        Json_merge (pJson1 : pJson2  : MO_MERGE_MATCH);

        Json_WriteStmf (pJson1:'/samples/json/jsonout-merge-6i.json':1208:*OFF);
        Json_Close(pJson1);
        Json_Close(pJson2);
