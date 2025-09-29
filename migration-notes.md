# noxDb to noxDbUTF8 migrations notes;

1) only nox_ prototypes a build by default. No "syntax suggar" json_ and xml_ are made by default.

2) nox_sql... function a now 100% reintrant, which means:
2.1) all sql function requires a connection parameter ( exept for the connect)
2.2) parameters a reorderes to be more strinct: Connection:sqlstatement:parametes:[options]

3) renamed


