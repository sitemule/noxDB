**FREE

///
// Routing to a program adding openAPI ( swagger)
//
// This example shows how traditional programs compiled with
//    ctl-opt pgminfo(*PCML:*MODULE) thread(*CONCURRENT);
// can be used with ILEastic, and also serve the openAPI.json ( yet to come)
//
// The routing is shown in swagroute.rpgle
//
// Start it:
// SBMJOB CMD(CALL PGM(SWAGROUTE)) JOB(SWAGROUTE) JOBQ(QSYSNOMAX) ALWMLTTHD(*YES)
//
// The web service can be tested with the browser by entering the following URL:
// http://my_ibm_i:44045/hello?name=john
//
// @info: It requires your RPG code to be reentrant and compiled for
//        multithreading. Each client request is handled by a seperate thread.
///
ctl-opt pgminfo(*PCML:*MODULE) thread(*CONCURRENT);
ctl-opt copyright('Sitemule.com  (C), 2023');
ctl-opt decEdit('0,') datEdit(*YMD.);
ctl-opt debug(*yes);

dcl-pi *N;
    name char (10) const;
    text char(200);
    age  packed(5:0);
end-pi;

text = 'hello ' + name;
age = 25;
return;

// PCML Structure similar to this:
// <pcml version="6.0">
//    <!-- RPG program: NTUT99  -->
//    <!-- created: 2025-05-20-16.21.26 -->
//    <!-- source: /prj/noxdb-tutorials/ntut99.rpgle -->
//    <!-- 5824 -->
//    <program name="NTUT99" path="/QSYS.LIB/QGPL.LIB/NTUT99.PGM">
//       <data name="JOB" type="char" length="10" usage="input" />
//       <data name="YEARS" type="packed" length="3" precision="0" usage="input" />
//       <data name="SALARY" type="packed" length="5" precision="0" usage="inputoutput" />
//    </program>
// </pcml>

// Or:
// <pcml version="6.0">
//    <!-- RPG program: NTUT99  -->
//    <!-- created: 2025-05-20-16.17.40 -->
//    <!-- source: /prj/noxdb-tutorials/ntut99.rpgle -->
//    <!-- 5820 -->
//    <program name="MAIN">
//       <data name="JOB" type="char" length="10" usage="input" />
//       <data name="YEARS" type="packed" length="3" precision="0" usage="input" />
//       <data name="SALARY" type="packed" length="5" precision="0" usage="inputoutput" />
//    </program>
// </pcml>
//
