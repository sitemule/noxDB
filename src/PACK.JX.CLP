pgm parm(&toLib)

  dcl &toLib    *char 10
  dcl &fromLib  *char 10 value(JSONXML)

  /* Tolib need to be empty or no name confickts at least */
  CRTDUPOBJ  OBJ(jsonxml)   FROMLIB(&FROMLIB) OBJTYPE(*SRVPGM) TOLIB(&tolib)
  CRTDUPOBJ  OBJ(QRPGLESRC) FROMLIB(&FROMLIB) OBJTYPE(*FILE)   TOLIB(&tolib) DATA(*YES)
  CRTDUPOBJ  OBJ(Qjxsample) FROMLIB(&FROMLIB) OBJTYPE(*file)   TOLIB(&tolib) DATA(*YES)
  CRTDUPOBJ  OBJ(h        ) FROMLIB(&FROMLIB) OBJTYPE(*file)   TOLIB(&tolib) DATA(*YES)
  CRTDUPOBJ  OBJ(*All     ) FROMLIB(&FROMLIB) OBJTYPE(*bnddir) TOLIB(&tolib)

  /* SQL features */
  CRTDUPOBJ  OBJ(RTVSQLROW) FROMLIB(&FROMLIB) OBJTYPE(*all   ) TOLIB(&tolib)
  CRTDUPOBJ  OBJ(JXS001   ) FROMLIB(&FROMLIB) OBJTYPE(*pgm   ) TOLIB(&tolib)


