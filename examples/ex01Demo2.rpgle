**FREE
    // ------------------------------------------------------------- 
    // noxDB - Not Only Xml - Its JSON, XML, SQL and more
    //
    // This tutorial will show all the features, from a JSON 
    // and SQL perspective
    //
    // Design:  Niels Liisberg  
    // Project: Sitemule.com
    //
    // try/build:
    // cd '/prj/NOXDBUTF8' 
    // addlible NOXDBUTF8 
    // call 
    // ------------------------------------------------------------- 

    Ctl-Opt BndDir('NOXDBUTF8') dftactgrp(*NO) ACTGRP('QILE'); 
    Ctl-Opt CCSID(*CHAR:*UTF8) ; //  CCSID(*EXACT) ; // CCSID(*CHAR:*JOBRUN) ; // CCSID(*CHAR:*UTF8);

    /include QRPGLEREF,noxDbUtf8
    *INLR = *ON;    