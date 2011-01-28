fl
\
\ the _xc wrod is also a marker for the beginning of this file, see the spimaker word
\ _xc ( c1 c2 cstr  -- c1 -1 | cstr -1 0 )
: _xc rot2 over = if drop -1 0 else nip -1 then ;
\
\ xc1 ( c1 -- cstr -1 | c1 0 ) c1 - to be xlated, t/f true &  xx is the address of the xlated string, t/f false xx is c1
: xc1
22 c" quote" _xc if
23 c" hash" _xc if
30 c" z" _xc if
31 c" one" _xc if
32 c" two" _xc if
33 c" three" _xc if
34 c" four" _xc if
38 c" eight" _xc if
28 c" lparen" _xc if
29 c" rparen" _xc if 0 thens ;
\
\ xc2 ( c1 -- xx t/f ) c1 - to be xlated, t/f true &  xx is the address of the xlated string, t/f false xx is c1
: xc2
5B c" sbo" _xc if
5C c" bs" _xc if
5D c" sbc" _xc if
3A c" colon" _xc if
3B c" scolon" _xc if
27 c" tick" _xc if
40 c" at" _xc if
21 c" bang" _xc if
3D c" eq" _xc if
3E c" gt" _xc if 0  thens ;
\
\ xc3 ( c1 -- xx t/f ) c1 - to be xlated, t/f true &  xx is the address of the xlated string, t/f false xx is c1
: xc3
3C c" lt" _xc if
2D c" minus" _xc if
2B c" plus" _xc if
2F c" slash" _xc if
2A c" star" _xc if
2E c" dot" _xc if
2C c" comma" _xc if
24 c" dlr" _xc if
7B c" cbo" _xc if
7D c" cbc" _xc if
3f c" q" _xc if 0 thens ;
\
\ xlatnamechar ( c1 -- xx t/f ) c1 - to be xlated, t/f true &  xx is the address of the xlated string, t/f false xx is c1
: xlatnamechar xc1 if -1 else xc2 if -1 else xc3 then then ;
\
\ ixnfa ( n1 -- c-addr ) returns the n1 from the last nfa address
: ixnfa 0 max wlastnfa W@
begin over 0= if -1 else swap 1- swap nfa>next dup 0= then until nip ;
\
\ .xstr ( c-addr u1 -- ) emit u1 characters at c-addr
: .xstr dup 0<> if bounds do i C@ xlatnamechar if .cstr else emit then loop else 2drop then ;
\
\ .xstrname ( c-addr -- ) c-addr point to a forth name field, print the translated name
: .xstrname dup 0<> if namelen .xstr else drop ." ??? " then ;
\
\ xstrlen ( c-addr u1 -- u2 ) emit u1 characters at c-addr
: xstrlen dup 0<>
if bounds 0 rot2  do i C@ xlatnamechar if C@ else drop 1 then + loop nip else 2drop 0 then ;
\
\ xstrnamelen ( c-addr -- n1 ) c-addr point to a forth name field, n1 the tranlated length
: xstrnamelen dup namelen dup 0<> if xstrlen else nip then ;
\
\ nfacount ( -- n1 ) returns the number of nfas in the forth dictionary
: nfacount 0 wlastnfa W@ begin swap 1+ swap nfa>next dup 0= until drop ;
\
\ nfaix ( c-addr -- n1 ) returns the index of the nfa address, -1 if not found
: nfaix -1 swap 0 wlastnfa W@ begin rot 2dup = if 2drop swap -1 -1 -1 else rot 1+ rot nfa>next dup 0= then until 3drop ;
\
\ lastdef ( c-addr -- t/f ) true if this is the most recently defined word 
: lastdef dup c" wlastnfa" name= if drop 0 else dup find if pfa>nfa = else 2drop -1 then then ; 
\
\ a variable which point to the last word spun out
wvariable lastSpinNFA
\ spinname ( c-addr -- ) emit a spin name -1 @ 
: spinname -1 swap 22 emit namelen 0 
do C@++ dup 22 = if drop 22 emit ." ,$22" nip 0 swap else emit then loop drop if 22 emit then ;
\
\ spinwordheader ( n1 -- addr ) n1 is the nfa index, addr is the nfa
: spinwordheader
	cr 18 spaces ." word    "  
	lastSpinNFA W@ dup 0= if ." 0" drop else ." @" .xstrname ." NFA + $10" then cr
	ixnfa dup lastSpinNFA W! dup .xstrname ." NFA" 
	dup xstrnamelen namemax and 15 swap - 1 max dup spaces ." byte    $" over C@ .byte ." ," over spinname cr 
	over .xstrname ." PFA" spaces ." word    " ;
\
\ spinwordasm ( addr -- ) the nfa address
: spinwordasm ." (@a_" .xstrname ."  - @a_base)/4" cr ;  
\
\ spinwordconstant ( addr -- addr t/f ) addr is the nfa, false if the word was processed 
: spinwordconstant
	dup nfa>pfa W@ $C_a_doconw =
	if dup c" $H_" npfx
		if ." (@a_doconw - @a_base)/4" cr 18 spaces ." word    "	
			dup ." @" namelen 3 - swap 3 + swap .xstr ." PFA  + $10" cr 0
		else dup c" $C_" npfx
			if ." (@a_doconw - @a_base)/4" cr 18 spaces ." word    "	
				dup ." (@" namelen 3 - swap 3 + swap .xstr ."  - @a_base)/4" cr 0
			else -1 then
		then
	else -1 then ;
\
\ isExecasm ( addr -- t/f) true if addr is one of the ifuncs
: isExecasm dup $C_a__execasm2>1 = over $C_a__execasm1>1 = or swap $C_a__execasm2>0 = or ;
\
: spindcmp1 18 spaces ." word    $"  2+ dup W@ .word cr ;
: spindcmp2 18 spaces ." long    $" 2+ alignl dup dup 2+ W@ .word W@ .word 2+ cr ;
\
\ spindcmp ( addr -- addr t/f) process the post word data, flag true if at the end of the word
: spindcmp
dup W@ dup $C_a_doconw = swap $C_a_dovarw = or
if spindcmp1 -1 else
	dup W@ dup isExecasm over $C_a_litw = or over $C_a_branch = or over $C_a_(loop) = or over $C_a_(+loop) = or swap $C_a_0branch = or
if spindcmp1 0 else
	dup W@ dup $C_a_doconl = swap $C_a_dovarl = or
if spindcmp2 -1 else
	dup W@ $C_a_litl =
if spindcmp2 0 else
	dup W@ dup $H_dq = swap $H_cq = or
if 18 spaces ." byte    $" 2+ C@++ dup .byte ." ," 2dup 22 emit .str 22 emit + alignw 2- cr 0 else
	dup W@ $C_a_exit =
thens ;
\
\ spinwordforth( addr1 -- addr2 ) addr1 is the nfa, addr2 is the pfa address at the end of this word
: spinwordforth nfa>pfa 2-
begin
	2+ dup W@ dup pfa>nfa swap _fmask COG@ and if ." @" .xstrname ." PFA + $10" cr else spinwordasm then spindcmp dup 0=
	if 18 spaces ." word    " then
until 2+ ;

: _sw 0 do i 7 and 0= if i 0<> if cr then 18 spaces ." WORD    0" else ." ,0" then loop ;

: spinword dup spinwordheader dup C@ 80 and
if spinwordconstant
	if
		spinwordforth over 1- ixnfa 2- swap - dup 0<>
		if alignw 2/ dup 8 > if alignw 2/ then _sw else drop then
	else drop then
else spinwordasm then drop ;
\
: cr18 cr 18 spaces ;
\ spinmaker ( -- ) generates the forth spin code
: spinmaker 0 here W! nfacount 1- dup c" _xc" find
if cr ." ForthDictStart" cr pfa>nfa nfaix - 0 0 lastSpinNFA W!
	do dup i - dup ixnfa lastdef if spinword else drop then loop drop
	cr18 ." word    "  lastSpinNFA W@ ." @" .xstrname ." NFA + $10" cr
	." wlastnfaNFA             byte    $88," 22 emit ." wlastnfa" 22 emit cr
	." wlastnfaPFA             word    (@a_dovarw - @a_base) /4"
	cr18 ." word    @wlastnfaNFA + $10 " cr
	." wfreespacestart" cr
4c80 0 do
	cr18 ." long    0,0, 0,0, 0,0, 0,0,  0,0, 0,0, 0,0, 0,0"
40 +loop cr ." ForthDictEnd" cr ." ForthMemoryEnd" cr cr else 3drop then ;


