/* PGM(JXS001) ALLOW(*IPGM *BPGM *BREXX *IREXX    ) */
             CMD        PROMPT('Retrive row using SQL')

             PARM       KWD(ID) TYPE(*CHAR) LEN(10) +
                          CONSTANT('RTVSQLVAL')

             PARM       KWD(SQLCMD) TYPE(*CHAR) LEN(8192) MIN(1) +
                          EXPR(*YES) VARY(*YES *INT2) CASE(*MIXED) +
                          PROMPT('SQL Select statement')

             PARM       KWD(found)  TYPE(*LGL)           +
                          RTNVAL(*YES)                  +
                          PROMPT('*ON If row is found'          )

             PARM       KWD(INTO01) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 01 (1-32766)')
             PARM       KWD(INTO02) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 02 (1-32766)')

             PARM       KWD(INTO03) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 03 (1-32766)')

             PARM       KWD(INTO04) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 04 (1-32766)')

             PARM       KWD(INTO05) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 05 (1-32766)')

             PARM       KWD(INTO06) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 06 (1-32766)')

             PARM       KWD(INTO07) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 07 (1-32766)')

             PARM       KWD(INTO08) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 08 (1-32766)')

             PARM       KWD(INTO09) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 09 (1-32766)')

             PARM       KWD(INTO10) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 10 (1-32766)')


             PARM       KWD(INTO11) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 11 (1-32766)')

             PARM       KWD(INTO12) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 12 (1-32766)')

             PARM       KWD(INTO13) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 13 (1-32766)')

             PARM       KWD(INTO14) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 14 (1-32766)')

             PARM       KWD(INTO15) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 15 (1-32766)')

             PARM       KWD(INTO16) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 16 (1-32766)')

             PARM       KWD(INTO17) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 17 (1-32766)')

             PARM       KWD(INTO18) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 18 (1-32766)')

             PARM       KWD(INTO19) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 19 (1-32766)')


             PARM       KWD(INTO20) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 20 (1-32766)')

             PARM       KWD(INTO21) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 21 (1-32766)')

             PARM       KWD(INTO22) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 22 (1-32766)')

             PARM       KWD(INTO23) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 23 (1-32766)')

             PARM       KWD(INTO24) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 24 (1-32766)')

             PARM       KWD(INTO25) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 25 (1-32766)')

             PARM       KWD(INTO26) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 26 (1-32766)')

             PARM       KWD(INTO27) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 27 (1-32766)')

             PARM       KWD(INTO28) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 28 (1-32766)')

             PARM       KWD(INTO29) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 29 (1-32766)')

             PARM       KWD(INTO30) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 30 (1-32766)')

             PARM       KWD(INTO31) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 31 (1-32766)')

             PARM       KWD(INTO32) TYPE(*CHAR) LEN(1) +
                          RTNVAL(*YES) VARY(*YES *INT2) +
                          PROMPT('Returned column 32 (1-32766)')
