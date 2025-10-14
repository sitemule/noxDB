**free
Ctl-Opt copyright('Sitemule - System & Method (C), 2025');
Ctl-Opt BndDir('NOXDBUTF8') CCSID(*CHAR:*UTF8);
Ctl-Opt dftactgrp(*NO) ACTGRP('QILE') option(*nodebugio:*srcstmt:*nounref) ALWNULL(*USRCTL);
Ctl-Opt main(main) ;

/include qrpgleref,noxDbUtf8

// ------------------------------------------------------------------------------------
dcl-proc main;

    nox_Assert ('Start issue067') ;

    // MergObjects uses there modifiers:
    // ---------------------------------
    // Only new elements are merged - existing are left untouched
    //    Dcl-C MO_MERGE_NEW const(256);
    // Merge and replace only existing nodes.
    //    Dcl-C MO_MERGE_MATCH const(512);
    // Merge all: replace if it exists and append new nodes if not exists
    //    Dcl-C MO_MERGE_REPLACE const(1024 );
    // Extra modifier to the above - Move from source into destination when this is added
    //    Dcl-C MO_MERGE_MOVE const(2048);

    // This is a deep copy, but shallow detection of "top" nodes
    test_MERGE_NEW_CLONE();
    test_MERGE_MATCH_CLONE();
    test_MERGE_REPLACE_CLONE();

    // This moves nodes from source to destination:
    test_MERGE_NEW_MOVE();
    test_MERGE_MATCH_MOVE();
    test_MERGE_REPLACE_MOVE();

    nox_Assert ('End issue067') ;

end-proc;
// ------------------------------------------------------------------------------------
// test_MERGE_NEW_CLONE
// ------------------------------------------------------------------------------------
dcl-proc test_MERGE_NEW_CLONE;

    dcl-s Content varchar(1000);
    dcl-s Content2 varchar(1000);
    dcl-s MemStart int(20);
    dcl-s MemNow   int(20);
    dcl-s pFrom    pointer;
    dcl-s pTo      pointer;


    MemStart = nox_memUse();

    pFrom = nox_Object (
        'a' : 'a' :
        'b' : nox_Object(
            'x':nox_int(100):
            'y':nox_int(200)
        )
    );

    pTo = nox_Object(
        'b' : nox_Object(
            'i' :nox_int(1):
            'j' :nox_int(2)
        ):
        'c' : 'c'
    );



    // MergObjects uses there modifiers:
    // ---------------------------------
    // Only new elements are merged - existing are left untouched
    //    Dcl-C MO_MERGE_NEW const(256);
    // Merge and replace only existing nodes.
    //    Dcl-C MO_MERGE_MATCH const(512);
    // Merge all: replace if it exists and append new nodes if not exists
    //    Dcl-C MO_MERGE_REPLACE const(1024 );
    // Extra modifier to the above - Move from source into destination when this is added
    //    Dcl-C MO_MERGE_MOVE const(2048);
    nox_MergeObjects(pTo:pFrom:MO_MERGE_NEW);

    Content = nox_AsJsonText(pFrom);
    Content2 = nox_AsJsonText(pTo);

    nox_Assert ( 'a = "a"' : nox_getstr(pFrom : 'a')   = 'a');
    nox_Assert ( 'b.x=100' : nox_getint(pFrom : 'b.x') = 100);
    nox_Assert ( 'b.y=200' : nox_getint(pFrom : 'b.y') = 200);

    nox_Assert ( 'a = "a"' : nox_getstr(pTo : 'a')   = 'a');
    nox_Assert ( 'b.i=1'   : nox_getint(pTo : 'b.i') = 1);
    nox_Assert ( 'b.j=2'   : nox_getint(pTo : 'b.j') = 2);
    nox_Assert ( 'c = "c"' : nox_getstr(pTo : 'c')   = 'c');

    nox_delete(pTo);
    nox_delete(pFrom);

    MemNow  = nox_memUse();

    nox_Assert ( 'Mem leak' : MemNow = MemStart);


end-proc;

// ------------------------------------------------------------------------------------
// test_MERGE_MATCH_CLONE
// ------------------------------------------------------------------------------------
dcl-proc test_MERGE_MATCH_CLONE;

    dcl-s Content varchar(1000);
    dcl-s Content2 varchar(1000);
    dcl-s MemStart int(20);
    dcl-s MemNow   int(20);
    dcl-s pFrom pointer;
    dcl-s pTo pointer;


    MemStart = nox_memUse();


    pFrom = nox_Object (
        'a' : 'a' :
        'b' : nox_Object(
            'x':nox_int(100):
            'y':nox_int(200)
        )
    );

    pTo = nox_Object(
        'b' : nox_Object(
            'i' :nox_int(1):
            'j' :nox_int(2)
        ):
        'c' : 'c'
    );

    // MergObjects uses there modifiers:
    // ---------------------------------
    // Only new elements are merged - existing are left untouched
    //    Dcl-C MO_MERGE_NEW const(256);
    // Merge and replace only existing nodes.
    //    Dcl-C MO_MERGE_MATCH const(512);
    // Merge all: replace if it exists and append new nodes if not exists
    //    Dcl-C MO_MERGE_REPLACE const(1024 );
    // Extra modifier to the above - Move from source into destination when this is added
    //    Dcl-C MO_MERGE_MOVE const(2048);
    nox_MergeObjects(pTo:pFrom:MO_MERGE_MATCH);

    Content = nox_AsJsonText(pFrom);
    Content2 = nox_AsJsonText(pTo);

    nox_Assert ( 'a = "a"' : nox_getstr(pFrom : 'a')   = 'a');
    nox_Assert ( 'b.x=100' : nox_getint(pFrom : 'b.x') = 100);
    nox_Assert ( 'b.y=200' : nox_getint(pFrom : 'b.y') = 200);

    nox_Assert ( 'a = NULL': nox_has   (pTo: 'a') = *OFF);
    nox_Assert ( 'b.x=100' : nox_getint(pTo : 'b.x') = 100);
    nox_Assert ( 'b.y=200' : nox_getint(pTo : 'b.y') = 200);
    nox_Assert ( 'c = "c"' : nox_getstr(pTo : 'c')   = 'c');


    nox_delete(pTo);
    nox_delete(pFrom);

    MemNow  = nox_memUse();

    nox_Assert ( 'Mem leak' : MemNow = MemStart);


end-proc;

// ------------------------------------------------------------------------------------
// test_MERGE_REPLACE_CLONE
// ------------------------------------------------------------------------------------
dcl-proc test_MERGE_REPLACE_CLONE;

    dcl-s Content varchar(1000);
    dcl-s Content2 varchar(1000);
    dcl-s MemStart int(20);
    dcl-s MemNow   int(20);
    dcl-s pFrom pointer;
    dcl-s pTo pointer;


    MemStart = nox_memUse();

    pFrom = nox_Object (
        'a' : 'a' :
        'b' : nox_Object(
            'x':nox_int(100):
            'y':nox_int(200)
        )
    );

    pTo = nox_Object(
        'b' : nox_Object(
            'i' :nox_int(1):
            'j' :nox_int(2)
        ):
        'c' : 'c'
    );

    // MergObjects uses there modifiers:
    // ---------------------------------
    // Only new elements are merged - existing are left untouched
    //    Dcl-C MO_MERGE_NEW const(256);
    // Merge and replace only existing nodes.
    //    Dcl-C MO_MERGE_MATCH const(512);
    // Merge all: replace if it exists and append new nodes if not exists
    //    Dcl-C MO_MERGE_REPLACE const(1024 );

    // Extra modifier to the above - Move from source into destination when this is added
    //    Dcl-C MO_MERGE_MOVE const(2048);
    nox_MergeObjects(pTo:pFrom:MO_MERGE_REPLACE);

    Content = nox_AsJsonText(pFrom);
    Content2 = nox_AsJsonText(pTo);


    nox_Assert ( 'a = "a"' : nox_getstr(pFrom : 'a')   = 'a');
    nox_Assert ( 'b.x=100' : nox_getint(pFrom : 'b.x') = 100);
    nox_Assert ( 'b.y=200' : nox_getint(pFrom : 'b.y') = 200);

    nox_Assert ( 'a = "a"' : nox_getStr(pTo : 'a') = 'a');
    nox_Assert ( 'b.x=100' : nox_getint(pTo : 'b.x') = 100);
    nox_Assert ( 'b.y=200' : nox_getint(pTo : 'b.y') = 200);
    nox_Assert ( 'c = "c"' : nox_getstr(pTo : 'c')   = 'c');

    nox_delete(pTo);
    nox_delete(pFrom);

    MemNow  = nox_memUse();

    nox_Assert ( 'Mem leak' : MemNow = MemStart);


end-proc;

// ----------- all the same but with MOVE modifier

// ------------------------------------------------------------------------------------
// test_MERGE_NEW_MOVE
// ------------------------------------------------------------------------------------
dcl-proc test_MERGE_NEW_MOVE;

    dcl-s Content varchar(1000);
    dcl-s Content2 varchar(1000);
    dcl-s MemStart int(20);
    dcl-s MemNow   int(20);
    dcl-s pFrom pointer;
    dcl-s pTo pointer;


    MemStart = nox_memUse();

    pFrom = nox_Object (
        'a' : 'a' :
        'b' : nox_Object(
            'x':nox_int(100):
            'y':nox_int(200)
        )
    );

    pTo = nox_Object(
        'b' : nox_Object(
            'i' :nox_int(1):
            'j' :nox_int(2)
        ):
        'c' : 'c'
    );


    // MergObjects uses there modifiers:
    // ---------------------------------
    // Only new elements are merged - existing are left untouched
    //    Dcl-C MO_MERGE_NEW const(256);
    // Merge and replace only existing nodes.
    //    Dcl-C MO_MERGE_MATCH const(512);
    // Merge all: replace if it exists and append new nodes if not exists
    //    Dcl-C MO_MERGE_REPLACE const(1024 );
    // Extra modifier to the above - Move from source into destination when this is added
    //    Dcl-C MO_MERGE_MOVE const(2048);
    nox_MergeObjects(pTo:pFrom:MO_MERGE_NEW + MO_MERGE_MOVE);

    Content = nox_AsJsonText(pFrom);
    Content2 = nox_AsJsonText(pTo);

    nox_Assert ( 'a = NULL': nox_has   (pFrom : 'a')   = *OFF);
    nox_Assert ( 'b.x=100' : nox_getint(pFrom : 'b.x') = 100);
    nox_Assert ( 'b.y=200' : nox_getint(pFrom : 'b.y') = 200);

    nox_Assert ( 'a = "a"' : nox_getstr(pTo : 'a')   = 'a');
    nox_Assert ( 'b.i=1'   : nox_getint(pTo : 'b.i') = 1);
    nox_Assert ( 'b.j=2'   : nox_getint(pTo : 'b.j') = 2);
    nox_Assert ( 'c = "c"' : nox_getstr(pTo : 'c')   = 'c');


    nox_delete(pTo);
    nox_delete(pFrom);

    MemNow  = nox_memUse();

    nox_Assert ( 'Mem leak' : MemNow = MemStart);


end-proc;

// ------------------------------------------------------------------------------------
// test_MERGE_MATCH_MOVE
// ------------------------------------------------------------------------------------
dcl-proc test_MERGE_MATCH_MOVE;

    dcl-s Content varchar(1000);
    dcl-s Content2 varchar(1000);
    dcl-s MemStart int(20);
    dcl-s MemNow   int(20);
    dcl-s pFrom pointer;
    dcl-s pTo pointer;


    MemStart = nox_memUse();

    pFrom = nox_Object (
        'a' : 'a' :
        'b' : nox_Object(
            'x':nox_int(100):
            'y':nox_int(200)
        )
    );

    pTo = nox_Object(
        'b' : nox_Object(
            'i' :nox_int(1):
            'j' :nox_int(2)
        ):
        'c' : 'c'
    );

    // MergObjects uses there modifiers:
    // ---------------------------------
    // Only new elements are merged - existing are left untouched
    //    Dcl-C MO_MERGE_NEW const(256);
    // Merge and replace only existing nodes.
    //    Dcl-C MO_MERGE_MATCH const(512);
    // Merge all: replace if it exists and append new nodes if not exists
    //    Dcl-C MO_MERGE_REPLACE const(1024 );
    // Extra modifier to the above - Move from source into destination when this is added
    //    Dcl-C MO_MERGE_MOVE const(2048);
    nox_MergeObjects(pTo:pFrom:MO_MERGE_MATCH+ MO_MERGE_MOVE);

    Content = nox_AsJsonText(pFrom);
    Content2 = nox_AsJsonText(pTo);

    nox_Assert ( 'a = "a"' : nox_getstr(pFrom : 'a')   = 'a');
    nox_Assert ( 'b = NULL': nox_has   (pFrom : 'b')   = *OFF);

    nox_Assert ( 'a = NULL': nox_has   (pTo: 'a') = *OFF);
    nox_Assert ( 'b.x=100' : nox_getint(pTo : 'b.x') = 100);
    nox_Assert ( 'b.y=200' : nox_getint(pTo : 'b.y') = 200);
    nox_Assert ( 'c = "c"' : nox_getstr(pTo : 'c')   = 'c');



    nox_delete(pTo);
    nox_delete(pFrom);

    MemNow  = nox_memUse();

    nox_Assert ( 'Mem leak' : MemNow = MemStart);


end-proc;

// ------------------------------------------------------------------------------------
// test_MERGE_REPLACE_MOVE
// ------------------------------------------------------------------------------------
dcl-proc test_MERGE_REPLACE_MOVE;

    dcl-s Content varchar(1000);
    dcl-s Content2 varchar(1000);
    dcl-s MemStart int(20);
    dcl-s MemNow   int(20);
    dcl-s pFrom pointer;
    dcl-s pTo pointer;


    MemStart = nox_memUse();

    pFrom = nox_Object (
        'a' : 'a' :
        'b' : nox_Object(
            'x':nox_int(100):
            'y':nox_int(200)
        )
    );

    pTo = nox_Object(
        'b' : nox_Object(
            'i' :nox_int(1):
            'j' :nox_int(2)
        ):
        'c' : 'c'
    );

    // MergObjects uses there modifiers:
    // ---------------------------------
    // Only new elements are merged - existing are left untouched
    //    Dcl-C MO_MERGE_NEW const(256);
    // Merge and replace only existing nodes.
    //    Dcl-C MO_MERGE_MATCH const(512);
    // Merge all: replace if it exists and append new nodes if not exists
    //    Dcl-C MO_MERGE_REPLACE const(1024 );

    // Extra modifier to the above - Move from source into destination when this is added
    //    Dcl-C MO_MERGE_MOVE const(2048);
    nox_MergeObjects(pTo:pFrom:MO_MERGE_REPLACE+ MO_MERGE_MOVE);

    Content = nox_AsJsonText(pFrom);
    Content2 = nox_AsJsonText(pTo);

    nox_Assert ( 'a = NULL': nox_has   (pFrom : 'a')   = *OFF);
    nox_Assert ( 'b = NULL': nox_has   (pFrom : 'b')   = *OFF);

    nox_Assert ( 'a = "a"' : nox_getStr(pTo : 'a') = 'a');
    nox_Assert ( 'b.x=100' : nox_getint(pTo : 'b.x') = 100);
    nox_Assert ( 'b.y=200' : nox_getint(pTo : 'b.y') = 200);
    nox_Assert ( 'c = "c"' : nox_getstr(pTo : 'c')   = 'c');

    nox_delete(pTo);
    nox_delete(pFrom);

    MemNow  = nox_memUse();

    nox_Assert ( 'Mem leak' : MemNow = MemStart);


end-proc;
