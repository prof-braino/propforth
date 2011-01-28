fl

fswrite propforth.f

hex

1 wconstant build_propforth

\ Copyright (c) 2010 Sal Sanci
\ 
\ These words are all optional words.
\


\ a cog special register
[if ctra
1F8	wconstant ctra ]

\ a cog special register
[if ctrb
1F9	wconstant ctrb ]

\ a cog special register
[if frqa
1FA	wconstant frqa ]

\ a cog special register
[if frqb
1FB	wconstant frqb ]

\ a cog special register
[if phsa
1FC	wconstant phsa ]

\ a cog special register
[if phsb
1FD	wconstant phsb ]

\ a cog special register
[if vcfg
1FE	wconstant vcfg ]

\ a cog special register
[if vscl
1FF	wconstant vscl ]

\ this word needs to align with the assembler code
[if _faddrmask
: _faddrmask 1 _cv ; ]

\ this word needs to align with the assembler code
[if _flongmask
: _flongmask 2 _cv ; ]

\ this word needs to align with the assembler code
[if _stptr
: _stptr 5 _cv ; ] 

\ this word needs to align with the assembler code
[if _sttos
: _sttos 7 _cv ; ]

\ this word needs to align with the assembler code
[if _treg1
: _treg1 8 _cv ; ]

\ this word needs to align with the assembler code
[if _treg2
: _treg2 9 _cv ; ]

\ this word needs to align with the assembler code
[if _treg3
: _treg3 a _cv ; ]

\ this word needs to align with the assembler code
[if _treg4
: _treg4 b _cv ; 

\ this word needs to align with the assembler code
[if _treg5
: _treg5 c _cv ; ]

\ this word needs to align with the assembler code
[if _treg6
: _treg6 d _cv ; ]

\ this word needs to align with the assembler code
[if _stbot
: _stbot e _cv ; ]

\ this word needs to align with the assembler code
[if _sttop
: _sttop 2e _cv ; ]

\ this word needs to align with the assembler code
[if _rsbot
: _rsbot _sttop ; ]

\ .long ( n -- ) emit 8 hex digits
[if .long
: .long dup 10 rshift .word .word ; ]

\ st? ( -- ) prints out the stack
[if st?
: st? ." ST: " _stptr COG@ 2+ dup _sttop < if _sttop swap - 0 do _sttop 2- i -  COG@ .long space loop else drop then cr ;
]

\ sc ( -- ) clears the stack
[if sc
: sc _sttop _stptr COG@ - 3 - dup . ." items cleared" cr dup 0> if 0 do drop loop then ; ]

\ _pna ( addr -- ) print the address, contents and forth name
[if _pna
: _pna dup .word 3a emit W@ dup .word space pfa>nfa .strname space ; ]

\ pfa? ( addr -- t/f) true if addr is a pfa 
[if pfa?
: pfa? dup pfa>nfa dup C@ dup 80 and 0= swap namemax and 0<> rot nfa>pfa rot if W@ then rot = and ; ]

\ rs? ( -- ) prints out the return stack
[if rs?
: rs? ." RS: " _rstop _rsptr COG@ 1+ - 0 do _rstop 1- i - COG@ dup 2- W@ pfa? if 2- _pna else .long space then loop cr ;
]


\ aallot ( n1 -- ) add n1 to coghere, allocates space in the cog or release it, n1 is # of longs
[if aallot
: aallot coghere W+! coghere W@ par >= if 8005 ERR then ; ]

\ cog, ( x -- ) allocate 1 long in the cog and copy x to that location
[if cog,
: cog, coghere W@ COG! 1 aallot ; ]

\ lasm ( addr -- ) expects an address pointing to a structure in the following form
\ empty long, long upper address of the assembler routine, long lower address of the assembler routine
\ a series of longs which are the assembler codes

[if lasm
: lasm 4+ dup L@ swap 4+ swap over L@ dup coghere W! do 4+ dup L@ cog, loop drop ; ]


\ cogvariable ( -- ) skip blanks parse the next word and create a cog variable, allocate a long
[if cogvariable
: cogvariable coghere W@ _wc1 1 aallot ; ]

\ variable ( -- ) skip blanks parse the next word and create a variable, allocate a long, 4 bytes
[if variable
: variable lockdict create $C_a_dovarl w, 0 l, forthentry freedict ; ]

\ constant ( x -- ) skip blanks parse the next word and create a constant, allocate a long, 4 bytes
[if constant
: constant lockdict create $C_a_doconl w, l, forthentry freedict ; ]

\ abs ( n1 -- abs_n1 ) absolute value of n1
[if abs
: abs _execasm1>1 151 _cnip ; ]

\ andC! ( c1 addr -- ) and c1 with the contents of address
[if andC!
: andC! dup C@ rot and swap C! ; ]

\ !destination ( n1 n2 -- n1 ) set the d field of n1 with n2
[if !destination
: !destination _execasm2>1 0A9 _cnip ; ]

\ !instruction ( n1 n2 -- n1 ) set the i field of n1 with n2
[if !instruction
: !instruction _execasm2>1 0B1 _cnip ; ]

\ !source ( n1 n2 -- n1 ) set the s field of n1 with n2
[if !source
: !source _execasm2>1 0A1 _cnip ; ]

\ r@ ( -- n1 ) \ copy top of RS to stack
[if r@
: r@ _rsptr COG@ 2+ COG@ ; ]

\ px? ( n1 -- t/f) true if pin n1 is hi
[if px?
: px? >m _maskin ; ]

\ waitcnt ( n1 n2 -- n1 ) \ wait until n1, add n2 to n1
[if waitcnt
: waitcnt _execasm2>1 1F1 _cnip ; ]

\ waitpeq ( n1 n2 -- ) \ wait until state n1 is equal to ina anded with n2
[if waitpeq
: waitpeq _execasm2>0 1E0 _cnip ; ]

\ waitpne ( n1 n2 -- ) \ wait until state n1 is not equal to ina anded with n2
[if waitpne
: waitpne _execasm2>0 1E8 _cnip ; ]

\ locknew ( -- n2 ) allocate a lock, result is in n2, -1 if unsuccessful
[if locknew
: locknew -1 4 hubop -1 = if drop -1 then ; ]

\ lockret ( n1 -- ) deallocate a lock, previously allocated via locknew
[if lockret
: lockret 5 hubop 2drop ; ]

\ lasti? ( -- t/f ) true if this is the last value of i in this loop
[if lasti?
: lasti? _rsptr COG@ 2+ COG@ 1- _rsptr COG@ 3 + COG@ = ; ]

\ j ( -- n1 ) the second most current loop counter
[if j
: j _rsptr COG@ 5 + COG@ ; ]

\ jbound ( -- n1 ) the upper bound of j
[if jbound
: jbound _rsptr COG@ 4+ COG@ ; ]

\ lastj? ( -- t/f ) true if this is the last value of j in this loop
[if lastl?
: lastj? _rsptr COG@ 4+ COG@ 1- _rsptr COG@ 5 + COG@ = ; ]

\ setj ( n1 -- ) set the second most current loop counter
[if setj
: setj _rsptr COG@ 5 + COG! ; ]

\ parsenw ( -- cstr ) parse and move to the next word, str ptr is zero if there is no next word
[if parsenw
: parsenw parsebl if pad>in nextword else 0 then ; ]

\ padnw ( -- t/f ) move past current word and parse the next word, true if there is a next word
[if padnw
: padnw nextword parsebl ; ]

\ padclr ( -- )
[if padclr
: padclr begin padnw 0= until ; ]

\ padbl ( -- ) fills this cogs pad with blanks
[if padbl
: padbl pad padsize bl fill ; ]

\ cappendc ( c1 cstr -- ) append c1 the cstr
[if cappendc
: cappendc dup C@ 1+ over C! dup C@ + C! ; ]

\ cappendnc ( n cstr -- ) print the number n and append to cstr and then append a blank
[if cappendnc
: cappendnc swap <# #s #> over cappend bl swap cappendc ; ]

\ ctolower ( c1 -- c1 ) if c is A-Z converts it to lower case
[if ctolower
: ctolower dup 41 5A between if 20 or then ; ]

\ u*/mod ( u1 u2 u3 -- u4 u5 ) u5 = (u1*u2)/u3, u4 is the remainder. Uses a 64bit intermediate result.
[if u*/mod
: u*/mod rot2 um* rot um/mod ; ]

\ u*/ ( u1 u2 u3 -- u4 ) u4 = (u1*u2)/u3 Uses a 64bit intermediate result.
[if u*/
: u*/ rot2 um* rot um/mod nip ; ]


\ sign ( n1 n2 -- n3 ) n3 is the xor of the sign bits of n1 and n2 
[if sign
: sign xor 80000000 and ; ]

\ * ( n1 n2 -- n1*n2) n1 multiplied by n2
[if *
: * um* drop ; ]

\ */mod ( n1 n2 n3 -- n4 n5 ) n5 = (n1*n2)/n3, n4 is the remainder. Uses a 64bit intermediate result.
[if */mod
: */mod 2dup sign >r abs rot dup r> sign >r abs rot abs um* rot um/mod 
	r> if negate swap negate swap then ; ]

\ */ ( n1 n2 n3 -- n4 ) n4 = (n1*n2)/n3. Uses a 64bit intermediate result.
[if */
: */ */mod nip ; ]

\ /mod ( n1 n2 -- n3 n4 ) \ signed divide & mod  n4 = n1/n2, n3 is the remainder
[if /mod
: /mod 2dup sign >r abs swap abs swap u/mod r> if negate swap negate swap then ; ]

\ / ( n1 n2 -- n1/n2) n1 divided by n2
[if /
: / /mod nip ; ]


\ (forget) ( cstr -- ) wind the dictionary back to the word which follows - caution
[if (forget)
: (forget) dup
if
	find if
		pfa>nfa nfa>lfa dup here W! W@ wlastnfa W!
	else .cstr 3f emit cr then
else drop then ; ]

\ forget ( -- ) wind the dictionary back to the word which follows - caution
[if forget
: forget parsenw (forget) ; ]

\ eereset ( -- ) initialize the eeprom in case it is in a weird state
[if eereset
: eereset begin 1 lockset 0= until _eestart _sdah 9 0 do _sclh _scll loop _eestart _eestop 1 lockclr ; ]

\ _eeread ( t/f -- c1 ) read a byte from the eeprom, ackbit in, byte out
[if _eeread : _eeread _sdai 0 8 0 do 1 lshift _sclh _sda? _scll if 1 or then loop
swap if _sdah else _sdal then _sdao _sclh _scll _sdal ; ]

\ the eereadpage and eewritePage words assume the eeprom are 64kx8 and will address up to 
\ 8 sequential eeproms
\ eereadpage ( eeAddr addr u -- t/f ) return true if there was an error, use lock 1
[if eereadpage : eereadpage begin 1 lockset 0= until
1 max rot dup ff and swap dup 8 rshift ff and swap 10 rshift 7 and 1 lshift dup >r
_eestart A0 or _eewrite swap _eewrite or swap _eewrite or
_eestart r> A1 or _eewrite or
rot2 bounds
do lasti? _eeread i C! loop _eestop 1 lockclr drop ; ]

\ EW@ ( eeAddr -- n1 )
[if EW@
: EW@ t0 2 eereadpage if 8006 ERR then t0 W@ ; ]

\ EC@ ( eeAddr -- c1 )
[if EC@
: EC@ EW@ FF and ; ]

\ eecopy ( addr1 addr2 u -- ) copy u bytes from addr1 to addr2, addr1 and addr2 must be on a 0x40 byte page boundary
\ clears the pad, so make sure no commands follow
\ and u must be a multiple of 0x40 and should not overlap
[if eecopy
: eecopy 3F invert and rot 3f invert and rot 3f invert and rot
0 do over i + dup . pad 40 eereadpage if 8006 ERR then
dup i + dup .  pad 40 eewritepage if 8003 ERR then
i 3FF and 0= if cr then 40 +loop 2drop pad padsize bl fill ; ]

\ [if (dumpb)
: (dumpb) cr over .addr space dup .addr _ecs bounds ; ]

\ [if (dumpm)
: (dumpm) cr .addr _ecs ; ]

\ [if (dumpe)
: (dumpe) tbuf 10 bounds do i C@ .bvalue space loop 2 spaces tbuf 10 bounds do i C@ dup bl < if drop 2e then emit loop ; ]

\ \ dump  ( adr cnt -- ) uses tbuf
[if dump
: dump  (dumpb) do i  (dumpm) i tbuf 10 cmove  (dumpe) 10 +loop cr ; ]

\ edump  ( adr cnt -- ) uses tbuf
[if edump
: edump  (dumpb) do i  (dumpm) i tbuf 10 eereadpage if tbuf 10 0 fill then  (dumpe) 10 +loop cr ; ]

\ cogdump  ( adr cnt -- )
\ [if cogdump
: cogdump cr over .addr space dup .addr _ecs bounds
do cr i .addr _ecs i 4 bounds do i COG@ .value space loop 4 +loop cr ; ]

\ #C ( c1 -- ) prepend the character c1 to the number currently being formatted
[if C#
: #C -1 >out W+! pad>out C! ; ]

\ .cogch ( n1 n2 -- ) print as x(y)
[if .cogch
: .cogch <# 29 #C # 28 #C drop # #> .cstr ; ]

\ cog? ( -- )
\ [if cog?
: cog? 8 0 do ." Cog:" i dup . ."  #io chan:" dup cognchan . cogstate C@ 
	dup 4 and if version W@ .cstr then
	dup 10 and if i cognumpad version W@ C@ over C@ - spaces .cstr then
	14 and if i cogio i cognchan 0 do
		i 4* over + 2+ W@ dup 0= if drop else
			space space j i .cogch ." ->" io>cogchan .cogch 
		then
	loop
drop then cr loop ; ]

\ free ( -- ) display free main bytes and current cog longs
[if free
: free dictend W@ here W@ - . ." bytes free - " par coghere W@ - . ." cog longs free" cr ; ]

\ cog+ ( -- ) add a forth cog
[if cog+
: cog+ (cog+) cog? ; ]


\ (cog-) ( -- ) stop first forth cog, cannot be executed form the first forth cog 
[if (cog-)
: (cog-) nfcog cogstop ; ]

\ cog- ( -- ) stop first forth cog, cannot be executed form the first forth cog 
[if cog-
: cog- (cog-) cog? ; ]

\ st? ( -- ) prints out the stack
\ [if st?
: st? ." ST: " _stptr COG@ 2+ dup _sttop < if _sttop swap - 0 do _sttop 2- i -  COG@ .value space loop else drop then cr ;
]

\ sc ( -- ) clears the stack
[if sc
: sc _sttop _stptr COG@ - 3 - dup . ." items cleared" cr dup 0> if 0 do drop loop then ; ]

\ _pna ( addr -- ) print the address, contents and forth name
\ [if _pna
: _pna dup .addr 3a emit W@ dup .addr space pfa>nfa .strname space ; ]

\ pfa? ( addr -- t/f) true if addr is a pfa 
[if pfa?
: pfa? dup pfa>nfa dup C@ dup 80 and 0= swap namemax and 0<> rot nfa>pfa rot if W@ then rot = and ; ]

\ rs? ( -- ) prints out the return stack
\ [if rs?
: rs? ." RS: " _rstop _rsptr COG@ 1+ - 0 do _rstop 1- i - COG@ dup 2- W@ pfa? if 2- _pna else .value space then loop cr ;
]


\ these routine will output to the console, they will not block, so characters may drop in the case of collisions
 
\ .conemit ( c1 -- ) emit cr to console, will timeout, 80MHZ cog 57.6Kb console, should keep up
[if .conemit
: .conemit state W@ 2 and 0= if con cogio 200 0 do dup W@ 100 and if leave then loop W! else drop then ; ]

\ .concstr ( cstr -- ) emit cstr to console
[if .concstr
: .concstr C@++ dup if bounds do i C@ .conemit loop else 2drop then ; ]

\ .con ( n1 -- ) print n1 to the console to console
[if .con
: .con <# #s #> .concstr bl .conemit ; ]

\ .concr ( -- ) emit a cr to the console
[if .concr
: .concr D .conemit _crf W@ if A .conemit then ; ]

: .conbvalue <# # # # #> .concstr ;
: .conaddr <# # # # # # # #> .concstr ;
: .convalue <# # # # # # # # # # # # #> .concstr ;

\ .const? ( -- ) prints out the stack
[if .const?
: .const? c" ST: " .concstr _stptr COG@ 2+ dup _sttop < if _sttop swap - 0 do _sttop 2- i -  COG@
.convalue bl .conemit loop else drop then .concr ;
]

\
\ Noisy boot messages - only appear if you do a saveforth
\
\ print out a boot message
[if (rbm)

: (rbm) state W@ 2 and 0= if lockdict .concr prop W@ .concstr propid W@ .con
c" PROP REBOOT " .concstr version W@ .concstr .concr freedict then ;

\ connect this cog to the console, print a reboot message if the .conf flag is true
\ set the forth cogs

: _ob onboot ;
: onboot _ob (rbm)  ;

]



\
\ Noisy reset messages
\
\ print out a reset message to the console
\ (rsm) ( n -- ) n is the last status
\ 0011FFFF - stack overflow
\ 0012FFFF - return stack overflow
\ 0021FFFF - stack underflow
\ 0022FFFF - return stack underflow
\ 8100FFFF - no free cogs
\ 8200FFFF - no free main memory
\ 8400FFFF - fl no free main memory
\ 8500FFFF - no free cog memory
\ 8800FFFF - eeprom write error
\ 9000FFFF - eeprom read error

[if (rsm)
: (rsm) state W@ 2 and 0= swap
\ process the last status
	dup 0= if c" ok" else
	dup FF11 = if c" MAIN STACK OVERFLOW" else
	dup FF12 = if c" RETURN STACK OVERFLOW" else
	dup FF21 = if c" MAIN STACK UNDERFLOW" else
	dup FF22 = if c" RETURN STACK UNDERFLOW" else
	dup 8001 = if c" OUT OF FREE COGS" else
	dup 8002 = if c" OUT OF FREE MAIN MEMORY" else
	dup 8003 = if c" EEPROM WRITE ERROR" else
	dup 8004 = if c" FL OUT OF FREE MAIN MEMORY" else
	dup 8005 = if c" OUT OF FREE COG MEMORY" else
	dup 8006 = if c" EEPROM READ ERROR" else
		c" UNKNOWN ERROR "
	thens
	rot if
		lockdict .concr prop W@ .concstr propid W@ .con c" Cog" .concstr cogid .con
		c" RESET - last status: " .concstr swap .con .concstr .concr freedict
	else 2drop then ;

: onreset (rsm) 4 state orC!  ;
]

\ rnd ( -- n1 ) n1 is a random number from 00 - FF
[if rnd
: rnd cnt COG@ 8 rshift cnt COG@ xor FF and ; ]

\ rndtf ( -- t/f) true or false randomly
[if rndtf
: rndtf rnd 7f > ; ]

\ rndand ( n1 -- n2) n2 is randomly n1 or 0
[if rndand
: rndand rnd 7f > and ; ]

\ _cfo ( n1 -- n2 ) n1 - desired frequency, n2 freq a 
[if _cfo
: _cfo clkfreq 1- min 0 swap clkfreq um/mod swap clkfreq 2/ >= abs + ; ]

\ setHza ( n1 n2 -- ) n1 is the pin, n2 is the freq, uses ctra
\ set the pin oscillating at the specified frequency
[if setHza
: setHza _cfo frqa COG! dup pinout 10000000 + ctra COG! ; ]

\ qHzb ( n1 n2 -- n3 ) n1 - the pin, n2 - the # of msec to sample, n3 the frequency
[if qHzb
: qHzb
	swap 28000000 + 1 frqb COG! ctrb COG!
	3000 min clkfreq over 3e8 u*/ 310 - phsb COG@ swap cnt COG@ + 0 waitcnt
	phsb COG@ nip swap - 3e8 rot u*/ ; ]

\ setHzb ( n1 n2 -- ) n1 is the pin, n2 is the freq, uses ctrb
\ set the pin oscillating at the specified frequency
[if setHzb
: setHzb _cfo frqb COG! dup pinout 10000000 + ctrb COG! ; ]

\ crcl ( -- ) cr and clear the line (for an ansi terminal)
[if crcl
: crcl cr 1b emit 5b emit 4b emit ; ]

\ a simple terminal which interfaces to the a channel
\ term ( n1 n2 -- ) n1 - the cog, n2 - the channel number
[if term
: term over cognchan min
	." Hit CTL-F to exit term" cr
	>r >r cogid 0 r> r> (iolink)
	begin key dup 6 = if drop 1 else emit 0 then until
	cogid iounlink ;
]

\ ee>image ( addr n1 -- ) addr - the address to start producing an image from, must be a multiple of 64,
\	n1 - count of bytes to produce, must be a multiple of 64
[if ee>image
: ee>image 3f andn swap 3f andn swap dup if
	bounds do
		i pad 40 eereadpage if 90 ERR then
		pad 40 bounds do i dup pad 20 + = if cr then L@ . 4 +loop i . ." image>ee" cr
	40 +loop
then padbl ; ]

\ image>ee ( n1 - n16 addr -- ) writes the 16 longs on the stack to the addr in eeprom
[if image>ee
: image>ee >r pad 3C + 40 0 do swap over i - L! 4 +loop drop r> pad 40 eewritepage if 8003 ERR then padbl ; ]


...

