**free
// ------------------------------------------------------------------------------------
// noxDB - Not Only Xml - Its JSON, XML, SQL and more
//
// This tutorial will show all SQL function of the noxDbUtf8 library
//
// Design:  Niels Liisberg
// Project: Sitemule.com
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// Look at the header source file "QRPGLEREF" member "NOXDBUTF8"
// for a complete description of the functionality
//
// When using noxDbUtf8 you need two things:
//  A: Bind you program with "NOXDBUTF8" Bind directory
//  B: Include the noxDbUtf8 prototypes from QRPGLEREF member NOXDBUTF8
//
// Important: You need to set the CCSID of the source to the CCSID of the
//            target ccsid of the running job.
//            otherwise special chars will be strange for constants.
//            This project is by default set to CCSID 500
//            do a CHGJOBCCSID(500) before running these examples.
//            This only applies to program constants !!
//
// Note:      This program is/can be build with UTF-8, so all CHAR/VARCHAR are in UTF-8
//            This is not an requirement - you can use any CCSID you like
//
// Note: In the SQL folder you will find a SQL script: stock.sql
// that creates the tables used in this example.
//
//
// try/build:
// cd '/prj/NOXDBUTF8'
// addlible NOXDBUTF8
// chgjobccsid(500)
// call
// ------------------------------------------------------------------------------------
Ctl-Opt copyright('Sitemule - System & Method (C), 2025');
Ctl-Opt BndDir('NOXDBUTF8') CCSID(*CHAR:*UTF8);
Ctl-Opt dftactgrp(*NO) ACTGRP('QILE') option(*nodebugio:*srcstmt:*nounref) ALWNULL(*USRCTL);
Ctl-Opt main(main) ;

/include qrpgleref,noxDbUtf8

// Global connection pointer
dcl-s pCon         pointer;


// ------------------------------------------------------------------------------------
dcl-proc main;

    dcl-s memuse       int(20);

    // Take a snapshot of the memory usage before we start
    memuse = nox_memUse();

    // Connect to the database - using the noxDbUtf8 driver. This is global for all examples
    pCon = nox_sqlConnect();

    example1a();
    example1b();
    example2();
    example3();
    example4();

on-exit;
    // Always remember to delete used memory !!
    nox_sqlDisconnect(pCon);
    if memuse <> nox_memuse();
        nox_joblog('Ups - forgot to clean something up');
    endif;

end-proc;
// -------------------------------------------------------------
// This example shows how to build a JSON object from scratch
// It uses the nox_parseString to parse a JSON string
// Later we will construct the same JSON by using the SQL resultset
// and the iterator to build the JSON object.
// --------------------------------------------------------------
dcl-proc example1a;

    Dcl-S pJson              Pointer;

    pJson = nox_parseString( '-
    {-
        "Stock": [-
            {-
                "SKU": "Cycles",-
                "Department": "Cycles",-
                "Category": {-
                    "MainCategory": "Bikes",-
                    "Sub-Category": "racing"-
                },-
                "Sizes": [51,55, ["S", "L", "XL"],58,60]-
            },-
            {-
                "Department": "Mountain",-
                "Category": {-
                    "MainCategory": "E-bikes",-
                    "Sub-Category": "MTB"-
                },-
                "Sizes": [51,55,58,60],-
                "Colours": ["White",-
                            "Black",-
                            "Green",-
                            "Red",-
                            "Blue" -
                ]-
            }-
        ]-
    }');
    // Dump it as an IFS file
    nox_WriteJsonStmf(pJson:'/prj/noxdbutf8/testout/stock1a.json':1208:*OFF);

on-exit;
   nox_delete(pJson);
end-proc;

// -------------------------------------------------------------
// Same as example1a - but we use the object builder functions
// nox_Object and nox_Array
// --------------------------------------------------------------
dcl-proc example1b;

    Dcl-S pJson              Pointer;

    pJson = nox_Object(
        'Stock' : nox_Array(
            nox_Object(
                'SKU'        : 'Cycles' :
                'Department' : 'Cycles' :
                'Category'   : nox_Object(
                    'MainCategory' : 'Bikes'  :
                    'Sub-Category' : 'racing'
                ) :
                'Sizes'      : nox_Array(
                    nox_int(51):
                    nox_int(55):
                    nox_Array('S':'L':'XL'):
                    nox_int(58):
                    nox_int(60)
                )
            ):
            nox_Object(
                'Department' : 'Mountain' :
                'Category'   : nox_Object(
                    'MainCategory' : 'E-bikes' :
                    'Sub-Category' : 'MTB'
                ) :
                'Sizes'      : nox_Array(
                    nox_int(51):
                    nox_int(55):
                    nox_int(58):
                    nox_int(60)
                ) :
                'Colours'    : nox_Array(
                    'White':
                    'Black':
                    'Green':
                    'Red':
                    'Blue'
                )
            )
        )
    );
    // Dump it as an IFS file
    nox_WriteJsonStmf(pJson:'/prj/noxdbutf8/testout/stock1b.json':1208:*OFF);

on-exit;
   nox_delete(pJson);
end-proc;

// -------------------------------------------------------------
// This example is similar to example1, but it uses a different
// way to build the JSON object.
// It uses the SQL resultset to build the JSON object.
// by appending substructures by nested logic;
// -------------------------------------------------------------
dcl-proc example2;

    Dcl-S  pJson           Pointer;
    Dcl-S  pStock          Pointer;
    Dcl-S  pNumberSizes    Pointer;
    Dcl-s  pTextSizes      Pointer;
    Dcl-S  pColurs         Pointer;
    dcl-ds stockList       likeds(nox_iterator);


    pStock = nox_sqlResultset (pCon:
      'select -
          sku,-
          department ,-
          main_category,-
          sub_category -
        from noxdbdemo.stock '
    );

    // Test errors:
    If nox_Error(pStock) ;
        nox_joblog(nox_Message(pStock));
        Return;
    EndIf;

    stockList = nox_setIterator(pStock);
    DoW nox_ForEach(stockList);

        // Need to rename Db2 names for final result:
        nox_Rename ( nox_Locate(stockList.this : 'department'): 'Department');
        nox_Rename ( nox_Locate(stockList.this : 'sku')       : 'SKU');

        // We need to create a new object for the category
        // and move and rename the main_category and sub_category into it
        nox_setStr (stockList.this: 'Category.MainCategory' :
            nox_getStr(stockList.this: 'main_category'));
        nox_setStr (stockList.this: 'Category.Sub-Category' :
            nox_getStr(stockList.this: 'sub_category'));

        // Now we can delete the original main_category and sub_category
        nox_Delete (nox_Locate(stockList.this: 'main_category'));
        nox_Delete (nox_Locate(stockList.this: 'sub_category'));

        // For each stock item, we will add the sizes and colours
        // We use the main_category to find the sizes and colours
        pNumberSizes= nox_ArrayConvertList(
            nox_sqlResultset (pCon:
                'select number -
                 from noxdbdemo.sizes -
                 where main_category = ${Category.MainCategory} -
                 and number is not null': // only first level  stock
                stockList.this
            )
        );

        pTextSizes = nox_ArrayConvertList(
           nox_sqlResultset ( pCon:
               'select text -
                from noxdbdemo.sizes -
                where main_category = ${Category.MainCategory} -
                and number is not null': // only first level  stock
                stockList.this
            )
        );

        // If we have sub sizes, we will add them to the sizes array
        if nox_getLength(pTextSizes) > 0;
            nox_ArrayPush (pNumberSizes: pTextSizes);
        endif;

        // If we have sizes, we will add them to the stock item
        if nox_getLength(pNumberSizes) > 0;
            nox_MoveObjectInto (stockList.this : 'Sizes' : pNumberSizes);
        endif;

        pColurs = nox_ArrayConvertList(
            nox_sqlResultset (pCon:
                'select colur_name -
                 from noxdb.Colurs -
                 where main_category = ${Category.MainCategory}':
                 stockList.this
            )
        );
        // If we have colours, we will add them to the stock item
        if nox_getLength(pColurs) > 0;
            nox_MoveObjectInto (stockList.this : 'Colurs' : (pColurs));
        endif;
    EndDo;

    // Now we have a complete stock object with sizes and colours
    // We can write it to a stream file in the IFS
    // BUT - we need it in a final object called stock:
    pJson = nox_newObject();
    nox_MoveObjectInto (pJson : 'Stock' : pStock);


    nox_WriteJsonStmf(pJson:'/prj/noxdbutf8/testout/stock2.json':1208:*OFF);

// Since everything is contained in the pJson object
// we can delete only the final result
on-exit;
    nox_delete(pJson);
end-proc;
// -------------------------------------------------------------
// This example is similar to example2, but it uses a yet
// simpler aproach by manipulating the graph
// It uses the SQL resultset to build the JSON object.
// by appending substructures by nested logic;
// Note: This example uses noxDb >= '2026-07-01'
// -------------------------------------------------------------
dcl-proc example3;

    Dcl-S  pJson           Pointer;
    Dcl-S  pStock          Pointer;
    Dcl-S  pNumberSizes    Pointer;
    Dcl-s  pTextSizes      Pointer;
    Dcl-S  pColurs         Pointer;
    Dcl-S  pSize55         Pointer;
    dcl-ds stockList       likeds(nox_iterator);


    pStock = nox_sqlResultset (pCon:
      'select -
          sku,-
          department ,-
          main_category,-
          sub_category -
        from noxdbdemo.stock '
    );

    // Test errors:
    If nox_Error(pStock) ;
        nox_joblog(nox_Message(pStock));
        Return;
    EndIf;

    stockList = nox_setIterator(pStock);
    DoW nox_ForEach(stockList);

        // Need to rename Db2 names for final result:
        nox_Rename ( nox_Locate(stockList.this : 'department'): 'Department');
        nox_Rename ( nox_Locate(stockList.this : 'sku')       : 'SKU');

        // Here we directly rearange the nodes by moving them around
        nox_moveValue (stockList.this: 'Category.MainCategory' :stockList.this: 'main_category');
        nox_moveValue (stockList.this: 'Category.Sub-Category' :stockList.this: 'sub_category');


        // For each stock item, we will add the sizes and colours
        // We use the main_category to find the sizes and colours
        // Here we uses the built-in function to conver the SQL resultset
        // Note - now we have rearanged the nodes, so we can pick
        // key values for the SQL directly from  the stoc row:
        pNumberSizes= nox_ArrayConvertList (
            nox_sqlResultset (pCon:
                'select number -
                 from noxdbdemo.sizes -
                 where main_category = ${Category.MainCategory} -
                 and number is not null':     // Sizer with numbers first
                stockList.this                // from where to pick the key-values
            )
        );

        pTextSizes = nox_ArrayConvertList(
           nox_sqlResultset (pCon:
               'select text -
                from noxdbdemo.sizes -
                where main_category = ${Category.MainCategory} -
                and text is not null':        // Sizer with text next
                stockList.this                // from where to pick the key-values
            )
        );

        // just a demo: if we have size=55 the text size will be inserted after it
        // so we can have a mixed array of numbers and text
        // If we have sizes, we will add them to the stock item
        pSize55  = nox_lookupValue(pNumberSizes :  '55' : NOX_IGNORE_CASE);
        if pSize55 <> *null and nox_getLength(pTextSizes) > 0;
            // If we have a size 55, we will add the text sizes after it
            // This is just a demo to show how to manipulate the graph
            nox_nodeInsert (pSize55 : pTextSizes: NOX_AFTER_SIBLING);
        else;

            // If we have sub sizes, we will add them to the sizes array
            if nox_getLength(pTextSizes) > 0;
                nox_ArrayPush (pNumberSizes: pTextSizes);
            endif;
        endif;

        // If we have sizes, we will add them to the stock item
        if nox_getLength(pNumberSizes) > 0;
            nox_MoveObjectInto (stockList.this : 'Sizes' : pNumberSizes);
        endif;

        // In this version we always produce the colour array - even if it has no elements
        nox_MoveObjectInto (stockList.this : 'Colurs' :
            nox_ArrayConvertList(
                nox_sqlResultset (pCon:
                    'select colur_name -
                     from noxdb.Colurs -
                     where main_category = ${Category.MainCategory} ':
                    stockList.this                // from where to pick the key-values
                )
            )
        );
    EndDo;

    // Now we have a complete stock object with sizes and colours
    // We can write it to a stream file in the IFS
    // BUT - we need it in a final object called stock:
    pJson = nox_newObject();
    nox_MoveObjectInto (pJson : 'Stock' : pStock);


    nox_WriteJsonStmf(pJson:'/prj/noxdbutf8/testout/stock3.json':1208:*OFF);

// Since everything is contained in the pJson object
// we can delete only the final result
on-exit;
    nox_delete(pJson);
end-proc;

// -------------------------------------------------------------
// This example is similar to example3, but it uses a yet
// simpler aproach by manipulating the graph and object builder
// It uses the SQL resultset to build the JSON object.
// by appending substructures by nested logic;
// Note: This example uses noxDb >= '2026-07-01'
// -------------------------------------------------------------
dcl-proc example4;

    Dcl-S  pJson           Pointer;
    Dcl-S  pStock          Pointer;
    Dcl-S  pNumberSizes    Pointer;
    Dcl-s  pTextSizes      Pointer;
    Dcl-S  pColurs         Pointer;
    Dcl-S  pSize55         Pointer;
    dcl-ds stockList       likeds(nox_iterator);


    pStock = nox_sqlResultset (pCon:
      'select -
          sku,-
          department ,-
          main_category,-
          sub_category -
        from noxdbdemo.stock '
    );

    // Test errors:
    If nox_Error(pStock) ;
        nox_joblog(nox_Message(pStock));
        Return;
    EndIf;

    stockList = nox_setIterator(pStock);
    DoW nox_ForEach(stockList);

        // Need to rename Db2 names for final result:
        nox_Rename ( nox_Locate(stockList.this : 'department'): 'Department');
        nox_Rename ( nox_Locate(stockList.this : 'sku')       : 'SKU');

        // Here we directly rearange the nodes using the object builder
        // nox_Object "owns" it's children - they are moved into the graph
        nox_MoveObjectInto (stockList.this :
            'Category' : nox_Object(
                'MainCategory' : nox_Locate (stockList.this: 'main_category'):
                'Sub-Category' : nox_Locate (stockList.this: 'sub_category' )
            )
        );


        // For each stock item, we will add the sizes and colours
        // We use the main_category to find the sizes and colours
        // Here we uses the built-in function to conver the SQL resultset
        // Note - now we have rearanged the nodes, so we can pick
        // key values for the SQL directly from  the stoc row:
        pNumberSizes= nox_ArrayConvertList (
            nox_sqlResultset (pCon:
                'select number -
                 from noxdbdemo.sizes -
                 where main_category = ${Category.MainCategory} -
                 and number is not null':     // Sizer with numbers first
                stockList.this                // from where to pick the key-values
            )
        );

        pTextSizes = nox_ArrayConvertList(
           nox_sqlResultset (pCon:
               'select text -
                from noxdbdemo.sizes -
                where main_category = ${Category.MainCategory} -
                and text is not null':        // Sizer with text next
                stockList.this                // from where to pick the key-values
            )
        );

        // just a demo: if we have size=55 the text size will be inserted after it
        // so we can have a mixed array of numbers and text
        // If we have sizes, we will add them to the stock item
        pSize55  = nox_lookupValue(pNumberSizes :  '55' : NOX_IGNORE_CASE);
        if pSize55 <> *null and nox_getLength(pTextSizes) > 0;
            // If we have a size 55, we will add the text sizes after it
            // This is just a demo to show how to manipulate the graph
            nox_nodeInsert (pSize55 : pTextSizes: NOX_AFTER_SIBLING);
        else;

            // If we have sub sizes, we will add them to the sizes array
            if nox_getLength(pTextSizes) > 0;
                nox_ArrayPush (pNumberSizes: pTextSizes);
            endif;
        endif;

        // If we have sizes, we will add them to the stock item
        if nox_getLength(pNumberSizes) > 0;
            nox_MoveObjectInto (stockList.this : 'Sizes' : pNumberSizes);
        endif;

        // In this version we always produce the colour array - even if it has no elements
        nox_MoveObjectInto (stockList.this : 'Colurs' :
            nox_ArrayConvertList(
                nox_sqlResultset (pCon:
                    'select colur_name -
                     from noxdb.Colurs -
                     where main_category = ${Category.MainCategory} ':
                    stockList.this                // from where to pick the key-values
                )
            )
        );
    EndDo;

    // Now we have a complete stock object with sizes and colours
    // We can write it to a stream file in the IFS
    // BUT - we need it in a final object called stock:
    pJson = nox_Object(
        'Stock' : pStock
    );


    nox_WriteJsonStmf(pJson:'/prj/noxdbutf8/testout/stock4.json':1208:*OFF);

// Since everything is contained in the pJson object
// we can delete only the final result
on-exit;
    nox_delete(pJson);
end-proc;
