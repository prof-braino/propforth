fl

fswrite norom.f

hex

: build_norom ;

\
\ An eeprom free boot for the slave, the master prop emulates the eeprom
\ and sends it's eeprom image, or a ram image
\
\
\ Status: working - Alpha
\
\
\ Prototype - the master is a propeller protoboard @ 5 MHZ with a 64kx8 rom
\ (should be ok with a demo board and 32kx8 eeprom
\
\ add a prop chip, used a 40 pin dip
\ ran power and ground 2 0.1 uF caps between the power and ground pins, close to the chip
\
\ 10k pullup resistor on  IO 29 - the pin normally hookup up to sda on the eeprom
\
\ Protoboard			Prop Chip	
\ IO 8 	-> 220 ohm resistor 	-> IO 28 (this pin normally hooks up to scl on the eeprom)
\ IO 9 	-> 220 ohm resistor 	-> IO 29 (this pin normally hooks up to sda on the eeprom, 10k pullup resistor as well)
\ IO 10	->			-> RESET
\ IO 11 ->			-> XI

\ this is a serial port connection so we can talk to PropForth on the Prop Chip
\
\ IO 0	->			-> IO 30
\ IO 1	->			-> IO 31
\


\
{
\ hook up the chip, load this file, define these words, run demo

fl
: bootslave 8 9 A B rambootnx ;
: demo bootslave 1 0 e100 4 startserialcog 10 delms 4 0 term ;

\ 4 0 term - will connect again after demo is run

}


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

\ variable ( -- ) skip blanks parse the next word and create a variable, allocate a long, 4 bytes
[if variable
: variable lockdict create $C_a_dovarl w, 0 l, forthentry freedict ; ]

\ aallot ( n1 -- ) add n1 to coghere, allocates space in the cog or release it, n1 is # of longs
[if aallot
: aallot coghere W+! coghere W@ par >= if 8500 ERR then ; ]

\ cog, ( x -- ) allocate 1 long in the cog and copy x to that location
[if cog,
: cog, coghere W@ COG! 1 aallot ; ]

\ lasm ( addr -- ) expects an address pointing to a structure in the following form
\ empty long, long upper address of the assembler routine, long lower address of the assembler routine
\ a series of longs which are the assembler codes

[if lasm
: lasm 4+ dup L@ swap 4+ swap over L@ dup coghere W! do 4+ dup L@ cog, loop drop ; ]

\ abs ( n1 -- abs_n1 ) absolute value of n1
[if abs
: abs _execasm1>1 151 _cnip ; ]

\ waitcnt ( n1 n2 -- n1 ) \ wait until n1, add n2 to n1
[if waitcnt
: waitcnt _execasm2>1 1F1 _cnip ; ]

\ _cfo ( n1 -- n2 ) n1 - desired frequency, n2 freq a 
[if _cfo
: _cfo clkfreq 1- min 0 swap clkfreq um/mod swap clkfreq 2/ >= abs + ; ]

\ u*/mod ( u1 u2 u3 -- u4 u5 ) u5 = (u1*u2)/u3, u4 is the remainder. Uses a 64bit intermediate result.
[if u*/mod
: u*/mod rot2 um* rot um/mod ; ]

\ u*/ ( u1 u2 u3 -- u4 ) u4 = (u1*u2)/u3 Uses a 64bit intermediate result.
[if u*/
: u*/ rot2 um* rot um/mod nip ; ]

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

\ a simple terminal which interfaces to the a channel
\ term ( n1 n2 -- ) n1 - the cog, n2 - the channel number
[if term
: term over cognchan min
	." Hit CTL-F to exit term" cr
	>r >r cogid 0 r> r> (iolink)
	begin key dup 6 = if drop 1 else emit 0 then until
	cogid iounlink ;
]


18D asmlabel a_ram
162 asmlabel a_rom
152 wconstant v_sdata
151 wconstant v_sclk
150 wconstant v_mdata
14F wconstant v_mclk
lockdict variable def_rom 01A6 l, 014F l,
0 l, 0 l, 0 l, 0 l, 00008000 l, F03EA351 l, F03EA552 l, F43EA552 l, F43EA351 l, 5C7C0000 l,
A0FE1C08 l, F03EA351 l, F43EA351 l, E4FE1D5A l, 68BFED52 l, F03EA351 l, F43EA351 l, 64BFED52 l, 5C7C0000 l, 68BFE94F l,
68BFED4F l, 64BFED50 l, 64BFE950 l, 64BFED51 l, 64BFED52 l, 64BFE952 l, 5CFEB154 l, 5CFEC359 l, 5CFEC359 l, 5CFEC359 l,
5CFEB154 l, 5CFEC359 l, A0BE1D53 l, A0FE1A08 l, A0FE1810 l, E4FE1972 l, 613EA1F2 l, 74BFED52 l, F03EA351 l, 68BFE94F l,
F43EA351 l, 64BFE94F l, E4FE1B71 l, 68BFED50 l, 64BFED52 l, F03EA351 l, 68BFE94F l, F43EA351 l, 64BFE94F l, 64BFED50 l,
E4FE1D70 l, 64BFED52 l, 68BFED50 l, F03EA351 l, 68BFE94F l, F03EA552 l, 64BFED50 l, A0FE1900 l, E4FE1989 l, 64BFED4F l,
64BFE94F l, 5C7C0075 l, 64BFED51 l, 64BFED52 l, 64BFE952 l, 5CFEB154 l, 5CFEC359 l, 5CFEC359 l, 5CFEC359 l, 5CFEB154 l,
5CFEC359 l, A0BE1D53 l, A0FE1200 l, 00BE1509 l, 80FE1201 l, A0FE1A08 l, 617E1480 l, 2CFE1401 l, 74BFED52 l, F03EA351 l,
F43EA351 l, E4FE1B9B l, 64BFED52 l, F03EA351 l, F43EA351 l, E4FE1D98 l, 5C7C0075 l,
freedict

wvariable (rb04s) 0 (rb04s) W!

\ (rb1) ( n1 n2 n3 -- n1 n3 )  n1 - the pin connected to the slave sclk, n2 - the pin connected to the slave sda,
\  n3 the pin connected to the slave reset, boot the slave and load it with and image of our eeprom
\ load assembler, and initialize pins
: (rb1) def_rom lasm swap  >m v_sdata COG! over >m v_sclk COG! ;

\ (rb2) ( n1 -- )  pulse pin n1 lo fro 1 ms (reset)
: (rb2) dup pinlo dup pinout 1 delms dup pinhi pinin ;

\ (rb3) ( n1 -- ) send a signal on pin n1 indicating we are the master
: (rb3) dup 97000 setHza 100 delms 0 ctra COG! pinin ;


\ romboot ( n1 n2 n3 -- ) n1 - the pin connected to the slave sclk, n2 - the pin connected to the slave sda,
\  n3 the pin connected to the slave reset, boot the slave and load it with and image of our eeprom
: romboot
\ lock the eeprom so no one else can use it
	begin 1 lockset 0= until
\ load assembler, and initialize pins
	(rb1) 1C >m v_mclk COG! 1D >m v_mdata COG!
\ set up the eeprom for sequential reads from address 0
	0 dup ff and swap 8 rshift ff and _eestart A0 _eewrite drop _eewrite drop _eewrite drop 
	_eestart A1 _eewrite drop
\ reset, and do assembler eeprom emulator
	(rb2) a_rom
\ free the lock on the eeprom
	1 lockclr
\ send 97000  (618496 decimal) hz for 10 ms  to the slave on the slave's scl line to let it know we are the master 
	(rb3) ;

\ ramboot ( n1 n2 n3 -- ) n1 - the pin connected to the slave sclk, n2 - the pin connected to the slave sda,
\  n3 the pin connected to the slave reset, boot the slave and load it with and image of our ram
: ramboot
\ load assembler, and initialize pins
	(rb1)
\ reset, and do assembler eeprom emulator
	(rb2) a_ram
\ send 97000  (618496 decimal) hz for 10 ms  to the slave on the slave's scl line to let it know we are the master 
	(rb3) ;

\ rambootnx ( n1 n2 n3 n4 -- )  n1 - the pin connected to the slave sclk, n2 - the pin connected to the slave sda,
\  n3 the pin connected to the slave reset, n4 is the pin to use as a clock output
\ boot the slave and load it with and image of our ram
: rambootnx
\ set the clkmode to pll16 xin, if someone else has not already
	lockdict (rb04s) 1+ dup C@ dup 1+ rot C! 0= if 4 C@ (rb04s) C! 67 4 C! then freedict
\ set the clock out to be our clock / 16
	0 L@ 4 rshift setHzb
\ boot from ram
	ramboot
\ reset the clkmode to pll16 xin, if someone else has not already
	lockdict (rb04s) 1+ dup C@ 1- dup rot C! 0= if (rb04s) C@ 4 C! then freedict
;



: _ob onboot ;
: onboot _ob
\ get rid of any error code on the stack, not valid
	drop 0 
\ set the prompts assuming we are the master
	c" MASTERProp" prop W! 0 propid W!
	10 0 do
		1C 1 qHzb 96000 98000 between if
\ reset the prompts to slave prompts
			c"  SLAVEProp" prop W! 8 propid W!
			1 _finit andnC! leave
		then
	loop ;

 
{

fl

\ the assembler for the eeprom emulator
\
\


:asm
v_mclk
 0
v_mdata
 0
v_sclk
 0 
v_sdata
 0
__1_32k
 8000



\ wait for a start bit from the slave prop
__8slavewaitstart
		waitpeq	v_sclk	, v_sclk
		waitpeq	v_sdata	, v_sdata
		waitpne	v_sdata	, v_sdata		
		waitpne v_sclk	, v_sclk
__9slavewaitstartret
		ret


\ read a byte from the slave prop, give it an ack
__Aslavereadbyte
		mov	_treg6 	, # 8
__Flp
\ wait for a positive edge on the clock
		waitpeq v_sclk	, v_sclk
\ wait for a negative edge
		waitpne v_sclk	, v_sclk
		djnz	_treg6	, # __Flp

\ set the ack bit for the slave, master receives ack bit from eeprom (ignore)
		or	dira	, v_sdata
\ wait for a positive edge on the clock
		waitpeq v_sclk	, v_sclk
\ wait for a negative edge on the clock
		waitpne v_sclk	, v_sclk
\ release the ack bit for the slave
		andn	dira	, v_sdata
__Bslavereadbyteret
		ret


a_rom
		or	outa	, v_mclk
		or	dira	, v_mclk

		andn	dira	, v_mdata
		andn	outa	, v_mdata

		andn	dira	, v_sclk
		andn	dira	, v_sdata
		andn	outa	, v_sdata

\ wait for a start bit
		jmpret	__9slavewaitstartret , # __8slavewaitstart

\ read the start command and the address
		jmpret	__Breadbyteret , # __Aslavereadbyte
		jmpret	__Breadbyteret , # __Aslavereadbyte
		jmpret	__Breadbyteret , # __Aslavereadbyte

\ wait for a start bit
		jmpret	__9slavewaitstartret , # __8slavewaitstart
		jmpret	__Breadbyteret , # __Aslavereadbyte

\ read 32k bytes		
		mov	_treg6	, __1_32k
\	mov	_treg1	, # 0
__Flp
\	rdbyte	_treg2	, _treg1
\	add	_treg1	, # 1

		mov	_treg5	, # 8
__Elp
\ 3 instruction from the negative edge, give the data from the eeprom 600 ns to settle, so @ 80Mhz 12 instr @ 80 Mhz
\ 15 @ 96 Mhz minimum
\ delay (n + 2) * 4 clocks
		mov	_treg4	, # 10
__7lp
		djnz	_treg4	, # __7lp


\ read the data from the the master's eeprom and echo to the slave
		test	v_mdata , ina	wc
\	test	_treg2	, # 80 wc
\	shl	_treg2	, # 1
		muxnc	dira	, v_sdata

\ wait for a positive edge
		waitpeq	v_sclk	, v_sclk
		or	outa	, v_mclk

\ wait for a negative edge
		waitpne	v_sclk	, v_sclk
		andn	outa	, v_mclk

		djnz	_treg5	, # __Elp

\ set the ack bit for the master eeprom to 0
		or	dira	, v_mdata
		andn	dira	, v_sdata

\ wait for a positive edge
		waitpeq	v_sclk	, v_sclk
		or	outa	, v_mclk

\ wait for a negative edge
		waitpne	v_sclk	, v_sclk
		andn	outa	, v_mclk

\ set the ack bit for the master eeprom to 1
		andn	dira	, v_mdata

		djnz	_treg6	, # __Flp

\ ready to receive stop from slave, echo to masters eeprom
		andn	dira	, v_sdata
		or	dira	, v_mdata

\ wait for a positive edge
		waitpeq	v_sclk	, v_sclk
		or	outa	, v_mclk

		waitpeq	v_sdata	, v_sdata
		andn	dira	, v_mdata

\ delay (n + 2) * 4 clocks
		mov	_treg4	, # 100
__7lp
		djnz	_treg4	, # __7lp

		andn	dira	, v_mclk
		andn	outa	, v_mclk

		jnext




a_ram

		andn	dira	, v_sclk
		andn	dira	, v_sdata
		andn	outa	, v_sdata

\ wait for a start bit
		jmpret	__9slavewaitstartret , # __8slavewaitstart

\ read the start command and the address
		jmpret	__Breadbyteret , # __Aslavereadbyte
		jmpret	__Breadbyteret , # __Aslavereadbyte
		jmpret	__Breadbyteret , # __Aslavereadbyte

\ wait for a start bit
		jmpret	__9slavewaitstartret , # __8slavewaitstart
		jmpret	__Breadbyteret , # __Aslavereadbyte

\ read 32k bytes		
		mov	_treg6	, __1_32k
		mov	_treg1	, # 0
__Flp
		rdbyte	_treg2	, _treg1
		add	_treg1	, # 1

		mov	_treg5	, # 8
__Elp
\ read the data from the master's ram and echo to the slave
		test	_treg2	, # 80 wc
		shl	_treg2	, # 1
		muxnc	dira	, v_sdata

\ wait for a positive edge
		waitpeq	v_sclk	, v_sclk
\ wait for a negative edge
		waitpne	v_sclk	, v_sclk

		djnz	_treg5	, # __Elp

		andn	dira	, v_sdata

\ wait for a positive edge
		waitpeq	v_sclk	, v_sclk

\ wait for a negative edge
		waitpne	v_sclk	, v_sclk
		djnz	_treg6	, # __Flp

		jnext

;asm		


}


...

