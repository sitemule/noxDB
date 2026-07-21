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
        SrcLineNbrBin int(5); // bindec(2) ;   // Source line number as binary          
        LastFileStsBin int(5); // bindec(2) ;  // Source id matching positions 228-235  
        User char(10) ;             // Current user                          
        ExtErrCode int(10) ;        // External error code                   
        IntoElements int(20) ;      // Elements set by XML-INTO or DATA-INTO (7.3)     
        InternalJobId char(16) ;    // Internal job id (7.3 TR6)                       
            ijHi uns(20) overlay(InternalJobId:1);                      
            ijLo uns(20) overlay(InternalJobId:9);  //                     
        SysName char(8) ;           // System name (7.3 TR6)                           
    end-ds ;      


    example1();
    
    *INLR = *ON;

// ------------------------------------------------------------------------------------
// Generating JSON by PSDS
// ------------------------------------------------------------------------------------
dcl-proc example1;

                                                                       
    dcl-s pPSDS     pointer;
    dcl-s handle	char(1);


    // Now the magic: the pJson pointer is send to the mapper and returns as an object graph
    data-gen PgmStatus %data(handle: '') %gen(json_DataGen(pPSDS));
    
    // Let's see what we got
    json_WriteJsonStmf(pPSDS : '/prj/noxdb/testout/dump-pgm-status.json':1208:*OFF);

    // Always remember to delete used memory. 
    json_delete(pPSDS);

end-proc;
