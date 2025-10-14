**free
Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' ) main(main);

/include 'headers/noxDb2.rpgle'

dcl-proc main;
   dcl-s xml pointer;
   dcl-s value varchar(200) ccsid(*utf8);
   dcl-s message char(50);

   xml = nox_parseString('<httpHeader includeErrorMsg="true"><header name="X-COUNT" value="111" />+
              </httpHeader>');

   value = nox_asXmlText(xml);
   message = value;
   dsply message;

   on-exit;
     nox_delete(xml);
end-proc;
