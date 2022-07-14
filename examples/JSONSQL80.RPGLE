        //------------------------------------------------------------- *
        //This sample shows the use of the buildin JSONparser in
        //IceBreak


        //trace: CHGCPATRC JOBNUMBER(*CURRENT) SEV(*INFO)
        //DSPCPATRC

        //http://www-03.ibm.com/systems/power/software/i/db2/support/tips/clifaq.
        //------------------------------------------------------------- *
        Ctl-Opt BndDir('NOXDB2') dftactgrp(*NO) ACTGRP('QILE' );

      /include 'headers/JSONPARSER.rpgle'

        json_sqlDisconnect();

        // That's it..
        *inlr = *on;
