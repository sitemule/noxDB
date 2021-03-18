**FREE
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

// Using the "data-gen"

// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE') option(*nodebugio:*srcstmt:*nounref) ALWNULL(*USRCTL);
/include qrpgleRef,noxdb

    example1();
    example2();
    *INLR = *ON;

// ------------------------------------------------------------------------------------
// Generating JSON or XML by placing the datastructure in the objectgraph
// ------------------------------------------------------------------------------------
dcl-proc example1;


    // This is he data structure we map the object graph into:
    // The name "rows" is in the data-into statement
    // The "dim" causes it to be an array: 
    dcl-DS rows dim(2) qualified inz;
        id   int(10);
        name varchar(256);
    end-ds;  

    dcl-s pJson     pointer;
    dcl-s i	        int(10);  
    dcl-s handle	char(1);

    // Make some data we can play with
    for i = 1 to %elem(rows) ;
        rows(i).id = i;
        rows(i).name = 'John ' + %char(i);
    endfor;                                                           

    // Now the magic: the pJson pointer is send to the mapper and returns as an object graph
    data-gen rows %data(handle: '') %gen(json_DataGen(pJson));
    
    // Let's see what we got
    json_WriteJsonStmf(pJson:'/prj/noxdb/testdata/dump-payload.json':1208:*OFF);
       

    // Always remember to delete used memory !!
    json_delete(pJson);

end-proc;
// ------------------------------------------------------------------------------------
// Generating JSON or XML by placing the datastructure in the object graph
// Here we use all datatypes
// ------------------------------------------------------------------------------------
dcl-proc example2;


    dcl-s pJson     pointer;
    dcl-s i	        int(10);  
    dcl-s handle	char(1);

    // This is the data structure we map the object graph into:
    // Some types requires 7.4 or new TR's
    dcl-ds alltypes qualified inz;
        id          int(10);
        isClient    ind;
        name        varchar(256);
        ucs2name    ucs2(256);
        utf8name    varchar(256) ccsid(*utf8);
        //utf16name   varchar(256) ccsid(*UTF16); 
        myDate      date(*ISO);
        myTime      time(*ISO);
        myTimeStamp timestamp; 
        canbenull   varchar(100) nullind;
        //dynarr      char(1) dim(*AUTO:100);
        dcl-ds substructure;
            itemno      int(10);
            itemName    varchar(256);
            price       packed (13:2);
            margin      zoned(5:3);
            pi          float(8);
        end-ds;
    end-ds;  

    // Initialize with some fun:
    alltypes.id = 123;
    alltypes.isClient = *ON;
    alltypes.name = 'John';
    alltypes.ucs2name = u'4f605978'; // This will only work with noxDB2 since noxDB is in clean EBCDIC
    alltypes.utf8name = u'4f605978'; // This will only work with noxDB2 since noxDB is in clean EBCDIC
    //alltypes.utf16name = u'4f605978';
    alltypes.myDate    = %date();
    alltypes.myTime = %time();
    alltypes.myTimeStamp = %timestamp();
    //%nullind(alltypes.canbenull) = *ON;
    alltypes.substructure.itemno = 1234;
    alltypes.substructure.itemName = 'iPhone super XV';
    alltypes.substructure.price  = 12345.67;
    alltypes.substructure.margin = -22.5;
    alltypes.substructure.pi     = 22.0/7;

    //alltypes.dynarr(*next) = 'a';
    //alltypes.dynarr(*next) = 'b';
    //alltypes.dynarr(*next) = 'c';

    // Now the magic: the pJson pointer is send to the mapper and returns as an object graph
    data-gen alltypes %data(handle: '') %gen(json_DataGen(pJson));
    
    // Let's see what we got
    json_WriteJsonStmf(pJson:'/prj/noxdb/testdata/dump-payload2.json':1208:*OFF);

    // Always remember to delete used memory !!
    json_delete(pJson);

end-proc;
