**free
// -------------------------------------------------------------
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

// Build a json object with primitive types and write
// is as astream file to the IFS in UTF-8 format

// Note: In the SQL folder you will find a SQL script: stock.sql
// that creates the tables used in this example.

// -------------------------------------------------------------
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') main(main);
/include qrpgleRef,noxdb

dcl-proc main;

    // Always set your ccsid for constants, if different from job ccsid:
    // examples code in the repo uses CCSID 500, which is the EBCDIC CCSID for international characters
    json_setDelimitersByCcsid(500);

    example1();
    example2();
    json_sqlDisconnect();


end-proc;
// -------------------------------------------------------------
// This example shows how to build a JSON object from scratch
// It uses the json_parseString to parse a JSON string
// Later we will construct the same JSON by using the SQL resultset
// and the iterator to build the JSON object.
// --------------------------------------------------------------
dcl-proc example1;

    Dcl-S pJson              Pointer;

    pJson = json_parseString( '-
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
    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/stock1.json':1208:*OFF);

on-exit;
   json_delete(pJson);
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
    Dcl-S  pSizes          Pointer;
    Dcl-s  pSubSizes Pointer;
    Dcl-S  pColurs         Pointer;
    Dcl-S  pCategory       Pointer;
    dcl-ds stockList       likeds(json_iterator);


    pStock = json_sqlResultset (
      'select -
          sku,-
          department ,-
          main_category,-
          sub_category -
        from noxdb.stock '
    );

    // Test errors:
    If json_Error(pStock) ;
        json_joblog(json_Message(pStock));
        Return;
    EndIf;

    stockList = json_setIterator(pStock);
    DoW json_ForEach(stockList);

        // Need to rename Db2 names for final result:
        json_nodeRename ( json_locate(stockList.this : 'department'): 'Department');
        json_nodeRename ( json_locate(stockList.this : 'sku')       : 'SKU');

        // We need to create a new object for the category
        // and move and rename the main_category and sub_category into it
        json_setStr (stockList.this: 'Category.MainCategory' :
            json_getStr(stockList.this: 'main_category'));
        json_setStr (stockList.this: 'Category.Sub-Category' :
            json_getStr(stockList.this: 'sub_category'));

        // Now we can delete the original main_category and sub_category
        json_nodeDelete (json_locate(stockList.this: 'main_category'));
        json_nodeDelete (json_locate(stockList.this: 'sub_category'));

        // For each stock item, we will add the sizes and colours
        // We use the main_category to find the sizes and colours
        pSizes = convertObjectToValues(
            json_sqlResultset (
                'select number from noxdb.sizes -
                 where main_category = ' + quote(
                    json_getStr(stockList.this:'main_category')
                ) +
                ' and number is not null' // only first level  stock
            )
        );

        pSubSizes = convertObjectToValues(
           json_sqlResultset (
               'select text from noxdb.sizes -
                where main_category = ' + quote(
                    json_getStr(stockList.this:'main_category')
                ) +
                ' and text is not null' // only nextlevel  stock
            )
        );

        // If we have sub sizes, we will add them to the sizes array
        if json_getLength(pSubSizes) > 0;
            json_ArrayPush (pSizes : pSubSizes);
        endif;

        // If we have sizes, we will add them to the stock item
        if json_getLength(pSizes) > 0;
            json_MoveObjectInto (stockList.this : 'Sizes' : pSizes);
        endif;

        pColurs = convertObjectToValues(
            json_sqlResultset (
                'select colur_name from noxdb.Colurs -
                 where main_category = ' + quote(
                    json_getStr(stockList.this:'main_category')
                )
            )
        );
        // If we have colours, we will add them to the stock item
        if json_getLength(pColurs) > 0;
            json_MoveObjectInto (stockList.this : 'Colurs' : (pColurs));
        endif;
    EndDo;

    // Now we have a complete stock object with sizes and colours
    // We can write it to a stream file in the IFS
    // BUT - we need it in a final object called stock:
    pJson = json_newObject();
    json_MoveObjectInto (pJson : 'Stock' : pStock);


    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/stock2.json':1208:*OFF);

// Since everythin is contained in the pJson object
// we can delete only the final result
on-exit;
    json_delete(pJson);
end-proc;
// -------------------------------------------------------------
// quote helper function to ensure sql injection is not possible
// This function will add quotes around the string and escape any quotes inside the string
// --------------------------------------------------------------
dcl-proc quote;
    dcl-pi *n varchar(256);
        str varchar(256) const options(*varsize);
    end-pi;
    dcl-c  q '''';

    return q + %scanrpl (q:q+q:str) + q;

end-proc;
// -------------------------------------------------------------
// convertObjectToValues helper function to return
// array values from a list of objects, picking first element value
// Note: The original input object liste is destryoyed after use
// --------------------------------------------------------------
dcl-proc convertObjectToValues;
    dcl-pi *n pointer;
        pObjList pointer value;
    end-pi;
    dcl-ds list likeds(json_iterator);
    dcl-s pArray pointer;
    pArray = json_newArray(); // Create a new array object

    // For each object in the list, we will add it to the array
    list = json_setIterator(pObjList);
    DoW json_ForEach(list);
        json_ArrayPush(pArray : json_getChild(list.this));
    enddo;
    json_delete(pObjList);

    // Return the array object
    return pArray;
end-proc;
