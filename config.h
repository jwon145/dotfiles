/* MIT/X Consortium License */
static const char font[]            = "-*-dina-medium-r-*-*-*-160-*-*-*-*-*-*";
//static const char normbordercolor[] = "#212121";
//static const char normbgcolor[]     = "#262626";
//static const char normfgcolor[]     = "#696969";
//static const char selbordercolor[]  = "#696969"; 
//static const char selbgcolor[]      = "#262626";
//static const char selfgcolor[]      = "#E0E0E0";
static const char normbordercolor[] = "#696969";
static const char normbgcolor[]     = "#1b1d1e";
static const char normfgcolor[]     = "#e0e0e0";
static const char selbordercolor[]  = "#02a2ff"; 
static const char selbgcolor[]      = "#1b1d1e";
static const char selfgcolor[]      = "#02a2ff";
static const unsigned int borderpx  = 1;        /* border pixel of windows */
static const unsigned int snap      = 4;        /* snap pixel */
static const Bool showbar           = True;     /* False means no bar */
static const Bool topbar            = True;     /* False means bottom bar */
static const unsigned int gappx     = 15;           /* gap pixel between windows */

static const Rule rules[] = {
    	/* class         instance    title       tags mask     isfloating   monitor */
        { "Firefox",        NULL,       NULL,       1 << 0,       False,        -1 },
        { "urxvt",          NULL,       NULL,       1 << 3,       False,        -1 },
        { "zenity",       NULL,       NULL,       0,         True,        -1 },
        { NULL,       NULL,       "xmessage",       0,         True,        -1 },
        { NULL,       NULL,       "zenity",       0,         True,        -1 },
        {  NULL,            NULL,      "tmux",      1 << 1,       False,        -1 },
        {  "sun-awt-X11-XFramePeer",        NULL,       NULL,       1 << 0,       True,        -1 },
};

/* tags & layouts */
static const char      *tags[] = { "foo", "bar", "baz", "qux", "quux" };

static const int initlayouts[] = { 0, 0, 0, 0, 0 }; 

static const float mfact       = 0.55;  /*  factor of master area size [0.05..0.95]         */
static const Bool resizehints  = False; /*  True means respect size hints in tiled resizals */

static const Layout  layouts[] = {
	/* symbol     arrange function   */
	{ "[T]",      tile },        /* first entry is default */
	{ "[M]",      monocle },   
	{ "[F]",      NULL },
    };

/*  key definitions  */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static const char   *termcmd[] = { "urxvt", NULL };
static const char   *dmcmd[] = { "dmenu_run", "-nb", "#303030", "-nf", "#909090", "-sb", "#909090", "-sf", "#303030", "-fn", "dina", NULL };
static const char    *webcmd[] = { "/opt/google/chrome/google-chrome", NULL };
static const char    *dmenucmd[] = { "firefox", NULL };
static const char    *gfriendscmd[] = { "~stevec/gfriends", NULL };
static const char   *quitcmd[] = { "killall", "startup",  NULL };
// Control - Ctrl, Mod1 - Alt, MODKEY - Applekey, Shift - shift
static Key keys[] = {
	/*   modifier                   key        function        argument        */
	{ 0,                            XK_Menu,   spawn,          {.v = dmenucmd } },
	{ MODKEY,                       XK_r,      spawn,          {.v = termcmd } },
	{ MODKEY,                       XK_e,      spawn,          {.v = dmcmd } },
    { MODKEY,                       XK_w,      spawn,          {.v = webcmd } },
    { MODKEY,                       XK_f,      spawn,          {.v = gfriendscmd } },
    { MODKEY,                       XK_q,      quit,           {0} },
	{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY,                       XK_x,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_z,      focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_c,      killclient,     {0} },
    { MODKEY|ControlMask,           XK_x,      pushdown,       {0} },
    { MODKEY|ControlMask,           XK_z,      pushup,         {0} },
	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
	{ MODKEY,                       XK_Return, zoom,           {0} },
	{ MODKEY,                       XK_Tab,    view,           {0} },
	{ MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} },
	{ MODKEY,                       XK_m,      setlayout,      {.v = &layouts[1]} },
	{ MODKEY,                       XK_f,      setlayout,      {.v = &layouts[2]} },
	{ MODKEY,                       XK_space,  setlayout,      {0} },
	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },
    { MODKEY,                       XK_Left,   tagcycle,       {.i = -1 } },
    { MODKEY,                       XK_Right,  tagcycle,       {.i = +1 } },
    { MODKEY|ControlMask,           XK_Left,   cycle,          {.i = -1 } },
    { MODKEY|ControlMask,           XK_Right,  cycle,          {.i = +1 } },
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
	{ MODKEY|ShiftMask,             XK_q,      spawn,          {.v = quitcmd } },
};

/* button definitions */
/* click can be ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};

