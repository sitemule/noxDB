       Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP(*NEW);            
      /COPY QRPGLEREF,JSONPARSER                                       
       Dcl-S pJson        Pointer;                                     
       Dcl-S refVal     Varchar(50);                                   
       Dcl-S pResult    Varchar(1024);                                 
       Dcl-S stringVar  Varchar(2000);                                 
                                                                       
       stringVar = '{   "$ref" : "#/components/schemas/OMCUSRSP"  }';  
       pJson = Json_ParseString(stringVar);                            
       if Json_Error(pJson) ;                                          
         pResult = Json_Message(pJson);                                
         Json_dump(pJson);                                             
         Json_Close(pJson);                                            
         *InLr = *On;                                                  
         Return;                                                       
       EndIf;                                                          
       refVal = Json_GetStr(pJson: '$ref');                            
       If refval = *blanks;                                            
         dsply '*Blanks';                                              
       else;                                                           
         dsply refVal;                                                 
       endif;                                                          
       *Inlr = *On;                                                    
