**FREE

ctl-opt dftactgrp(*no) actgrp(*new) bnddir('NOXDBUTF8');


/include 'headers/NOXDBUTF8.rpgle'


iterArray();
*inlr = *on;

// --------------------------------------------------------------------------------------
dcl-proc iterArray export;
  dcl-s json pointer;
  dcl-ds iterator likeds(nox_iterator);
  dcl-s value varchar(50);
  
  json = nox_parseString('[ "alpha", "beta", "gamma" ]');
  nox_WriteJsonStmf(json : '/prj/NOXDBUTF8/test/out/iter01.json' : 1208 : *OFF);    


  iterator = nox_setIterator(json);
  dow (nox_forEach(iterator));
    value = nox_getStr(iterator.this);
    dsply value;  
  enddo;

  on-exit;
    nox_delete(json);
end-proc;

// --------------------------------------------------------------------------------------
dcl-proc iterValues export;
  dcl-s json pointer;
  dcl-ds iterator likeds(nox_iterator);
  dcl-s value varchar(50);
  
  json = nox_parseString('{ "values" : [ "alpha", "beta", "gamma" ] }');
  nox_WriteJsonStmf(json : '/prj/NOXDBUTF8/test/out/iter02.json' : 1208 : *OFF);    


  iterator = nox_setIterator(json : 'values');
  dow (nox_forEach(iterator));
    value = nox_getValueStr(iterator.this);
    dsply value;  
  enddo;

  on-exit;
    nox_delete(json);
end-proc;

// --------------------------------------------------------------------------------------
dcl-proc iterKeys export;
  dcl-s json pointer;
  dcl-ds iterator likeds(nox_iterator);
  dcl-s value varchar(50);
  
  json = nox_parseString('{ "value1" : "alpha", "value2" : "beta", "value3" : "gamma" }');
  nox_WriteJsonStmf(json : '/prj/NOXDBUTF8/test/out/iter03.json' : 1208 : *OFF);    

  iterator = nox_setIterator(json);
  dow (nox_forEach(iterator));
    value = nox_getName(iterator.this);
    dsply value;  
    value = nox_getValueStr(iterator.this);
    dsply value;  
  enddo;

  on-exit;
    nox_delete(json);
end-proc;