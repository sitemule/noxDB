/* ---------------------------------------------------------------------------------------- */
/* Copyright [2016] [System & Method A/S]                                                   */
/*                                                                                          */
/* Licensed under the Apache License, Version 2.0 (the "License");                          */
/* you may not use this file except in compliance with the License.                         */
/* You may obtain a copy of the License at                                                  */
/*                                                                                          */
/*     http://www.apache.org/licenses/LICENSE-2.0                                           */
/*                                                                                          */
/* Unless required by applicable law or agreed to in writing, software                      */
/* distributed under the License is distributed on an "AS IS" BASIS,                        */
/* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.                 */
/* See the License for the specific language governing permissions and                      */
/* limitations under the License.                                                           */
/* ---------------------------------------------------------------------------------------- */
/* Design  . . . : Niels Liisberg                                                           */
/* Function  . . : retrive a row from SQL within a CL/CLLE program                          */
/*                                                                                          */
/*By      Date      Task   Description                                                 */
/* NLI      15.02.2016 0000000 New program                                                  */
/* ---------------------------------------------------------------------------------------- */
Pgm ()


   Dcl &found     *lgl
   Dcl &prodid    *char 32
   Dcl &desc      *char 256

   rtvSqlRow  sqlcmd('-
        Select PRODID, DESC       -
        from product              -
        where prodKey = 100       -
        fetch first 1 row only    -
   ') found(&found)   -
      into01(&prodid) -
      into02(&desc  ) -

   if (&found)  then(-
     sndpgmmsg ('Prod:' !> &prodid !> 'desc' !> &desc) -
   )
   else (-
     sndpgmmsg ('Prod 100 was not found')              -
   )

EndPgm
