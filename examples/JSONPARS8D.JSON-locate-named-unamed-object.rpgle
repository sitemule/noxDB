**free
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

// Parse Strings.
// Using the sqarebrackets [] notation to position 
// into the object graph

// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE');
/include qrpgleRef,noxdb

    example1();
    example2();
    example3();
    example4();
    *inlr = *on;

// ------------------------------------------------------------------------------------
// example1
// ------------------------------------------------------------------------------------
dcl-proc example1;

    Dcl-S pJson              Pointer;
    Dcl-S p                  Pointer;
    Dcl-S s                  VarChar(50);
    Dcl-S n                  VarChar(50);


    // First demo: find objects which contains objects where attibutes has a value
    pJson = json_ParseString ('-
        {-
            "e":{-
                "a": { "x":1 , "y":"11"},-
                "b": { "x":2 , "y":"22"},-
                "c": { "x":3 , "y":"33"} -
            }-
        }-
    ');

    If json_Error(pJson) ;
        json_joblog(json_Message(pJson));
        json_delete(pJson);
        Return;
    EndIf;

    // Get the object in the array where the "x" attribute has the value of 2
    p = json_locate  (pJson : '/e[x=2]');
    n = json_getName(p); // the is the "b" object
    s = json_getStr      (p : 'y' );
    json_joblog(s);

    json_delete(pJson);

end-proc;
// ------------------------------------------------------------------------------------
// example2
// ------------------------------------------------------------------------------------
dcl-proc example2;

    Dcl-S pJson              Pointer;
    Dcl-S p                  Pointer;
    Dcl-S s                  VarChar(50);
    Dcl-S n                  VarChar(50);

    // Next demo: find objects in array a where attibutes has a value
    pJson = json_ParseString ('-
        {-
            "a": [ -
                { "x":1 , "y":"11"}, -
                { "x":2 , "y":"22"}, -
                { "x":3 , "y":"33"}  -
            ]-
        }-
    ');

    If json_Error(pJson) ;
        json_joblog(json_Message(pJson));
        json_delete(pJson);
        Return;
    EndIf;

    // Get the object in the array a where the "x" attribute has the value of 2
    p = json_locate  (pJson : '/a[x=2]');
    n = json_getName (p); // This object has no name since it is an element of an array
    s = json_getStr  (p : 'y' );
    json_joblog(s);
    json_delete(pJson);
end-proc;

// ------------------------------------------------------------------------------------
// example3, only the array
// ------------------------------------------------------------------------------------
dcl-proc example3;

    Dcl-S pJson              Pointer;
    Dcl-S p                  Pointer;
    Dcl-S s                  VarChar(50);
    Dcl-S n                  VarChar(50);

    // Next demo: find attributes in arrays where attibutes has a value
    pJson = json_ParseString ('-
        [ -
            { "x":1 , "y":"11"}, -
            { "x":2 , "y":"22"}, -
            { "x":3 , "y":"33"}  -
        ]-
    ');

    If json_Error(pJson) ;
        json_joblog(json_Message(pJson));
        json_delete(pJson);
        Return;
    EndIf;

    // does the array contains any objects;
    if json_nodeType(json_getChild(pJson)) = JSON_OBJECT;
        json_joblog('First child node is an object');
    endif;


    // Get the object in the array where the "x" attribute has the value of 2
    p = json_locate  (pJson : '[x=2]');
    s = json_getStr      (p : 'y' );
    json_joblog(s);
    json_delete(pJson);
end-proc;

// ------------------------------------------------------------------------------------
// example4, XML
// ------------------------------------------------------------------------------------
dcl-proc example4;

    Dcl-S pXml               Pointer;
    Dcl-S p                  Pointer;
    Dcl-S s                  VarChar(50);
    Dcl-S n                  VarChar(50);

    // Next demo: find attributes in arrays where attibutes has a value
    pXml  = xml_ParseString ('-
        <root>-
            <row>-
                <id a="x">1</id>-
                <name>John</name>-
            </row>-
            <row>-
                <id a="y">2</id>-
                <name>Niels</name>-
            </row>-
        </root>-
    ');

    If xml_Error(pXml) ;
        xml_joblog(json_Message(pXml));
        xml_delete(pXml);
        Return;
    EndIf;


    // Get the element "row" having an element where id = 2
    p = xml_locate  (pXml : '/root/row[id=2]');
    s = xml_getStr  (p : 'name' );
    xml_joblog(s);

    // Get the element "row" having an element has an id element where atribute a is the value y
    p = xml_locate  (pXml : '/root/row[id@a=y]');
    s = xml_getStr  (p : 'name' );
    xml_joblog(s);


    xml_delete(pXml);
end-proc;

