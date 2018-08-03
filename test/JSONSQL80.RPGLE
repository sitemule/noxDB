      * ------------------------------------------------------------- *
      * This sample shows the use of the buildin JSONparser in
      * IceBreak
      *
      *
      *  trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
      *         DSPCPATRC
      *
      *  http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.html
      * ------------------------------------------------------------- *
     H BndDir('JSONPARSER') dftactgrp(*NO) ACTGRP('QILE' )

      /include jsonParser
      /free

        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
