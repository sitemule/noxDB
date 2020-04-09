// CMD:CRTCMOD 
/* ------------------------------------------------------------- *
 * Company . . . : System & Method A/S                           *
 * Design  . . . : Niels Liisberg                                *
 * Function  . . : NOX - main service program API exports        *
 *                                                               *
 * By     Date     Task    Description                           *
 * NL     02.06.03 0000000 New program                           *
 * NL     27.02.08 0000510 Allow also no namespace for *:tag     *
 * NL     27.02.08 0000510 nox_NodeCopy                           *
 * NL     13.05.08 0000577 nox_NodeAdd / WriteNote                *
 * NL     13.05.08 0000577 Support for refference location       *
 * ------------------------------------------------------------- */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <decimal.h>
#include <QCMDEXC.h>

int main (int argc , char ** argv)
{
    int i;
    // dup(outputfd)                                                                
    // reassign std-files                                                           
    // close(0);                                                                       
    // close(1);                                                                       
    // close(2);    
    printf("Start\n");
                                                                                    
    // sin  = open("/dev/null" ,  O_CREAT|O_TRUNC|O_RDWR,   S_IRUSR|S_IROTH);          
    // sout = open(snout       ,  O_CREAT|O_TRUNC|O_WRONLY, S_IWUSR|S_IWOTH, 1252);    
    // serr = open(snerr       ,  O_CREAT|O_TRUNC|O_WRONLY, S_IWUSR|S_IWOTH, 1252);    
    for (i=1;i< argc ; i++) {
        QCMDEXC (argv[i] , strlen(argv[i]));
    }
}