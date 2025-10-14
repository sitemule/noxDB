// CMD:CRTCPPMOD
#include <cstdlib>
//extern "C" void nox_setDelimitersByCcsid (int);
extern "C" void nox_Initialize (void);
extern "C" void nox_sqlDisconnect (void *);


class Entry_Exit
{
    public:
    int m_nEntry;
    int m_nExit;

    // Construction
    public:
        Entry_Exit(void);   // standard constructor
        ~Entry_Exit(void);
};

    Entry_Exit::Entry_Exit(void) {
        //nox_setDelimitersByCcsid (0);
        nox_Initialize();
        m_nEntry = 0;
    }

    Entry_Exit::~Entry_Exit() {
        nox_sqlDisconnect(NULL);
        m_nExit = 0;
    }


static  Entry_Exit  My_Entry_Exit;
