**FREE
// ------------------------------------------------------------- *
// noxDB - Not only XML. JSON, SQL and XML made easy for RPG

// Company . . . : System & Method A/S - Sitemule
// Design  . . . : Niels Liisberg

// Building a stub and interface for a ILE service program

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

// Look at the header source file "QRPGLEREF" member "NOXDB"
// for a complete description of the functionality

// When using noxDB you need two things:
//  A: Bind you program with "NOXDB" Bind directory
//  B: Include the noxDB prototypes from QRPGLEREF member NOXDB

// ------------------------------------------------------------- *


// ------------------------------------------------------------- *
Ctl-Opt BndDir('NOXDB') dftactgrp(*NO) ACTGRP('QILE')  main(main);
/include qrpgleRef,noxdb

dcl-c nl     x'25';

dcl-proc main;

    dcl-s lib  char(10) 	inz('NOXDB');
    dcl-s pgm  char(10) 	inz('JSONPGM00C');
    dcl-s type char(10) 	inz('*SRVPGM');

    dcl-s fileName varchar(256);
    dcl-s pMeta   	pointer;

    fileName = '/prj/noxdb/testout/' + %trim(lib) + '-' + %trim(pgm) ;

    // pMeta = getTheMeta(lib:pgm:type:pcmlFile + '.pcml');
    pMeta = json_ParseFile ('/prj/customer/example.pcml');


    buildStub(pMeta : fileName + '.rpgle');

    // buildInterface(pcml);


// Always clean up
on-exit;
    json_delete(pMeta);

end-proc;
// ------------------------------------------------------------------------------------
// getTheMeta
// ------------------------------------------------------------------------------------
dcl-proc getTheMeta;

    dcl-pi *n pointer;
        lib      char(10) const;
        pgm      char(10) const;
        type     char(10) const;
        fileName varchar(256) const;
    end-pi;

    dcl-s pMeta      pointer;

    // Get meta info from a ILE program:
    // Note - this will be in PCML format a.k.a XML, but in the object graph
    pMeta = json_ProcedureMeta (lib : pgm : '*ALL');

    // Just dump the result to IFS stream file since it is XML by nature:
    json_WriteXMLStmf(pMeta:fileName:1208:*OFF);
    return pMeta;

end-proc;
// ------------------------------------------------------------------------------------
// buildStub
// ------------------------------------------------------------------------------------
dcl-proc buildStub;

    dcl-pi *n;
        pMeta    pointer value;
        outFile  varchar(256) const;
    end-pi;

    dcl-s source    varchar(600000:4);
    Dcl-DS elem      likeds(json_iterator);
    dcl-ds parms      likeds(json_iterator);
    dcl-ds struct    likeds(json_iterator);
    dcl-s name       varchar(50);
    dcl-s entrypt    varchar(50);
    dcl-s rtnval     varchar(50);

    makePrologue(pMeta : source);

    elem = json_setIterator(pMeta:'pcml');
    DoW json_ForEach(elem);
        if json_getName(elem.this) = 'struct' ;
            name = json_getStr(elem.this : '@name');
            struct = json_setIterator(elem.this); // "this" is the container for the parameters

            source += nl+ 'dcl-ds ' + name + ' qualified template;';
            DoW json_ForEach(struct);
                makeItem(struct.this : source);
            enddo;
            source += nl+ 'end-ds;'+nl;


        Elseif json_getName(elem.this) = 'program' ;
            name = json_getStr(elem.this : '@name');
            entrypt = json_getStr(elem.this : '@entrypoint');
            rtnval  = json_getStr(elem.this : '@returnvalue');

            source += nl+ 'dcl-proc ' + name + ' export;';
            source += nl+  '  dcl-pi *n ' + rtnval + ' extproc(*dclcase);';

            // Build parameter list
            parms = json_setIterator(elem.this); // "this" is the container for the parameters
            DoW json_ForEach(parms);
                makeItem(parms.this : source);
            enddo;
            source += nl+ '  end-pi;';

            // make a "clear" on all output parameters
            parms = json_setIterator(elem.this); // "this" is the container for the parameters
            DoW json_ForEach(parms);
                // "const" parameters can not be reset
                if json_getStr(parms.this : '@usage') <> 'input' ;
                    source += nl+  '  clear ' + json_getStr(parms.this : '@name') + ';';
                endif;
            enddo;

            source += nl+ 'end-proc;'+nl;
        EndIf;
    EndDo;

    // Dump the result to IFS stream file
    writeTextStmf(source:outFile);

end-proc;
// -------------------------------------------------------------------------------------
dcl-proc makeItem;
    dcl-pi *n;
        pItem     pointer value;
        source   varchar(600000:4) ;
    end-pi;

    source += nl+ '    ' + json_getStr(pItem : '@name');

    if json_getStr(pItem : '@type') = 'struct' ;
        source += ' likeds(' + json_getStr(pItem : '@struct') + ')';
    else;
        source += ' ' + json_getStr(pItem : '@type');
    EndIf;

    // Build length and precision - first edge cases:
    if json_getStr(pItem : '@type') = 'int' ;
        select;
            when json_getStr(pItem : '@length') = '8' ;
                source += '(20)';
            when json_getStr(pItem : '@length') = '4' ;
                source += '(10)';
            when json_getStr(pItem : '@length') = '2' ;
                source += '(5)';
            when json_getStr(pItem : '@length') = '1' ;
                source += '(3)';
        endsl;
    else ;
        // Normal length and precision
        if json_getStr(pItem : '@length') >'';
            source += '(' + json_getStr(pItem : '@length');
            if json_getStr(pItem : '@precision') >'' ;
                source += ':' + json_getStr(pItem : '@precision');
            EndIf;
            source += ')' ;
        EndIf;
    EndIf;

    // Array?
    if json_getStr(pItem : '@count') > '' ;
        source += ' dim(' + json_getStr(pItem : '@count') + ')';
    EndIf;

    if json_getStr(pItem : '@usage') = 'input' ;
        source += ' const';
    EndIf;
    source += ';';
end-proc;
// -------------------------------------------------------------------------------------
dcl-proc makePrologue;

    dcl-pi *n;
        pItem     pointer value;
        source   varchar(600000:4) ;
    end-pi;

    source = (
            '**free'+
        nl+ ''+
        nl+ '///'+
        nl+ '// This code is "stub" a generated on PCML interface'+
        nl+ '// to verify the noxDb meta export from i.e.'+
        nl+ '//    ctl-opt pgminfo(*PCML:*MODULE:*DCLCASE:*V8);'+
        nl+ '// Niels Liisberg 2025'+
        nl+ '///'+
        nl+
        nl+ 'ctl-opt pgminfo(*PCML:*MODULE:*DCLCASE:*V7);'+
        nl+ 'ctl-opt thread(*CONCURRENT);'+
        nl+ 'ctl-opt nomain;'+
        nl+ 'ctl-opt copyright(''Sitemule.com (C), 2023-' + %subst(%char(%timestamp()):1:4)+ ''');'+
        nl+ 'ctl-opt decEdit(''0,'') datEdit(*YMD.);'+
        nl+ 'ctl-opt debug(*yes);' +
        nl+
        nl
    ) ;

end-proc;
// -------------------------------------------------------------------------------------
// writeTextStmf
// ------------------------------------------------------------------------------------
dcl-proc writeTextStmf;

    dcl-pi *n;
        source varchar(600000:4) const;
        stmf   varchar(256) const;
    end-pi;

    dcl-pr fopen pointer extproc('_C_IFS_fopen') ;
     filename pointer value options(*string) ;
     mode    pointer value options(*string) ;
    end-pr ;

    dcl-pr fputs int(10) extproc('_C_IFS_fputs') ;
        string pointer value options(*string) ;
        pfile  pointer value ;
    end-pr ;

    dcl-pr fclose  int(10) extproc('_C_IFS_fclose') ;
        pfile  pointer value ;
    end-pr ;

    dcl-s f pointer;



    f = fopen(stmf:'w,ccsid=500');
    fputs(source:f);
    fclose(f);

end-proc;
