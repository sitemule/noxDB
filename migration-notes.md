# noxDb to noxDbUTF8 migrations notes;

1) only nox_ prototypes a build by default. No "syntax suggar" json_ and xml_ are made by default.

2) nox_sql... function a now 100% reintrant, which means:
2.1) all sql function requires a connection parameter ( exept for the connect)
2.2) parameters are reorderes to be more strinct: Connection:sqlstatement:parametes:[options]

3) nox_GetNum ( jx_GetNum ) is renamed to nox_GetDec - it still returns packed(30:15).
3.1) use nox_GetInt when the value is an integer, e.g. counting elements with [UBOUND]:
     count = nox_GetInt(pXml : '/a/l[UBOUND]');



