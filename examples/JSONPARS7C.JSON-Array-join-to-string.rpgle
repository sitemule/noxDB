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

       // Join an array and return is as string

       // ------------------------------------------------------------- *
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
      /include qrpgleRef,noxdb
       Dcl-S pJson              Pointer;
       Dcl-S msg                VarChar(50);

          *inlr = *on;

          pJson = json_ParseString ('                                -
            {                                                        -
               arr1: [                                               -
                  "The ",                                            -
                  "little ",                                         -
                  "brown fox"                                        -
               ]                                                     -
            }                                                        -
          ');

          // Glue all array elements together as one string
          msg = json_getStrJoin(pJson : 'arr1' );
          Dsply msg;

          json_delete(pJson);
