       // -------------------------------------------------------------
       // noxDB - Not only XML. JSON, SQL and XML made easy for RPG
       //
       // Company . . . : System & Method A/S - Sitemule
       // Design  . . . : Niels Liisberg
       //
       // Unless required by applicable law or agreed to in writing, software
       // distributed under the License is distributed on an "AS IS" BASIS,
       // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
       //
       // Look at the header source file "QRPGLEREF" member "NOXDB"
       // for a complete description of the functionality
       //
       //
       // -------------------------------------------------------------
       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );
       Dcl-S pXml               Pointer;
       Dcl-S pA                 Pointer;
       Dcl-S lCount             Int(10:0);
       Dcl-S kCount                 Int(10:0);
       Dcl-S countChildren          Int(10:0);
      /include xmlParser
          pXml  = xml_parseString('                  -
                <a>                                    -
                   <l>1</l>                            -
                   <l>2</l>                            -
                   <k>x</k>                            -
                   <l>3</l>                            -
                </a>                                   -
            ');

          // Count number of l and k tags
          lCount = xml_getNum(pXml : '/a/l[UBOUND]');
          kCount = xml_getNum(pXml : '/a/k[UBOUND]');

          // relative Count number of l and k tags
          pA = xml_locate(pXml : '/a');
          lCount = xml_getNum(pA   : 'l[UBOUND]');
          kCount = xml_getNum(pA   : 'k[UBOUND]');

          // relative Count number childrens of a
          pA = xml_locate(pXml : '/a');
          countChildren  =   xml_getNum(pA  : '[UBOUND]');

          xml_delete(pXml);
          *inlr = *on;
