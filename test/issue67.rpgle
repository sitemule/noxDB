**free
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE' );

/include 'headers/JSONPARSER.rpgle'

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
    *INLR = *ON;

// ------------------------------------------------------------------------------------
// test_MERGE_NEW_CLONE
// ------------------------------------------------------------------------------------
dcl-proc test_MERGE_NEW_CLONE;

    dcl-s Content varchar(1000);
    dcl-s Content2 varchar(1000);
    dcl-s MemStart int(20);
    dcl-s MemNow   int(20);
    dcl-s pFrom pointer;
    dcl-s pTo pointer;


    MemStart = json_memUse();

    pFrom = json_parseString ('{ -
        "a" : "a",   -
        "b" : {                   -
            "x"  : 100,            -
            "y"  : 200             -
        }                         -
    }');

    pTo = json_parseString ('{ -
        "b" : {                   -
            "i"  : 1,            -
            "j"  : 2             -
        },                         -
        "c" : "c"   -
    }');



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
    json_MergeObjects(pTo:pFrom:MO_MERGE_NEW);

    Content = json_AsJsonText(pFrom);
    Content2 = json_AsJsonText(pTo);

    assert ( 'a = "a"' : json_getstr(pFrom : 'a')   = 'a');
    assert ( 'b.x=100' : json_getint(pFrom : 'b.x') = 100);
    assert ( 'b.y=200' : json_getint(pFrom : 'b.y') = 200);

    assert ( 'a = "a"' : json_getstr(pTo : 'a')   = 'a');
    assert ( 'b.i=1'   : json_getint(pTo : 'b.i') = 1);
    assert ( 'b.j=2'   : json_getint(pTo : 'b.j') = 2);
    assert ( 'c = "c"' : json_getstr(pTo : 'c')   = 'c');

    json_delete(pTo);
    json_delete(pFrom);

    MemNow  = json_memUse();

    assert ( 'Mem leak' : MemNow = MemStart);


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


    MemStart = json_memUse();


    pFrom = json_parseString ('{ -
        "a" : "a",   -
        "b" : {                   -
            "x"  : 100,            -
            "y"  : 200             -
        }                         -
    }');

    pTo = json_parseString ('{ -
        "b" : {                   -
            "i"  : 1,            -
            "j"  : 2             -
        },                         -
        "c" : "c"   -
    }');

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
    json_MergeObjects(pTo:pFrom:MO_MERGE_MATCH);

    Content = json_AsJsonText(pFrom);
    Content2 = json_AsJsonText(pTo);

    assert ( 'a = "a"' : json_getstr(pFrom : 'a')   = 'a');
    assert ( 'b.x=100' : json_getint(pFrom : 'b.x') = 100);
    assert ( 'b.y=200' : json_getint(pFrom : 'b.y') = 200);

    assert ( 'a = NULL': json_has   (pTo: 'a') = *OFF);
    assert ( 'b.x=100' : json_getint(pTo : 'b.x') = 100);
    assert ( 'b.y=200' : json_getint(pTo : 'b.y') = 200);
    assert ( 'c = "c"' : json_getstr(pTo : 'c')   = 'c');


    json_delete(pTo);
    json_delete(pFrom);

    MemNow  = json_memUse();

    assert ( 'Mem leak' : MemNow = MemStart);


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


    MemStart = json_memUse();

    pFrom = json_parseString ('{ -
        "a" : "a",   -
        "b" : {                   -
            "x"  : 100,            -
            "y"  : 200             -
        }                         -
    }');

    pTo = json_parseString ('{ -
        "b" : {                   -
            "i"  : 1,            -
            "j"  : 2             -
        },                         -
        "c" : "c"   -
    }');

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
    json_MergeObjects(pTo:pFrom:MO_MERGE_REPLACE);

    Content = json_AsJsonText(pFrom);
    Content2 = json_AsJsonText(pTo);


    assert ( 'a = "a"' : json_getstr(pFrom : 'a')   = 'a');
    assert ( 'b.x=100' : json_getint(pFrom : 'b.x') = 100);
    assert ( 'b.y=200' : json_getint(pFrom : 'b.y') = 200);

    assert ( 'a = "a"' : json_getStr(pTo : 'a') = 'a');
    assert ( 'b.x=100' : json_getint(pTo : 'b.x') = 100);
    assert ( 'b.y=200' : json_getint(pTo : 'b.y') = 200);
    assert ( 'c = "c"' : json_getstr(pTo : 'c')   = 'c');

    json_delete(pTo);
    json_delete(pFrom);

    MemNow  = json_memUse();

    assert ( 'Mem leak' : MemNow = MemStart);


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


    MemStart = json_memUse();

    pFrom = json_parseString ('{ -
        "a" : "a",   -
        "b" : {                   -
            "x"  : 100,            -
            "y"  : 200             -
        }                         -
    }');

    pTo = json_parseString ('{ -
        "b" : {                   -
            "i"  : 1,            -
            "j"  : 2             -
        },                         -
        "c" : "c"   -
    }');


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
    json_MergeObjects(pTo:pFrom:MO_MERGE_NEW + MO_MERGE_MOVE);

    Content = json_AsJsonText(pFrom);
    Content2 = json_AsJsonText(pTo);

    assert ( 'a = NULL': json_has   (pFrom : 'a')   = *OFF);
    assert ( 'b.x=100' : json_getint(pFrom : 'b.x') = 100);
    assert ( 'b.y=200' : json_getint(pFrom : 'b.y') = 200);

    assert ( 'a = "a"' : json_getstr(pTo : 'a')   = 'a');
    assert ( 'b.i=1'   : json_getint(pTo : 'b.i') = 1);
    assert ( 'b.j=2'   : json_getint(pTo : 'b.j') = 2);
    assert ( 'c = "c"' : json_getstr(pTo : 'c')   = 'c');


    json_delete(pTo);
    json_delete(pFrom);

    MemNow  = json_memUse();

    assert ( 'Mem leak' : MemNow = MemStart);


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


    MemStart = json_memUse();


    pFrom = json_parseString ('{ -
        "a" : "a",   -
        "b" : {                   -
            "x"  : 100,            -
            "y"  : 200             -
        }                         -
    }');

    pTo = json_parseString ('{ -
        "b" : {                   -
            "i"  : 1,            -
            "j"  : 2             -
        },                         -
        "c" : "c"   -
    }');

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
    json_MergeObjects(pTo:pFrom:MO_MERGE_MATCH+ MO_MERGE_MOVE);

    Content = json_AsJsonText(pFrom);
    Content2 = json_AsJsonText(pTo);

    assert ( 'a = "a"' : json_getstr(pFrom : 'a')   = 'a');
    assert ( 'b = NULL': json_has   (pFrom : 'b')   = *OFF);

    assert ( 'a = NULL': json_has   (pTo: 'a') = *OFF);
    assert ( 'b.x=100' : json_getint(pTo : 'b.x') = 100);
    assert ( 'b.y=200' : json_getint(pTo : 'b.y') = 200);
    assert ( 'c = "c"' : json_getstr(pTo : 'c')   = 'c');



    json_delete(pTo);
    json_delete(pFrom);

    MemNow  = json_memUse();

    assert ( 'Mem leak' : MemNow = MemStart);


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


    MemStart = json_memUse();

    pFrom = json_parseString ('{ -
        "a" : "a",   -
        "b" : {                   -
            "x"  : 100,            -
            "y"  : 200             -
        }                         -
    }');

    pTo = json_parseString ('{ -
        "b" : {                   -
            "i"  : 1,            -
            "j"  : 2             -
        },                         -
        "c" : "c"   -
    }');

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
    json_MergeObjects(pTo:pFrom:MO_MERGE_REPLACE+ MO_MERGE_MOVE);

    Content = json_AsJsonText(pFrom);
    Content2 = json_AsJsonText(pTo);

    assert ( 'a = NULL': json_has   (pFrom : 'a')   = *OFF);
    assert ( 'b = NULL': json_has   (pFrom : 'b')   = *OFF);

    assert ( 'a = "a"' : json_getStr(pTo : 'a') = 'a');
    assert ( 'b.x=100' : json_getint(pTo : 'b.x') = 100);
    assert ( 'b.y=200' : json_getint(pTo : 'b.y') = 200);
    assert ( 'c = "c"' : json_getstr(pTo : 'c')   = 'c');

    json_delete(pTo);
    json_delete(pFrom);

    MemNow  = json_memUse();

    assert ( 'Mem leak' : MemNow = MemStart);


end-proc;
// ------------------------------------------------------------------------------------
// Inline unit test
// ------------------------------------------------------------------------------------
dcl-proc assert;

    dcl-pi *n;
        text varchar(256) value;
        ok   ind value;
    end-pi;

    if not ok;
        json_joblog( 'ASSERT FAILED: ' + text);
    endif;
end-proc;
