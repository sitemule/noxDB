/* PGM(JXS001) ALLOW(*IPGM *BPGM *BREXX *IREXX    ) */
             CMD        PROMPT('Retrive row using SQL')

             PARM       KWD(ID) TYPE(*CHAR) LEN(10) +
                          CONSTANT('RTVSQLVAL')

             PARM       KWD(SQLCMD) TYPE(*CHAR) LEN(8192) MIN(1) +
                          EXPR(*YES) VARY(*YES *INT2) CASE(*MIXED) +
                          PROMPT('SQL Select statement')

             PARM       KWD(column) TYPE(COL) max(20)   +
                          rtnval(*YES)                          +
                          PROMPT('Returned column 001 len(8192)')
COL:        ELEM       TYPE(*CHAR)                        +


