
        Ctl-Opt BndDir('NOXDB');

        /include 'headers/JSONPARSER.rpgle'

        Dcl-S pJson        Pointer;
        Dcl-S price        Packed(15:2);
        Dcl-S text         Varchar(30);
        
        //------------------------------------------------------------- *

        Dcl-Pi JSON2;
        End-Pi;

        *inlr = *on;
        pJson = Json_ParseFile ('./test/documents/simple.json');

        if Json_Error(pJson) ;
           Json_dump(pJson);
           Json_Close(pJson);
           return;
        endif;

        price = Json_GetNum(pJson: '/price');
        text  = Json_GetStr(pJson: '/text');

        Dsply (%Char(price) + text);

        Json_Close(pJson);

        Return;