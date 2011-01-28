fl

hex

\ Copyright (c) 2010 Sal Sanci


\ These variables are the current dictionary limits cannot really easily redefine these variable on a running forth system,
\ it really screws things up to redefine requires multiple steps and caution, not worth the bother usually.
\ memend  W@ wvariable memend  memend  W!
\ here    W@ wvariable here    here    W!
\ dictend W@ wvariable dictend dictend W!
 
\ Constants which reference the cogdata space are effectively variables with a level of indirection. Refedinition of these,
\ if the base variable is the same is reasonable and can be done on a running system. Caution with other variables.

\ the numeric id of this prop
wvariable propid 0 propid W!

\ the default prop and version strings
: (prop) c" Prop" ;
: (version) c" PropForth v4.0 2010NOV28 13:00 0" ;

\ pointers to the prop and version strings 
wvariable prop
wvariable version

\ This variable is 0 (spin code) when the propeller is rebooted and set to non-zero when forth is initialized
_finit W@ wvariable _finit _finit W!

\ The size of the cog's data area, this will be initialized by _cdsz defined as a spin constant
_cdsz wconstant _cdsz


\ prop 7 is normally the console channel, this is the prop which handles communication to the console, and
\ provides the interface to the rest of the cogs
con wconstant con

\ These constants are all intialized to the running values, so any following words compile correctly. If you add constants
\ that are used by the base compiler, follow the practice. 
\ Any word constant which begins with $H_xxx is compiled with the value @xxxPFA + $10 - which is the exection address.
\ Any word constant which begins with $C_xxx is compiled with the value (@xxx - @a_base)/4 - execution address.

$H_serentry wconstant $H_serentry
$H_entry wconstant $H_entry

\ This is a pointer to the main cogdata area
$H_cogdata	wconstant	$H_cogdata

\ This is ' cq - the routine which handles the word c"
$H_cq	wconstant	$H_cq

\ This is ' dq - the routine which handles the word ."
$H_dq		wconstant	$H_dq

\ These constants are all assembler addresses
$C_a_exit	wconstant $C_a_exit
$C_a_dovarw	wconstant $C_a_dovarw
$C_a_doconw	wconstant $C_a_doconw
$C_a_branch	wconstant $C_a_branch
$C_a_litw	wconstant $C_a_litw
$C_a_2>r	wconstant $C_a_2>r
$C_a_(loop)	wconstant $C_a_(loop)
$C_a_(+loop)	wconstant $C_a_(+loop)
$C_a_0branch	wconstant $C_a_0branch
$C_a_dovarl	wconstant $C_a_dovarl
$C_a_doconl	wconstant $C_a_doconl
$C_a_litl	wconstant $C_a_litl
$C_a_debugonoff wconstant $C_a_debugonoff
$C_a_reset	wconstant $C_a_reset
$C_a__execasm2>1	wconstant $C_a__execasm2>1
$C_a__execasm1>1	wconstant $C_a__execasm1>1
$C_a__execasm2>0	wconstant $C_a__execasm2>0
$C_a_umstarlp		wconstant $C_a_umstarlp
$C_a_umslashmodlp 	wconstant $C_a_umslashmodlp
$C_a_cstreqlp 		wconstant $C_a_cstreqlp
$C_a__dictsearchlp 	wconstant $C_a__dictsearchlp

\ Addresses for the stack routines
$C_a_stpush		wconstant $C_a_stpush
$C_a_stpush_ret		wconstant $C_a_stpush_ret
$C_a_rspush		wconstant $C_a_rspush
$C_a_rspush_ret		wconstant $C_a_rspush_ret
$C_a_stpop		wconstant $C_a_stpop
$C_a_stpoptreg		wconstant $C_a_stpoptreg
$C_a_stpop_ret		wconstant $C_a_stpop_ret
$C_a_stpoptreg_ret	wconstant $C_a_stpoptreg_ret
$C_a_rspop		wconstant $C_a_rspop
$C_a_rspop_ret		wconstant $C_a_rspop_ret

\ Address for the a_next routine
$C_a_next	wconstant $C_a_next

\ This group of words needs to align with the assembler code
$C_varstart	wconstant $C_varstart
$C_varend	wconstant $C_varend
: _cv $C_varstart + ;
: _fmask 0 _cv ;
: _resetdreg 3 _cv ;
: ip 4 _cv ;
: _rsptr 6 _cv ;
: _rstop 4e _cv ;


\ This is space constant
bl	wconstant bl
\ -1 or true, used frequently
: -1 FFFFFFFF ;
\ 0 or false, used frequently
0	wconstant 0
\ This is the par register, always initalized to point to this cogs section of cogdata
1F0	wconstant par
\ the other cog special registers
1F1	wconstant cnt
1F2	wconstant ina
1F4	wconstant outa
1F6	wconstant dira

\ This variable defines the number of loops for an input timeout
_wkeyto  W@ wvariable _wkeyto  _wkeyto  W!
 
\ Flag to control the behavior of cr
_crf	W@ wvariable _crf _crf W!

\ Use in the _execasm2>1s to get rid of litw word
: _cnip here W@ 2- dup W@ over 2- W! here W! ; immediate

\ _execasm2>1 ( n1 n2 -- n ) \ the assembler operation is specified by the literal which follows (replaces the i field)
' _execasm2>1 asmlabel _execasm2>1

\ _execasm1>1 ( n -- n ) \ the assembler operation is specified by the literal which follows (replaces the i field)
' _execasm1>1 asmlabel _execasm1>1

\ _execasm2>0 ( n1 n2 -- ) \ the assembler operation is specified by the literal which follows (replaces the i field)
' _execasm2>0 asmlabel _execasm2>0

\ _dictsearch ( nfa cstr -- n1) nfa - addr to start searching in the dictionary, cstr - the counted string to find
\	n1 - -1 if found, 0 if not found, a fast assembler routine
' _dictsearch asmlabel _dictsearch

\ _maskin ( n -- t/f ) n is the bit mask to read in
' _maskin asmlabel _maskin

\ _maskoutlo ( n -- ) set the bits in n low
' _maskoutlo asmlabel _maskoutlo

\ _maskouthi ( n -- ) set the bits in n hi
' _maskouthi asmlabel _maskouthi

\ name= ( nfa cstr -- t/f)
' name= asmlabel name= 

\ cstr= ( cstr cstr -- t/f)
' cstr= asmlabel cstr=

\ and ( n1 n2 -- n1 ) \ bitwise and n1 n2
: and _execasm2>1 0C1 _cnip ;

\ andn ( n1 n2 -- n1 ) \ bitwise and n1 invert n2
: andn _execasm2>1 0C9 _cnip ;

\ L@ ( addr -- n1 ) \ fetch 32 bit value at main memory addr
: L@ _execasm1>1 011 _cnip ;

\ C@ ( addr -- c1 ) \ fetch 8 bit value at main memory addr
: C@ _execasm1>1 001 _cnip ;

\ W@ ( addr -- h1 ) \ fetch 16 bit value at main memory addr
: W@ _execasm1>1 009 _cnip ;

\ COG@ ( addr -- n1 ) \ fetch 32 bit value at cog addr
' COG@ asmlabel COG@

\ L! ( n1 addr -- ) \ store 32 bit value (n1) at main memory addr
: L! _execasm2>0 010 _cnip ;

\ C! ( c1 addr -- ) \ store 8 bit value (c1) main memory at addr
: C! _execasm2>0 000 _cnip ;

\ W! ( h1 addr -- ) \ store 16 bit value (h1) main memory at addr
: W! _execasm2>0 008 _cnip ;

\ COG! ( n1 addr -- ) \ store 32 bit value (n1) at cog addr
' COG! asmlabel COG!

\ branch \ 16 bit branch offset follows -  -2 is to itself, +2 is next word
' branch asmlabel branch

\ hubop ( n1 n2 -- n3 t/f ) n2 specifies which hubop (0 - 7), n1 is the source datcog, n3 is returned, 
\ 	t/f is the 'c' flag is set from the hubop
' hubop asmlabel hubop

\ doconw ( -- h1 ) \ push 16 bit constant which follows on the stack - implicit a_exit
' doconw asmlabel doconw

\ doconl ( -- n1 ) \ push a 32 bit constant which follows the stack - implicit a_exit
' doconl asmlabel doconl

\ dovarw ( -- addr ) \ push address of 16 bit variable which follows on the stack - implicit a_exit
' dovarw asmlabel dovarw

\ dovarl ( -- addr ) \ push address of 32 bit variable which follows the stack - implicit a_exit
' dovarl asmlabel dovarl

\ drop ( n1 -- ) \ drop the value on the top of the stack
' drop asmlabel drop

\ dup ( n1 -- n1 n1 )
' dup asmlabel dup

\ = ( n1 n2 -- t/f ) \ compare top 2 32 bit stack values, true if they are equal
' = asmlabel =

\ exit \ exit the current forth word, and back to the caller
' exit asmlabel exit

\ > ( n1 n2 -- t/f ) \ flag is true if and only if n1 is greater than n2
' > asmlabel >

\ litw ( -- h1 ) \  push a 16 bit literal on the stack
' litw asmlabel litw

\ litl ( -- n1 ) \  push a 32 bit literal on the stack
' litl asmlabel litl

\ lshift (n1 n2 -- n3) \ n3 = n1 shifted left n2 bits
: lshift _execasm2>1 059 _cnip ;

\ < ( n1 n2 -- t/f ) \ flag is true if and only if n1 is less than n2
' < asmlabel <

\ max ( n1 n2 -- n1 ) \ signed max of top 2 stack values
: max _execasm2>1 081 _cnip ;

\ min ( n1 n2 -- n1 ) \ signed min of top 2 stack values
: min _execasm2>1 089 _cnip ;

\ - ( n1 n2 -- n1-n2 )
: - _execasm2>1 109 _cnip ;

\ or ( n1 n2 -- n1_or_n2 ) \ bitwise or
: or _execasm2>1 0D1 _cnip ;

\ over ( n1 n2 -- n1 n2 n1 ) \ duplicate 2 value down on the stack to the top of the stack
' over asmlabel over

\ + ( n1 n2 -- n1+n2 ) \ sum of n1 & n2
: + _execasm2>1 101 _cnip ;

\ rot ( n1 n2 n3 -- n2 n3 n1 ) \ rotate top 3 value on the stack
' rot asmlabel rot

\ rshift ( n1 n2 -- n3) \ n3 = n1 shifted right logically n2 bits
: rshift _execasm2>1 51 _cnip ;

\ rashift ( n1 n2 -- n3) \ n3 = n1 shifted right arithmetically n2 bits
: rashift _execasm2>1 071 _cnip ;

\ r> ( -- n1 ) \ pop top of RS to stack
' r> asmlabel r>

\ >r ( n1 -- ) \ pop stack top to RS
' >r asmlabel >r

\ 2>r ( n1 n2 -- ) \ pop top 2 stack top to RS
' 2>r asmlabel 2>r

\ 0branch ( t/f -- ) \ branch it top of stack value is zero 16 bit branch offset follows,
\ -2 is to itself, +2 is next word
' 0branch asmlabel 0branch

\ (loop) ( -- ) \ add 1 to loop counter, branch if count is below limit offset follows,
\ -2 is to itself, +2 is next word
' (loop) asmlabel (loop)

\ (+loop) ( n1 -- ) \ add n1 to loop counter, branch if count is below limit, offset follows,
\ -2 is to itself, +2 is next word
' (+loop) asmlabel (+loop)

\ swap ( n1 n2 -- n2 n1 ) \ swap top 2 stack values
' swap asmlabel swap

\ um* ( u1 u2 -- u1*u2L u1*u2H ) \ unsigned 32bit * 32bit -- 64bit result
' um* asmlabel um*

\ um/mod ( u1lo u1hi u2 -- remainder quotient ) \ unsigned divide & mod  u1 divided by u2
' um/mod asmlabel um/mod

\ u/mod ( u1 u2 -- remainder quotient ) \ unsigned divide & mod  u1 divided by u2
: u/mod 0 swap um/mod ;

\ xor ( n1 n2 -- n1_xor_n2 ) \ bitwise xor
: xor _execasm2>1 0D9 _cnip ;

\ reboot ( -- ) reboot the propellor chip
: reboot FF 0 hubop ;

\ cogstop ( n -- )
: cogstop dup 3 hubop 2drop cogio 4+ _cdsz 2- 2- 0 fill  ;

\ cogreset ( n1 -- ) reset the forth cog
: cogreset
\ stop the cog, and 0 out the cog data area, if it is not the cog we are on
	7 and dup cogid <> if dup cogstop then
\ start up the cog
	dup dup cogio 10 lshift $H_entry 2 lshift or or 2 hubop 2drop
\ wait for the cog to come alive, for a bit of time
	cogstate 8000 0 do dup C@ 4 and if leave then loop drop ;

\ reset ( -- ) reset this cog
: reset mydictlock C@ if 0 lockclr drop then cogid cogreset ;

\ clkfreq ( -- u1 ) the system clock frequency
: clkfreq 0 L@ ;

\ parat ( offset -- addr )  the offset is added to the contents of the par register, giving an address references 
\ the cogdata
: parat par COG@ + ;

\ cogio ( n -- addr) the address of the data area for cog n
: cogio 7 and _cdsz u* $H_cogdata + ;

\ cogiochan ( n1 n2 -- addr ) cog n1, channel n2 ->addr
: cogiochan over cognchan 1- min 4* swap cogio + ;

\ io>cogchan ( addr -- n1 n2 ) addr -> n1 cogid, n2 channel
: io>cogchan $H_cogdata - dup 0< if drop -1  dup else _cdsz u/mod 7 and dup cognchan rot 4 u/ min then ;

\ io>cog ( addr -- n ) addr -> cogid
: io>cog io>cogchan drop ;

\ io  ( -- addr ) the address of the io channel for the cog
: io par COG@ ;

\ ERR ( n1 -- ) clear the input queue, set the error n1 and reset this cog
: ERR clearkeys io W! reset ;

\ (iodis) ( n1 n2 -- ) cog n1 channel n2 disconnect, disconnect this cog and the cog it is connected to
: (iodis) cogiochan 2+ dup W@ swap 0 swap 2+ W! dup if 0 swap 2+ W! else drop then ;

\ iodis ( n1 -- ) cogid to disconnect, disconnect this cog and the cog it is connected to
: iodis 0 (iodis) ;

\ (ioconn) ( n1 n2 n3 n4 -- ) connect cog n1 channel n2 to cog n3 channel n4, disconnect them from other cogs first
: (ioconn) 2dup (iodis) >r >r 2dup (iodis) r> r> cogiochan rot2 cogiochan 2dup 2+ W! swap 2+ W! ;

\ ioconn ( n1 n2 -- ) connect the 2 cogs, disconnect them from other cogs first
: ioconn 0 tuck (ioconn) ;

\ (iolink) ( n1 n2 n3 n4 -- ) links the 2 channels, output of cog n1 channel n2 -> input of cog n3 channel n4,
\  output of n3 channel n4 -> old output of n1 channel n2
: (iolink) cogiochan rot2 cogiochan swap over 2+ W@ over 2+ W! swap 2+ W! ;

\ iolink ( n1 n2 -- ) links the 2 cogs, output of n1 -> input of n2, output of n2 -> old output of n1
: iolink 0 tuck (iolink) ;
\ (iounlink) ( n1 n2 -- ) unlinks cog n1 channel n2
: (iounlink) cogiochan 2+ dup W@ 2+ dup W@ rot W! 0 swap W! ;

\ iounlink ( n1 -- ) unlinks the cog n1
: iounlink 0 (iounlink) ;

\***************************************************************************************************************************
\ free word at location 4

\ debugcmd  ( -- addr ) the address of the debugcmd as a word, used to commincate from forth cog to request a reset, 
\ or for traces
: debugcmd 6 parat ;
: cogdebugcmd cogio 6 + ;

\ debugvalue  ( -- addr ) the address of the debugvalue as a long, used in conjuction with debugcmd
: debugvalue 8 parat ;
: cogdebugvalue cogio 8 + ;

\ base ( -- addr ) access as a word, the address of the base variable
: base C parat ;

\ coghere ( -- addr ) access as a word, the first unused register address in this cog
: coghere E parat ;

\ execword ( -- addr ) a long, an area where the current word for execute is stored
: execword 10 parat ;

\ execute ( addr -- ) execute the word - pfa address is on the stack
: execute dup _fmask COG@ and if ip COG! else execword W! $C_a_exit execword 2+ W! execword ip COG! then ;

\ >out ( -- addr ) access as a word, the offset to the current output byte
: >out 14 parat ;

\ >in ( -- addr ) access as a word, addr is the var the offset in characters from the start of the input buffer to
\ the parse area.
: >in 16 parat ;

\ pad  ( -- addr ) access as bytes, or words and long, the address of the pad area - used by accept for keyboard input,
\ can be used carefully by other code
: pad 18 parat ;
: cogpad cogio 18 + ;

\ pad>in ( -- addr ) addr is the address to the start of the parse area.
: pad>in >in W@ pad + ;

\ namemax ( -- n1 ) the maximum name length allowed must be 1F
: namemax 1F ;

\ the size of the pad area
80 wconstant padsize

\ these are temporay variables, and by convention are only used within a word
\ caution, make sure you know what words you are calling
: t0 98 parat ;
: t1 9A parat ;
: tbuf 9C parat ; \   0x20 (32) byte array overflows into numpad

\ numpad ( -- addr ) the of the area used by the numeric output routines, can be used carefully by other code
: numpad BC parat ;
: cognumpad cogio BC + ;

\ pad>out ( -- addr ) addr is the address to the the current output byte
: pad>out >out W@ numpad + ;

\ the size of the numpad, 0x21 bytes if we are working in binary, otherwise 1 + max num digits are necessary
22 wconstant numpadsize

\ mydictlock ( -- addr ) access as a char, the number of times dictlock has been executed in the cog minus the freedict
: mydictlock DE parat ;

\ state ( -- addr) access as a char
: state DF parat ;
: cogstate cogio DF + ;
\ bit 0 -  0 - interpret mode / 1 - forth compile mode
\ bit 1 -  0 - direct console output turned off / 1 - direct console output turned on
\ bit 2 -  0 - Free / 1 - PropForth cog
\ bit 3 -  0 - Free / 1 - Other cog does not support IO channels
\ bit 4 -  0 - Free / 1 - Other cog supports io channels
\ bit 5 - 7 - number of io channels - 1

\ cognchan ( n1 -- n2 ) number of io channels for cog n2
: cognchan cogstate C@ 5 rshift 1 + ;

\ >con ( n1 -- ) disconnect the current cog, and connect the console to the forth cog
: >con con ioconn ;

\ compile? ( -- t/f ) true if we are in a compile
: compile? state C@ 1 and ;

\ emit? ( -- t/f) true if the output is ready for a char
: emit? io 2+ W@ dup if W@ 100 and 0<> else drop -1 then ;

\ femit? (c1 -- t/f) true if the output emitted a char, a fast non blocking emit
: femit? io 2+ W@ dup if dup W@ 100 and if swap FF and swap W! -1 else 2drop 0 then else 2drop -1 then ;

\ emit ( c1 -- ) emit the char on the stack
: emit begin dup femit? until drop ;

\ key? ( -- t/f) true if there is a key ready for input
: key? io W@ 100 and 0= ;

\ fkey? ( -- c1 t/f ) fast nonblocking key routine, true if c1 is a valid key
: fkey? io W@ dup 100 and if 0 else 100 io W! -1 then ;

\ key ( -- c1 ) get a key
: key 0 begin drop fkey? until ;

\ 2dup ( n1 n2 -- n1 n2 n1 n2 ) copy top 2 items on the stack
: 2dup over over ;

\ 2drop ( n1 n2 -- ) drop top 2 items on the stack
: 2drop drop drop ;

\ 3drop ( n1 n2 n3 -- ) drop top 3 items on the stack
: 3drop 2drop drop ;

\ u/ ( u1 u2 -- u1/u2) u1 divided by u2
: u/ u/mod nip ;

\ u* ( u1 u2 -- u1*u2) u1 multiplied by u2
: u* um* drop ;

\ invert ( n1 -- n2 ) bitwise invert n1
: invert -1 xor ;

\ negate ( n1 -- 0-n1 ) the negative of n1
: negate _execasm1>1 149 _cnip ;

\ 0= ( n1 -- t/f ) true if n1 is zero
: 0= 0 = ;

\ <> ( x1 x2 -- flag ) flag is true if and only if x1 is not bit-for-bit the same as x2. 
: <> = invert ;

\ 0 <> ( n1 -- t/f ) true if n1 is not zero
: 0<> 0= invert ;

\ 0< ( n1 -- t/f ) true if n1 < 0
: 0< 0 < ;

\ 0> ( n1 -- t/f ) true if n1 > 0
: 0> 0 > ;

\ 1+ ( n1 -- n1+1 )
: 1+ 1 + ;

\ 1- ( n1 -- n1-1 )
: 1- 1 - ;

\ 2+ ( n1 -- n1+2 )
: 2+ 2 + ;

\ 2- ( n1 -- n1-2 )
: 2- 2 - ;

\ 4+ ( n1 -- n1+4 )
: 4+ 4 + ;

\ 2* ( n1 -- n1<<1 ) n2 is shifted logically left 1 bit
: 2* 1 lshift ; 

\ 4* ( n1 -- n1<<1 ) n2 is shifted logically left 2 bits
: 4* 2 lshift ; 

\ 2/ ( n1 -- n1>>1 ) n2 is shifted arithmetically right 1 bit
: 2/ 1 rashift ;

\ rot2 ( x1 x2 x3 -- x3 x1 x2 )
: rot2 rot rot ;

\ nip ( x1 x2 -- x2 ) delete the item x1 from the stack
: nip swap drop ;

\ tuck ( x1 x2 -- x2 x1 x2 )
: tuck swap over ;

\ >= ( n1 n2 -- t/f) true if n1 >= n2
: >= 2dup > rot2 = or ;

\ <= ( n1 n2 -- t/f) true if n1 <= n2
: <= 2dup < rot2 = or ;

\ 0>= ( n1 -- t/f ) true if n1 >= 0
: 0>= dup 0 > swap 0= or ;

\ W+! ( n1 addr -- ) add n1 to the word contents of address
: W+! dup W@ rot + swap W! ;

\ orC! ( c1 addr -- ) or c1 with the contents of address
: orC! dup C@ rot or swap C! ;

\ andnC! ( c1 addr -- ) and inverse of c1 with the contents of address
: andnC! dup C@ rot andn swap C! ;

\ between ( n1 n2 n3 -- t/f ) true if n2 <= n1 <= n3
: between rot2 over <= rot2 >= and ;

\ cr ( -- ) emits a carriage return
: cr D emit _crf W@ if A emit then ;

\ space ( -- ) emits a space
: space bl emit ;

\ spaces ( n -- ) emit n spaces
: spaces dup if 0 do space loop else drop then ;

\ .hex ( n -- ) emit a single hex digit
: .hex F and 30 + dup 39 > if 7 + then emit ;

\ .byte ( n -- ) emit 2 hex digits
: .byte dup 4 rshift .hex .hex ;

\ .word ( n -- ) emit 4 hex digits
: .word dup 8 rshift .byte .byte ;

\ bounds ( x n -- x+n x )
: bounds over + swap ;

\ alignl ( n1 -- n1) aligns n1 to a long (32 bit)  boundary
: alignl 3 + FFFFFFFC and ;

\ alignw ( n1 -- n1) aligns n1 to a halfword (16 bit)  boundary
: alignw 1+ FFFFFFFE and ;

\ C@++ ( c-addr -- c-addr+1 c1 ) fetch the character and increment the address
: C@++ dup C@ swap 1+ swap ;

\ ctoupper ( c1 -- c1 ) if c is a-z converts it to upper case
: ctoupper dup 61 7A between if DF and then ;

\ todigit ( c1 -- n1 ) converts character to a number 
: todigit ctoupper 30 - dup 9 > if 7 - dup A < if drop -1 then then ;

\ isdigit ( c1 -- t/f ) true if is it a valid digit according to base
: isdigit todigit dup 0>= swap base W@ < and ;

\ isunumber ( c-addr len -- t/f ) true if the string is numeric
: isunumber bounds -1 rot2 do i C@ isdigit and loop ;

\ unumber ( c-addr len -- u1 ) convert string to an unsigned number
: unumber bounds 0 rot2 do base W@ u* i C@ todigit + loop ;

\ number ( c-addr len -- n1 ) convert string to a signed number
: number over C@ 2D = if 1- 0 max swap 1+ swap unumber negate else unumber then ;

\ isnumber ( c-addr len -- t/f ) true if the string is numeric
: isnumber over C@ 2D = if 1- 0 max swap 1+ swap then isunumber ;

\ .str ( c-addr u1 -- ) emit u1 characters at c-addr
: .str dup if bounds do i C@ emit loop else 2drop then ;

\ npfx ( c-addr1 c-addr2 -- t/f ) -1 if c-addr2 is prefix of c-addr1, 0 otherwise
: npfx namelen rot namelen rot 2dup >= if min bounds do C@++ i C@ <> if drop 0 leave then loop 0<> else 2drop 2drop 0 then ;

\ namelen ( c-addr -- c-addr+1 len ) returns c-addr+1 and the length of the name at c-addr
: namelen C@++ namemax and ;

\ cmove ( c-addr1 c-addr2 u -- ) If u is greater than zero, copy u consecutive characters from the data space starting
\  at c-addr1 to that starting at c-addr2, proceeding character-by-character from lower addresses to higher addresses.
: cmove dup 0= if 3drop else bounds do C@++ i C! loop then drop ;

\ namecopy ( c-addr1 c-addr2 -- ) Copy the name from c-addr1 to c-addr2
: namecopy over namelen 1+ nip cmove ;

\ ccopy ( c-addr1 c-addr2 -- ) Copy the cstr from c-addr1 to c-addr2
: ccopy over C@ 1+ cmove ;

\ cappend ( c-addr1 c-addr2 -- ) addpend the cstr from c-addr1 to c-addr2
: cappend dup dup C@ + 1+ rot2 over C@ over C@ + swap C! dup C@ swap 1+ rot2 cmove ;

\ cappendn ( n cstr -- ) print the number n and append to cstr
: cappendn swap <# #s #> swap cappend ;

\ (nfcog) ( -- n1 n2 ) n1 the next valid free forth cog, n2 is 0 if the cog is valid
: (nfcog) -1 -1 8 0 do
	i cogstate C@ 4 and if i cogio 2+ W@ 0= if 2drop i 0 leave then then
loop ;

 \ nfcog ( -- n ) returns the next valid free forth cog
: nfcog  (nfcog) if drop (cog+) (nfcog) if 8001 ERR then then ;

\ cogx ( cstr n -- ) execute cstr on cog n
: cogx io 2+ W@ rot2 cogio io 2+ W! .cstr cr io 2+ W! ;

\ .strname ( c-addr -- ) c-addr point to a forth name field, print the name
: .strname dup if namelen .str else drop 3f emit then ;

\ .cstr ( addr -- ) emit a counted string at addr
: .cstr C@++ .str ;

\ dq ( -- ) emit a counted string at the ip, and increment the ip past it and word alignw it
: dq r> C@++ 2dup + alignw >r .str ;

\ i ( -- n1 ) the most current loop counter
: i _rsptr COG@ 3 + COG@ ;

\ ibound ( -- n1 ) the upper bound of i
: ibound _rsptr COG@ 2+ COG@ ;

\ seti ( n1 -- ) set the most current loop counter
: seti _rsptr COG@ 3 + COG! ;

\ fill ( c-addr u char -- )
: fill rot2 bounds do dup i C! loop drop ;

\ nfa>lfa ( addr -- addr ) go from the nfa (name field address) to the lfa (link field address)
: nfa>lfa 2- ;

\ nfa>pfa ( addr -- addr ) go from the nfa (name field address) to the pfa (parameter field address)
: nfa>pfa 7FFF and namelen + alignw ;

\ nfa>next ( addr -- addr ) go from the current nfa to the prev nfa in the dictionary
: nfa>next nfa>lfa W@ ;

\ lastnfa ( -- addr ) gets the last NFA
: lastnfa wlastnfa W@ ;

\ isnamechar ( c1 -- t/f ) true if c1 is a valif name char > $20 < $7F
: isnamechar dup 20 > swap 7F < and ;

\ _forthpfa>nfa ( addr -- addr ) pfa>nfa for a forth word
: _forthpfa>nfa 7FFF and 1- begin 1- dup C@ isnamechar 0= until ;

\ _asmpfa>nfa ( addr -- addr ) pfa>nfa for an asm word
: _asmpfa>nfa lastnfa begin 2dup nfa>pfa W@ = over C@ 80 and 0= and if -1 else  nfa>next dup 0= then until nip ;

\ pfa>nfa ( addr -- addr ) gets the name field address (nfa) for a parameter field address (pfa)
: pfa>nfa dup _fmask COG@ and if _forthpfa>nfa else _asmpfa>nfa then ;

\ accept ( c-addr +n1 -- +n2 ) collect n1 -2 characters or until eol, convert tab to space,
\ pad with 1 space at start & end. For parsing ease, and for the length byte when we make cstrs
: accept 3 max 2dup bl fill 1- swap 1+ swap bounds 0
begin key dup A = over D = or
	if cr drop -1
	else dup 8 = over 7F = or
		if drop dup
			if 8 emit bl emit 8 emit 1- swap 1- bl over C! swap then 0
		else dup 9 = if drop bl then dup emit swap >r over C! 1+ 2dup 1+ = r> 1+ swap then
	then
until nip nip ;

\ parse ( c1 -- +n2 ) parse the word delimited by c1, or the end of buffer is reached, n2 is the length >in is the offset
\ in the pad of the start of the parsed word
: parse padsize >in W@ = if 0 else 0 begin 2dup pad>in + C@ = if -1 else 1+ 0 then until then nip ;

\ skipbl ( -- ) increment >in past blanks or until it equals padsize
: skipbl begin pad>in C@ bl = if >in W@ 1+ dup >in W! padsize = else -1 then until ;

\ nextword ( -- ) increment >in past current counted string
: nextword padsize >in W@ > if pad>in C@ >in W@ + 1+ >in W! then ;

\ parseword ( c1 -- +n2 ) skip blanks, and parse the following word delimited by c1, update to be a counted string in
\ the pad
: parseword skipbl parse dup if >in W@ 1- 2dup pad + C! >in W! then ; 

\ parsebl ( -- t/f) parse the next word in the pad delimited by blank, true if there is a word
: parsebl bl parseword 0<> ;

\ parsenw ( -- cstr ) parse and move to the next word, str ptr is zero if there is no next word
: parsenw parsebl if pad>in nextword else 0 then ;

\ find ( c-addr -- c-addr 0 | xt 2 | xt 1  |  xt -1 ) c-addr is a counted string, 0 - not found, 2 eXecute word, 
\ 1 immediate word, -1 word NOT ANSI
\
: find lastnfa over _dictsearch dup
if nip dup nfa>pfa over C@ 80 and 0= if W@ then
	swap C@ dup 40 and
	if 20 and if 2 else 1 then
	else drop -1 then
then ;

\ <# ( -- ) initialize the output area
: <# numpadsize >out W! ;

\ #> ( -- caddr ) address of a counted string representing the output, NOT ANSI
: #> drop numpadsize >out W@ - -1 >out W+! pad>out C! pad>out ;

\ tochar ( n1 -- c1 ) convert c1 to a char
: tochar 1F and 30 + dup 39 > if 7 + then ;

\ # ( n1 -- n2 ) divide n1 by base and convert the remainder to a char and append to the output
: # base W@ u/mod swap tochar -1 >out W+! pad>out C! ;

\ #s ( n1 -- 0 ) execute # until the remainder is 0
: #s begin # dup 0= until ;

\ some very common formatting routines
\ .bvalue ( n1 -- )
: .bvalue <# # # # #> .cstr ;
\ .addr ( n1 -- )
: .addr <# # # # # # # #> .cstr ;
\ .value ( n1 -- )
: .value <# # # # # # # # # # # # #> .cstr ;

\ . ( n1 -- )
: . dup 0< if 2D emit negate then <# #s #> .cstr 20 emit ;

\ cogid ( -- n1 ) return id of the current cog ( 0 - 7 )
: cogid -1 1 hubop drop ;

\ lockset ( n1 -- n2 ) set lock n1, result is in n2, -1 if the lock was set as per 'c' flag, lock ( n1 ) must have
\ been allocated via locknew
: lockset 6 hubop nip ;

\ lockclr ( n1 -- n2 ) clear lock n1, result is in n2, -1 if the lock was set as per 'c' flag, lock ( n1 ) must have
\ been allocated via locknew
: lockclr 7 hubop nip ;

\ lockdict? ( -- t/f ) attempt to lock the forth dictionary, 0 if unsuccessful -1 if successful
: lockdict? mydictlock C@ dup 
	if
		1+ FF min mydictlock C! -1
	else
\ TOS is zero 0 lockset
		lockset
		if
			0
		else
			1 mydictlock C! -1 
		then
	then ;

\ freedict ( -- ) free the forth dictionary, if I have it locked
: freedict mydictlock C@ dup if 1- dup mydictlock C! 0= if 0 lockclr drop then else drop then ;

\ lockdict ( -- ) lock the forth dictionary
: lockdict begin lockdict? until ;

\ checkdict ( n -- ) make sure there are at least n bytes available in the dictionary
: checkdict here W@ + dictend W@ >= if 8002 ERR then ;

: (createbegin) lockdict
	wlastnfa W@ here W@ dup 2+ wlastnfa W! swap over W! 2+ ;

: (createend) over namecopy namelen + alignw here W! freedict ;

\ ccreate ( cstr -- ) create a dictionary entry
: ccreate  (createbegin) swap  (createend) ;
 
\ create ( -- ) skip blanks parse the next word and create a dictionary entry
: create bl parseword if (createbegin) pad>in (createend) nextword then ;

\ clabel ( cstr -- ) create an assembler constant at the current cog coghere
: clabel lockdict ccreate $C_a_doconw w, coghere W@ w, forthentry freedict ;

\ herewal ( -- ) align contents of here to a word boundary, 2 byte boundary
: herewal lockdict 2 checkdict here W@ alignw here W! freedict ;

\ allot ( n1 -- ) add n1 to here, allocates space on the data dictionary or release it
: allot lockdict dup checkdict here W+! freedict ;

\ w, ( x -- ) allocate 1 halfword 2 bytes in the dictionary and copy x to that location
: w, lockdict herewal here W@ W! 2 allot freedict ;

\ c, ( x -- ) allocate 1 byte in the dictionary and copy x to that location
: c, lockdict here W@ C! 1 allot freedict ;

\ herelal ( -- ) alignw contents of here to a long boundary, 4 byte boundary
: herelal lockdict 4 checkdict here W@ alignl here W! freedict ;

\ l, ( x -- ) allocate 1 long, 4 bytes in the dictionary and copy x to that location
: l, lockdict  herelal here W@ L! 4 allot freedict ;

\ orlnfa ( c1 -- ) ors c1 with the nfa length of the last name field entered
: orlnfa lockdict lastnfa orC! freedict ;

\ forthentry ( -- ) marks last entry as a forth word
: forthentry lockdict 80 orlnfa freedict ;

\ immediate ( -- ) marks last entry as an immediate word
: immediate lockdict 40 orlnfa freedict ;

\ exec ( -- ) marks last entry as an eXecute word, executes always
: exec lockdict 60 orlnfa freedict ;

\ leave ( -- ) exits at the next loop or +loop, i is placed to the max loop value
: leave r> r> r> drop dup 2>r >r ;

\ clearkeys ( -- ) clear the input keys
: clearkeys 1 state andnC! begin -1 _wkeyto W@ 0 do key? if key 2drop 0 leave then loop until ;

\ w>l ( n1 n2 -- n1n2 ) consider only lower 16 bits
: w>l FFFF and swap 10 lshift or ;

\ l>w ( n1n2 -- n1 n2) break into 16 bits
: l>w dup 10 rshift swap FFFF and ;

: : lockdict create 3741 1 state orC! ;

: _mmcs ." MISMATCHED CONTROL STRUCTURE(S)" cr clearkeys ;
: _; w, 1 state andnC! forthentry 3741 <> if _mmcs then freedict ;

\ to prevent ; from using itself while it is defining itself
: ;; $C_a_exit _; ; immediate
: ; $C_a_exit _; ;; immediate

: dothen l>w dup 1235 = swap 1239 = or if dup here W@ swap - swap W! else _mmcs then ;
: then dothen ; immediate
: thens begin dup FFFF and dup 1235 = swap 1239 = or if dothen 0 else -1 then until ; immediate
: if $C_a_0branch w, here W@ 1235 w>l 0 w, ; immediate
: else $C_a_branch w, 0 w, dothen here W@ 2- 1239 w>l ; immediate
: until l>w 1317 = if $C_a_0branch w, here W@ - w, else _mmcs then ; immediate
: begin here W@ 1317 w>l ; immediate
: doloop swap l>w 2329 = if swap w, here W@ - w, else _mmcs then ;
: loop  $C_a_(loop) doloop ; immediate
: +loop  $C_a_(+loop) doloop ; immediate
: do $C_a_2>r w, here W@ 2329 w>l ; immediate

: _ecs 3A emit space ;
: _udf ." UNDEFINED WORD " ;

: _sp w, 1 >in W+! 22 parse dup c, dup pad>in here W@ rot cmove dup allot 1+ >in W+! herewal ; 
: ." $H_dq _sp ;  immediate

\ fisnumber ( -- ) dummy routine s for indirection when float package is loaded
: fisnumber isnumber ;
: fnumber number ;

\ interpretpad ( -- ) interpret the contents of the pad
: interpretpad  0 >in W!
begin bl parseword
	if pad>in nextword find dup
		if dup -1 = 
			if drop compile? if w, else execute then 0
			else 2 = 
				if execute 0 else
					compile? if execute 0 else pfa>nfa ." IMMEDIATE WORD " .strname clearkeys cr -1 then
				then
			then
		else drop dup C@++  fisnumber
			if
				C@++ fnumber compile? if dup 0 FFFF between if $C_a_litw w, w, else $C_a_litl w, l, then then 0
			else  
				1 state andnC! freedict _udf .strname cr clearkeys -1
			then
		then
	else -1 then until ;

\ interpret ( -- ) the main interpreter loop
: interpret pad padsize accept drop interpretpad ;

\ _wc1 ( x -- nfa ) skip blanks parse the next word and create a constant, allocate a word, 2 bytes
: _wc1 lockdict create $C_a_doconw w, w, forthentry lastnfa freedict ;

\ wconstant ( x -- ) skip blanks parse the next word and create a constant, allocate a word, 2 bytes
: wconstant _wc1 drop ;

\ wvariable ( -- ) skip blanks parse the next word and create a variable, allocate a word, 2 bytes 
: wvariable lockdict create $C_a_dovarw w, 0 w, forthentry freedict ;

\ asmlabel ( x -- ) skip blanks parse the next word and create an assembler entry
: asmlabel lockdict create w, freedict ;

\ hex ( -- ) set the base for hexadecimal
: hex 10 base W! ;

\ decimal ( -- ) set the base for decimal
: decimal A base W! ;

\ _words ( cstr -- ) prints the words in the forth dictionary starting with cstr, 0 prints all
: _words 0 >r lastnfa ." NFA (Forth/Asm Immediate eXecute) Name"
begin
	2dup swap dup if npfx else 2drop -1 then
	if
		r> dup 0= if cr then 1+ 3 and >r
		dup .addr space dup C@ dup 80 and
		if 46 else 41 then emit dup 40 and
		if 49 else 20 then  emit 20 and
		if 58 else 20 then emit
		space dup .strname dup C@ namemax and 15 swap - 0 max spaces
	then nfa>next dup 0=
until r> 3drop cr ;

\ words ( -- ) prints the words in the forth dictionary, if the pad has another string following, with that prefix
: words parsenw _words ;

\ delms ( n1 -- ) for 80Mhz 68DB max
: delms 7FFFFFFF clkfreq 3e8 u/ u/ min 1 max clkfreq 3E8 u/ u* cnt COG@ + begin dup cnt COG@ - 0< until drop ;
: delsec 10 u/mod dup if 0 do 3e80 delms loop else drop then dup if 0 do 3e8 delms loop else drop then ;

\ >m ( n1 -- n2 ) produce a 1 bit mask n2 for position n
: >m 1 swap lshift ;

\ pinin ( n1 -- ) set pin # n1 to an input
: pinin >m invert dira COG@ and dira COG! ;

\ pinout ( n1 -- ) set pin # n1 to an output
: pinout >m dira COG@ or dira COG! ;

\ pinlo ( n1 -- ) set pin # n1 to lo
: pinlo >m _maskoutlo ;

\ pinhi ( n1 -- ) set pin # n1 to hi
: pinhi >m _maskouthi ;

\ px ( t/f n1 -- ) set pin # n1 to h - true or l false
: px swap if pinhi else pinlo then ;

\ eeprom read and write routine for the prop proto board AT24CL256 eeprom on pin 28 sclk, 29 sda

: _sdai 1D pinin ;
: _sdao 1D pinout ;
: _scli 1C pinin ;
: _sclo 1C pinout ;

: _sdal 20000000 _maskoutlo ;
: _sdah 20000000 _maskouthi ;
: _scll 10000000 _maskoutlo ;
: _sclh 10000000 _maskouthi ;
: _sda? 20000000 _maskin ;

\ _eestart ( -- ) start the data transfer
: _eestart _sclh _sclo _sdah _sdao _sdal _scll ;

\ _eestop ( -- ) stop the data transfer
: _eestop _sclh _sdah _scll _scli _sdai ;

\ _eewrite ( c1 -- t/f ) write a byte to the eeprom, returns ack bit
: _eewrite 80 8 0
do 2dup and if _sdah else _sdal then _sclh _scll 1 rshift loop
2drop _sdai _sclh _sda? _scll _sdal _sdao ;

\ eewritepage ( eeAddr addr u -- t/f ) return true if there was an error, use lock 1
: eewritepage  begin 1 lockset 0= until
1 max rot dup ff and swap dup 8 rshift ff and swap 10 rshift 7 and 1 lshift
_eestart A0 or _eewrite swap _eewrite or swap _eewrite or
rot2 bounds
do i C@ _eewrite or loop _eestop 10 delms 1 lockclr drop ;

\ EW! ( n1 eeAddr -- )
: EW! swap t0 W! t0 2 eewritepage if 8003 ERR then ;

\ \ ( -- ) moves the parse pointer >in to the end of the line
: \ padsize >in W! ; immediate exec

\ { ( -- ) discard all the characters between { and }
\ open brace MUST be the first and only character on a new line, the close brace must be on another line
\ does not work in compile mode
: { begin fkey? drop 7D = until ;
: } ;

\ [if xxx   ( -- ) if xxx is defined drop all characters until ], [if xxx not have any characters following it on the line
: [if parsenw nip find if begin fkey? drop 5D = until then ;
: ] ;	


\ ' ( -- addr ) returns the execution token for the next name, if not found it returns 0
: ' parsebl if pad>in nextword find 0= if _udf cr drop 0 then else 0 then ;

\ cq ( -- addr ) returns the address of the counted string following this word and increments the IP past it
: cq r> dup C@++ + alignw >r ; 

\ c" ( -- c-addr ) compiles the string delimited by ", runtime return the addr of the counted string ** valid only in that line
: c" compile? if $H_cq _sp else 22 parse 1- pad>in 2dup C! swap 2+ >in W+! then ; immediate exec 

\ one fast load at a time
wvariable fl_lock
wvariable fl_in

\ (flout)  ( -- ) attempt to output a character
: (flout) io 2+ W@ dup W@ 100 and dictend W@ fl_in W@ < and if  dictend W@ dup 1+ dictend W! C@ swap W! else drop then ;

\ (fl) ( --) buffer input and emit
: (fl)
\
\ t0 - the end of the buffer
\ fl_in - pointer to next character for input
\ dictend - pointer to the next character for output
\ initialize
	dictend W@ 2- t0 W! here W@ 80 + dup fl_in W! dictend W!
\ process the input stream
\ ( timeoutcount beginning_of_line_flag -- )
	_wkeyto W@ -1 begin
		fkey? 0= if drop (flout) else
			begin
\ check to see if the buffer is overflowed?
				fl_in W@ t0 W@ >= if 8004 ERR else
				swap if
\ beginning of the line, comment or { ?
					dup 5C = if drop begin fkey? drop D = until -1 else
					dup 7b = if
						drop 0 begin 1+ 1f over and 1f = if (flout) then fkey? drop 7D = until
						drop 0 
					else
						dup fl_in W@ dup 1 + fl_in W! C! D = 
					then then
				else
\ process the char
					dup fl_in W@ dup 1 + fl_in W! C! D =
				then then
\ next key
			(flout) fkey? 0= until
\ reset the timeout counter
		drop nip _wkeyto W@ swap
		then
\ decrease the timeout counter
		swap 1- swap over 0=
	until 2drop
\ output any remain chars
	dictend W@ fl_in W@ < if fl_in W@ dictend W@ do i dup C@ emit dictend W! loop then
\ make sure we terminate any line
	d emit d emit
\ restore dictend
	t0 W@ 2+ dictend W! 
;

\ fl ( -- ) buffer the input and route to a free cog
: fl lockdict fl_lock W@ if freedict else -1 fl_lock W! cogid nfcog iolink freedict
	(fl)
	cogid iounlink
0 fl_lock W! then ;

\ saveforth( -- ) write the running image to eeprom UPDATES THE CURRENT VERSION STR
: saveforth 
c" here" find
if
	version W@ dup C@ + dup C@ 1+ swap C!
	pfa>nfa here W@ swap
	begin dup W@ over EW! 2+ dup 3F and 0= until
	do
		ibound i - 40 min dup i dup rot 
		eewritepage if 8003 ERR then 2e emit
	+loop	 
else drop then cr ;


\ this word is what the IP is set to on a reboot
\ fstart ( -- ) the start word
: fstart
\ set up the reset register for the cog
io 10 lshift $H_entry 2 lshift or cogid or _resetdreg COG!

\ if the cog terminated abnormally, the hi bit of the first word will be 0, normally processed by onreset
io W@ 

\ set up the cogs IO
100 io W!
\ 0 io 2+ W!

\ initialiaze the debug variable
_fmask COG@ debugcmd W!

\ zero out cog data area
par COG@ 8 + _cdsz 8 - 0 fill

\ initialize forth variables
hex $C_varend coghere W!

\ initiliaze the common variables
lockdict _finit W@ 0= 
if 
	0 fl_lock W!
\ initialize and then run onboot
	-1 _finit W!
	freedict
	c" onboot" find drop execute
else
	freedict
then

\ set the return stack to the top
_rstop 1- _rsptr COG!

\ execute onresetX (X is cogid) if it exists, otherwise execute onreset
c" onreset" tbuf ccopy cogid tbuf cappendn tbuf find if
	execute 
else 
	drop
	c" onreset" find drop execute
then

\ THE MAIN LOOP
begin compile? 0= if prop W@ .cstr propid W@ . ." Cog" cogid . ." ok" cr then interpret 0 until ;

\ (cog+) ( -- ) add a forth cog
: (cog+) 8 0 do i cogstate C@ 0= if i cogreset leave then loop ;

\ starserialcog ( n1 n2 n2 n4 -- ) 
\ n1 - rx pin
\ n2 - tx pin
\ n3 - baud rate
\ n4 - cog
: startserialcog dup >r
\ stop the cog and 0 out the cog data area
	dup cogstop cogio
\ set the parameters for the serial driver in the cog data area
	swap clkfreq swap u/ over L! 4+ swap >m over L! 4+ swap >m swap L!
\ set the string for what kind of cog this is
	r> dup cogstate 10 swap C! c" SERIAL" over cognumpad ccopy
\ restart the cog
	dup cogio 10 lshift $H_serentry 2 lshift or or 2 hubop 2drop
;


\
\ THE DEFAULT INITIALIZATION WORDS, onboot and on reset must exist
\ onboot ( n1 -- n1 ) n1 - reset error code 
: onboot (version) version W! (prop) prop W! 1e 1f E100 7 startserialcog cogid >con
	(cog+) (cog+) (cog+) (cog+) (cog+) (cog+) ;

\ onreset ( n -- )
\ FF11 - stack overflow
\ FF12 - return stack overflow
\ FF21 - stack underflow
\ FF22 - return stack underflow
\ 8001 - no more free forth cogs
\ 8002 - out of dictionary memory
\ 8003 - eeprom write error
\ 8004 - out of memory during an fl (fastload)
\ 8000 - FFFF other errrors

\ onreset ( n1 -- ) n1 - reset error code
: onreset 4 state orC! cr dup 8000 and if .addr else drop then ."  RESET " ;

\ wlastnfa is generated by spinmaker
