**FREE
// ------------------------------------------------------------------------------------
// noxDB - Not Only Xml - Its JSON, XML, SQL and more
//
// Demo 90 - the program that ex90Call calls by its PCML.
//
// Nothing here knows about JSON or noxDB: it is a plain program with plain
// parameters. The only thing it needs is pgminfo(*PCML:*MODULE), so the
// parameter list is stored in the object, where nox_CallProgram reads it.
//
// It splits an order into weekly deliveries of at most 100 pieces and
// returns a quote:
//   - "DELIVERIES" is an array of 10, but only "DELIVERIES_LENGTH" of them
//     are used. A sibling named <array>_LENGTH tells noxDB how many elements
//     to return, and it is not returned itself.
//
// try/build:
// cd '/prj/NOXDBUTF8'
// addlible NOXDBUTF8
// chgjob ccsid(500)
// gmake examples/ex90Pgm.rpgle --always-make
// ------------------------------------------------------------------------------------
Ctl-Opt copyright('Sitemule - System & Method (C), 2026');
Ctl-Opt pgminfo(*PCML:*MODULE);
Ctl-Opt dftactgrp(*NO) ACTGRP(*CALLER) option(*nodebugio:*srcstmt:*nounref);
Ctl-Opt main(main);

dcl-ds delivery_t qualified template;
    date        date(*iso);
    quantity    int(10);
    amount      packed(11:2);
end-ds;

dcl-ds quote_t qualified template;
    customer          char(30);
    total             packed(13:2);
    deliveries        likeds(delivery_t) dim(10);
    deliveries_LENGTH int(10);
end-ds;

// ------------------------------------------------------------------------------------
dcl-proc main;
    dcl-pi *n;
        customer   char(30)     const;
        quantity   int(10)      const;
        price      packed(11:2) const;
        firstDate  date(*iso)   const;
        quote      likeds(quote_t);
    end-pi;

    dcl-s left int(10);
    dcl-s n    int(10);

    clear quote;
    quote.customer = customer;
    left = quantity;

    dow left > 0 and n < %elem(quote.deliveries);
        n += 1;
        quote.deliveries(n).date     = firstDate + %days(7 * (n - 1));
        quote.deliveries(n).quantity = %min(left : 100);
        quote.deliveries(n).amount   = quote.deliveries(n).quantity * price;
        quote.total += quote.deliveries(n).amount;
        left -= quote.deliveries(n).quantity;
    enddo;

    quote.deliveries_LENGTH = n;
end-proc;
