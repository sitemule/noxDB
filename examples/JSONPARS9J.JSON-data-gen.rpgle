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
    example3();
    example4();
    
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
    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/dump-payload.json':1208:*OFF);
       

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
    json_WriteJsonStmf(pJson:'/prj/noxdb/testout/dump-payload2.json':1208:*OFF);

    // Always remember to delete used memory !!
    json_delete(pJson);

end-proc;
// ------------------------------------------------------------------------------------
// Generating JSON or XML by placing the datastructure in the objectgraph
// ------------------------------------------------------------------------------------
dcl-proc example3;


    // This is he data structure we map the object graph into:
    // The name "rows" is in the data-into statement
    // The "dim" causes it to be an array: 
    dcl-DS row  qualified inz;
        id   int(10);
        name varchar(256);
    end-ds;  

    dcl-s pArr	    pointer;
    dcl-s pRow      pointer;
    dcl-s i	        int(10);  
    dcl-s handle	char(1);

    pArr = json_newArray();

    // Make some data we can play with
    for i = 1 to 10 ;
        row.id = i;
        row.name = 'John ' + %char(i);

        // Now the magic: the pJson pointer is send to the mapper and returns as an object graph
        data-gen row %data(handle: '') %gen(json_DataGen(pRow));
        json_arrayPush (pArr : pRow);

    endfor;                                                           

    
    // Let's see what we got
    json_WriteJsonStmf(pArr:'/prj/noxdb/testout/dump-payload3.json':1208:*OFF);
       

    // Always remember to delete used memory. pArr "owns" all object generated 
    json_delete(pArr);

end-proc;
// ------------------------------------------------------------------------------------
// Generating JSON by PSDS
// ------------------------------------------------------------------------------------
dcl-proc example4;


    // This is he data structure we map the object graph into:
    // The name "rows" is in the data-into statement
    // The "dim" causes it to be an array: 
    dcl-ds PgmStatus psds qualified ;                                              
        Proc char(10) ;             // Module or main procedure name           
        StsCde zoned(5) ;           // Status code                             
        PrvStsCde zoned(5) ;        // Previous status                         
        SrcLineNbr char(8) ;        // Source line number                      
        Routine char(8) ;           // Name of the RPG routine                 
        Parms zoned(3) ;            // Number of parms passed to program       
        Exception char(7);                                                     
            ExceptionType char(3) overlay(Exception);     // Exception type      
            ExceptionNbr char(4)  overlay(Exception:4);    // Exception number   
        Reserved1 char(4) ;         // Reserved                                
        MsgWrkArea char(30) ;       // Message work area                       
        PgmLib char(10) ;           // Program library                         
        ExceptionData char(80) ;    // Retrieved exception data                
        Rnx9001Exception char(4) ;  // Id of exception that caused RNX9001     
        LastFile1 char(10) ;        // Last file operation occurred on         
        Unused1 char(6) ;           // Unused                                  
        DteEntered char(8) ;        // Date entered system                     
        StrDteCentury zoned(2) ;    // Century of job started date             
        LastFile2 char(8) ;         // Last file operation occurred on         
        LastFileSts char(35) ;      // Last file used status information     
        Job  char(26);                                                       
            JobName char(10) overlay(job:1);   // Job name                    
            JobUser char(10) overlay(job:11);  // Job user                    
            JobNbr zoned(6)  overlay(job:21);  // Job number                  
        StrDte zoned(6) ;           // Job started date                      
        PgmDte zoned(6) ;           // Date of program running               
        PgmTime zoned(6) ;          // Time of program running               
        CompileDte char(6) ;        // Date program was compiled             
        CompileTime char(6) ;       // Time program was compiled             
        CompilerLevel char(4) ;     // Level of compiler                     
        SrcFile char(10) ;          // Source file name                      
        SrcLib char(10) ;           // Source file library                   
        SrcMbr char(10) ;           // Source member name                    
        ProcPgm char(10) ;          // Program containing procedure          
        ProcMod char(10) ;          // Module containing procedure           
        SrcLineNbrBin bindec(2) ;   // Source line number as binary          
        LastFileStsBin bindec(2) ;  // Source id matching positions 228-235  
        User char(10) ;             // Current user                          
        ExtErrCode int(10) ;        // External error code                   
        IntoElements int(20) ;      // Elements set by XML-INTO or DATA-INTO (7.3)     
        InternalJobId char(16) ;    // Internal job id (7.3 TR6)                       
        SysName char(8) ;           // System name (7.3 TR6)                           
    end-ds ;      
                                                                       
    dcl-s pRow      pointer;
    dcl-s handle	char(1);


    // Now the magic: the pJson pointer is send to the mapper and returns as an object graph
    data-gen PgmStatus %data(handle: '') %gen(json_DataGen(pRow));

    
    // Let's see what we got
    json_WriteJsonStmf(pRow:'/prj/noxdb/testout/dump-payload4.json':1208:*OFF);
       

    // Always remember to delete used memory. pArr "owns" all object generated 
    json_delete(pRow);

end-proc;
