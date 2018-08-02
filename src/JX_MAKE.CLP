pgm

  dltSrvPgm  srvPgm(jsonxml/jsonxml)
  monmsg cpf0000

  crtSrvPgm  srvPgm(jsonxml/jsonxml)  +
     ACTGRP(QILE) +
     module(jxm*   RTVSYSVAL  UTL100   VARCHAR mem001  xlate) +
     alwLibUpd(*yes) tgtRls(V6R1M0)  SRCMBR(JSONXML)

endpgm
