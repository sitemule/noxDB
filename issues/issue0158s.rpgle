**FREE
// CMD:CRTRPGMOD
// Issue 158: the service program issue0158.rpgle calls with JSON.
//
// Procedures are called by their parameters - a return value is not mapped,
// so results go in parameters.
//
//   gmake issues/issue0158s.rpgle --always-make
//   CRTSRVPGM SRVPGM(<lib>/ISSUE0158S) MODULE(<lib>/ISSUE0158S) EXPORT(*ALL)
ctl-opt nomain pgminfo(*PCML:*MODULE)
        option(*srcstmt : *nodebugio : *nounref);

// ------------------------------------------------------------------------------------
// Convert an amount between currencies ( fixed demo rates against DKK )
// ------------------------------------------------------------------------------------
dcl-proc convert export;
    dcl-pi *n;
        amount     packed(11:2) const;
        fromCur    char(3)      const;
        toCur      char(3)      const;
        result     packed(11:2);
        rate       packed(11:6);
    end-pi;

    rate   = dkk(fromCur) / dkk(toCur);
    result = amount * rate;
end-proc;

dcl-proc dkk;
    dcl-pi *n packed(9:4);
        cur char(3) const;
    end-pi;
    select;
        when cur = 'EUR';
            return 7.46;
        when cur = 'USD';
            return 6.90;
        when cur = 'SEK';
            return 0.65;
    endsl;
    return 1;
end-proc;

// ------------------------------------------------------------------------------------
// Split a text into words: a top level array with its _LENGTH parameter
// ------------------------------------------------------------------------------------
dcl-proc split export;
    dcl-pi *n;
        text          varchar(200) const;
        words         char(20) dim(10);
        words_LENGTH  int(10);
    end-pi;

    dcl-s pos   int(10) inz(1);
    dcl-s stop  int(10);
    dcl-s word  varchar(200);

    words_LENGTH = 0;
    dow pos <= %len(text) and words_LENGTH < %elem(words);
        stop = %scan(' ' : text : pos);
        if stop = 0;
            stop = %len(text) + 1;
        endif;
        word = %subst(text : pos : stop - pos);
        if %len(word) > 0;
            words_LENGTH += 1;
            words(words_LENGTH) = word;
        endif;
        pos = stop + 1;
    enddo;
end-proc;
