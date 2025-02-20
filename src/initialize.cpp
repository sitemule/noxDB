extern "C" void jx_setDelimitersByCcsid (int);
extern "C" void jx_sqlDisconnect (void);


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
        jx_setDelimitersByCcsid (0);
        m_nEntry = 0;
    }

    Entry_Exit::~Entry_Exit() {
        jx_sqlDisconnect();
        m_nExit = 0;
    }


static  Entry_Exit  My_Entry_Exit;