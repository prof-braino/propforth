fl

fswrite com.f

hex

1 wconstant build_com


\ Copyright (c) 2010 Sal Sanci

\ A synchronous communication protocol between 2 props
\ only using 2 pins. Provide 8 full duplex I/O channels which can easily connect to forth io

\ Status: working - Beta

\ wire 2 pins from the master cog to the slave cog, they can be different pins
\ the pin defined as master pin on the master, must be connected to the the pin defined as master pin on the slave
\ the pin defined as slave  pin on the master, must be connected to the the pin defined as slave  pin on the slave
\ the reset pin is irrelevant for the communication, but is part of the structure, define as FF if unused

\ One cog on each propeller is used to drive the communication.

\ BOTH PROPS MUST BE AT THE SAME CLOCK SPEED

\ so assuming:
\	masterprop:	pin 14 - master pin (pin 20 in decimal)
\			pin 15 - slave pin  (pin 21 in decimal)
\	slaveprop:	pin 14 - master pin
\			pin 15 - slave pin

\ wire pin 14 of the master to pin 14 of the slave
\ wire pin 15 of the master to pin 15 of the slave
\ series resistor of 200 - 400 ohms are optional, they will prevent a short in case of software misconfiguration


\ SINGLE PROP EXAMPLE - because of a beautiful architecture the prop, you can run both channels on on prop chip
\ as a matter of fact, the code was developed and debugged this way, and can use LogicAnalyzer to look at the signals.
\ Hooking up 2 chips, it then worked without fuss.

\ The big differences we start a master cog and a slave cog running on one chip. For this example we will use 
\ cog 4 as the master cog and cog 5 as the slave cog


\ load this file, make sure you are connected to cog 6

\ If you want to use LogicAnalyzer to look at the signals

\ Load LogicAnalyzer then load this file

\ Define the 2 following routines
{

fl
: cominit
	c" 14 15 FF 3 commaster" 4 cogx
	c" 14 15 FF 3 comslave" 5 cogx
	100 delms
	0 0 5 0 (ioconn)
	1 0 5 1 (ioconn)
	2 0 5 2 (ioconn) ;

: comstat 4 cogio dup comcnt L@ . comerr L@ . 5 cogio dup comcnt L@ . comerr L@ . cr ;

}

\ This starts up cog 5 as the slave com cog, and connects cogs 0 - 2 to the slave cog
\ The master cog starts on cog 4, and connects to the master cog via pins 14 and 15

\ type:
\			cominit comstat
\			4 0 term 

\ this connects to the master cog, which communicates to the slave cog, which connects to cog 0

\			4 1 term 

\ this connects to the master cog, which communicates to the slave cog, which connects to cog 1



hex

\ variable ( -- ) skip blanks parse the next word and create a variable, allocate a long, 4 bytes
[if variable
: variable lockdict create $C_a_dovarl w, 0 l, forthentry freedict ; ]

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

\ px? ( n1 -- t/f) true if pin n1 is hi
[if px?
: px? >m _maskin ; ]

\ waitcnt ( n1 n2 -- n1 ) \ wait until n1, add n2 to n1
[if waitcnt
: waitcnt _execasm2>1 1F1 _cnip ; ]

\ abs ( n1 -- abs_n1 ) absolute value of n1
[if abs
: abs _execasm1>1 151 _cnip ; ]

\ sign ( n1 n2 -- n3 ) n3 is the xor of the sign bits of n1 and n2 
[if sign
: sign xor 80000000 and ; ]

\ */mod ( n1 n2 n3 -- n4 n5 ) n5 = (n1*n2)/n3, n4 is the remainder. Uses a 64bit intermediate result.
[if */mod
: */mod 2dup sign >r abs rot dup r> sign >r abs rot abs um* rot um/mod 
	r> if negate swap negate swap then ; ]

\ */ ( n1 n2 n3 -- n4 ) n4 = (n1*n2)/n3. Uses a 64bit intermediate result.
[if */
: */ */mod nip ; ]

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
	3000 min clkfreq over 3e8 */ 310 - phsb COG@ swap cnt COG@ + 0 waitcnt
	phsb COG@ nip swap - 3e8 rot */ ; ]

\ a simple terminal which interfaces to the a channel
\ term ( n1 n2 -- ) n1 - the cog, n2 - the channel number
[if term
: term over cognchan min
	." Hit CTL-F to exit term" cr
	>r >r cogid 0 r> r> (iolink)
	begin key dup 6 = if drop 1 else emit 0 then until
	cogid iounlink ;
]



1DB asmlabel a_slavecom
1D5 asmlabel a_mastercom
150 wconstant v_pinin
14F wconstant v_pinout
lockdict variable def_com 01E1 l, 014F l,
0 l, 0 l, 0 l, 0 l, 0 l, 0 l, 0 l, 0 l, A0FE1600 l, A0FE1C04 l,
28FEAC01 l, 28FE1608 l, 04BE1308 l, A0BE1509 l, 2CFE1218 l, 62FE1500 l, 68AA1709 l, 68EAAC80 l, 80FE1004 l, E4FE1D59 l,
5C7C0000 l, A0FEAC00 l, 5CFEC757 l, A0BEA90B l, 5CFEC757 l, A0BEAB0B l, 68BEAD53 l, A0BE1954 l, 6CBE1955 l, 6CBE1956 l,
6CFE1955 l, A0BE1B0C l, 28FE1A10 l, 6CBE190D l, 2CFE1810 l, 68BEAD0C l, 84FE1020 l, 5C7C0000 l, A0FE1C20 l, 613EA1F2 l,
34FE1601 l, 2DFE1A01 l, 70BFE94F l, E6FE1D76 l, 613EA1F2 l, 34FE1601 l, 5C7C0000 l, A0BE1B56 l, 5CFEFB75 l, A0BEA70B l,
A0BE1B55 l, 5CFEFB75 l, A0BEA50B l, A0BE1B54 l, 5CFEFB75 l, A0BEA30B l, 78BFE94F l, A0BE1D08 l, 80FE1C34 l, A0BE1951 l,
6CBE1952 l, 6CBE1953 l, 6CFE1955 l, A0BE1B0C l, 28FE1A10 l, 6CBE190D l, 2EFE1810 l, 08BE1B0E l, 80FE1A01 l, 083E1B0E l,
80FE1C04 l, A0D6A600 l, 08961B0E l, 80D61A01 l, 08161B0E l, A0FE1B00 l, A0BE1353 l, A0FE1C08 l, 627E1300 l, 04161B08 l,
28FE1201 l, 80FE1004 l, E4FE1D9D l, 84FE1020 l, 80FE1020 l, A0FE1A02 l, A0BE1951 l, A0FE1C04 l, A0BE170C l, 28FE1808 l,
29FEA601 l, 04B21308 l, 60FE16FF l, 627E1300 l, 04121708 l, 80FE1002 l, E4FE1DA7 l, A0BE1952 l, E4FE1BA6 l, 84FE1030 l,
A0BEAB08 l, 80FEAA02 l, A0FE1807 l, 2CFE1808 l, 80FE1020 l, A0FEA600 l, A0FE1B00 l, A0FEA300 l, A0BEA551 l, 2CFEA401 l,
A0BEA952 l, 2CFEA801 l, A0FE1C08 l, 04BE1708 l, 623E170C l, 5C5401CA l, 06BE1555 l, A0AA1754 l, 5C6801CA l, 04BE130A l,
623E1351 l, 0416170A l, A0961754 l, 623E1752 l, 0416A308 l, 623E1754 l, 0416A508 l, 6896A70D l, 2CFE1A01 l, 80FEAA04 l,
80FE1002 l, E4FE1DC0 l, 84FE1030 l, 5C7C0000 l, 5CFEE964 l, A2FE1201 l, 78BFE94F l, F43EA150 l, 5CFFA97E l, 5C7C01D5 l,
5CFEE964 l, A2FE1201 l, F43EA150 l, 78BFE94F l, 5CFFA97E l, 5C7C01DB l,
freedict



\ a_mastercom ( addr -- addr) addr - a pointer to a channel structure, MUST be long aligned
\ a_slavecom ( addr -- addr)
\ Channel structure
\ has 8 full duplex channels, with built in flow control, which can interface easily to forth cogs
\
\
\ 00 - 20 - 8 longs each representing a channel
\ 20 - 30 - 8 words, the recbuf, the bytes received by the channels are buffered here
\ 30 - byte, the master pin out
\ 31 - byte, the slave pin out
\ 32 - byte, the reset pin
\ 33 - byte, the state - used by domaster and doslave
\ 34 - long, a count of how many full duplex 96 bit exchanges there have been
\ 38 - long, a count of how many checksum errors there have been
\ 3C - long, a long used for debugging

\ the members of the structure
: comrecbuf 20 + ; : compinm@ 30 + C@ ; : compins@ 31 + C@ ; : compinm! 30 + C! ; : compins! 31 + C! ; : comreset@ 32 + C@ ;
: comreset! 32 + C! ; : comstate@ 33 + C@ ; : comstate! 33 + C! ;  : comcnt 34 + ; : comerr 38 + ;
\ : comdbg 3C + ;

\ (cominit) ( addr n1 n2 n3 -- addr ) addr - the channel structure address, n1 master pin n2 the slave pin, n3 is the reset pin
: (cominit)
	1F and 10 lshift swap 1F and 8 lshift or swap 1f and or over 30 + L!
	dup 20 bounds do 0100 i L! 4 +loop 
	dup comrecbuf 10 bounds do 01000100 i L! 4 +loop 
	dup comcnt 0 over L! 4+ 0 over L! 4+ 0 swap L! ;

\ base routines which synch and help determine if the master / slave is online
\
\ (comres) ( addr -- addr )
: (comres) dup compinm@ pinin dup compins@ pinin 0 over comstate! 0 ctra COG! 0 ctrb COG! ;

\ (comsynsm) ( addr -- addr ) send out the signal indicating we are the master
: (comsynsm) (comres) dup compins@ pinin dup compinm@ A7000 setHza ;

\ (comsynss) ( addr -- addr ) send out the signal indicating we are the slave
: (comsynss) (comres) dup compinm@ pinin dup compins@ 77000 setHza ;

\ (comsyncm) ( addr -- addr t/f ) check for a valid master signal
: (comsyncm) dup compinm@ 1 qHzb A6000 A8000 between ;

\ (comsyncs) ( addr -- addr t/f ) check for a valid slave signal
: (comsyncs) dup compins@ 1 qHzb 76000 78000 between ;

\ (comsyn )( addr -- addr ) auto negotiate communication, if this is used a 200 - 400 ohm resistor should be connected
\ in series with each of the com lines, ie master pin and slave pin, to limit current in the case of a collision
\ in the initial negotiation
: (comsyn)
	10000 0 do
		(comsynsm) 0 swap rndtf 8 and 8 + 0 do
			(comsyncs) if swap 1+ swap then
		loop
		swap 2 > if leave 2 over comstate!
		else
			(comsynss) 0 swap rndtf 8 and 8 + 0 do
				(comsyncm) if swap 1+ swap then
			loop
			swap 2 > if leave 2 over comstate! then
		then
	loop ;

\ waithi ( n1 -- ) make sure pin n1 is high and not oscillating
: waithi
	1000 0 do dup px? if 0 1000 0 do over px? if 1+ else leave then loop else 0 then
   		FF0 > if leave else 1 delms then  loop drop ;

: (com) def_com lasm c" COM" numpad ccopy 1- 5 lshift 10 or state C! >r io rot2 r> (cominit) (comres) 1 over comstate! ;

\ this starts the cog as a master channel
\ commaster ( n1 n2 n3 n4 -- ) n1 - master pin, n2 slave pin, n3 reset pin, n4 number of channels
: commaster
	(com) (comsynsm) begin (comsyncs) until
	dup compinm@ >m v_pinout COG! dup compins@ >m v_pinin COG!
	10 delms
	dup compinm@ dup pinhi pinout
	0 ctra COG! 0 ctrb COG! 
	dup compins@ waithi
	60 delms
	4 over comstate!
	a_mastercom  ;

\ this starts the cog as a slave channel, and connects cogs 0 - n4 as forth cogs, these cogs should be already started
\ and free as forth cogs
\ comslave ( n1 n2 n3 n4  -- ) n1 - master pin, n2 slave pin, n3 reset pin, n4 number of channels
: comslave
	(com) (comsynss) begin (comsyncm) until
	dup compinm@ >m v_pinin COG! dup compins@ >m v_pinout COG!
	10 delms
	dup compins@ dup pinhi pinout
	0 ctra COG! 0 ctrb COG!
	dup compinm@ waithi
	10 delms
	4 over comstate!
	a_slavecom ;



{

\ the assembler code which drives the channel

fl


:asm

\ the output pin used for the communication
v_pinout
 0
\ the input pin used for the communication
v_pinin
 0
\ the registers in which the data is received
__1rxdata0
 0
__2rxdata1
 0
__3rxcontrol
 0
\ the registers in which the data is transmitted
__4txdata0
 0
__5txdata1
 0
__6txcontrol
 0






\ packs 4 words from sendbuf into _treg3, and sets the bit in __6txcontrol if there is a byte to transmit
\ bytes and bits to indicate a byte for consumption are packed in small endian order
\
__7bl
		mov	_treg3	, # 0
		mov	_treg6 	, # 4
__Flp
		shr	__6txcontrol , # 1
		shr	_treg3	, # 8
		rdword	_treg1	, _sttos
		mov	_treg2	, _treg1
		shl	_treg1	, # 18
		and	_treg2	, # 100 wz
	if_z	or	_treg3	, _treg1
	if_z	or	__6txcontrol , # 80
		add	_sttos	, # 4
		djnz	_treg6	, # __Flp	
__8blret
		ret


\ load the sendbuf into the tx registers, set the appropriate bits to indicate there is a byte for consumption 
\ (b0-b7 of txcontrol), or in the ackowledge bits for what has been received (b8-b15 of txcontrol) and set the
\ checksum (b16 - b31 of txcontrol)
\
__9loadregs
\ accessing chchannel offest 0, inc 4 * 8 = 20, dec 20
		mov	__6txcontrol , # 0

		jmpret	__8blret , # __7bl
		mov	__4txdata0 , _treg3			

		jmpret	__8blret , # __7bl
		mov	__5txdata1 , _treg3			

		or	__6txcontrol , __3rxcontrol

		mov	_treg4	, __4txdata0
		xor	_treg4	, __5txdata1
		xor	_treg4	, __6txcontrol
		xor	_treg4	, # 155
		mov	_treg5	, _treg4
		shr	_treg5	, # 10
		xor	_treg4	, _treg5
		shl	_treg4	, # 10
		or	__6txcontrol , _treg4		

		sub	_sttos , # 20
__Aloadregsret
		ret

\ full duplex xmt / rec of the tx / rx registers 3 registers sent, 3 registers received
\ 0-6(variables) 9-a(loadregs)

\ _treg5 tx reg , _treg3 rx reg
__7trreg
		mov	_treg6 , # 20
__Flp
			test	v_pinin , ina wc
			rcl	_treg3	, # 1  
			shl	_treg5	, # 1 wc
			muxc	outa , v_pinout
		djnz	_treg6	, # __Flp wz
		test	v_pinin	, ina wc
		rcl	_treg3	, # 1  
__8trregret
		ret


\ xmt / rec then precess the received data
\ 0-6(variables) 9-A(loadregs) B-C(txrx)

__Btxrx
\ xmt / rec the registers, control register first, then data1, the data0
\ 0-6(variables) 7-8(trreg) 9-A(loadregs) B-C(txrx)
		mov	_treg5 , __6txcontrol
		jmpret	__8trregret , # __7trreg
		mov	__3rxcontrol , _treg3

		mov	_treg5 , __5txdata1
		jmpret	__8trregret , # __7trreg
		mov	__2rxdata1 , _treg3

		mov	_treg5 , __4txdata0
		jmpret	__8trregret , # __7trreg
		mov	__1rxdata0 , _treg3
	
		muxz	outa , v_pinout

\ add one to the counter in the channel structure
\ accessing comcnt
		mov	_treg6	, _sttos
		add	_treg6	, # 34

\ check the checksum, if there is an error zero out rxcontrol and add one to the error counter in the structure
		mov	_treg4	, __1rxdata0
		xor	_treg4	, __2rxdata1
		xor	_treg4	, __3rxcontrol
		xor	_treg4	, # 155

		mov	_treg5	, _treg4
		shr	_treg5	, # 10
		xor	_treg4	, _treg5
		shl	_treg4	, # 10 wz

		rdlong	_treg5	, _treg6
		add	_treg5	, # 1
		wrlong	_treg5	, _treg6

\ accessing comerr
		add	_treg6	, # 4
	if_nz	mov	__3rxcontrol , # 0

	if_nz	rdlong	_treg5	, _treg6
	if_nz	add	_treg5	, # 1
	if_nz	wrlong	_treg5	, _treg6

\ debugging
\
\		 
\		add	_treg6	, # 4
\
\	if_z	rdlong	_treg5	, _treg6
\	if_z	add	_treg5	, # 1
\	if_z	wrlong	_treg5	, _treg6
\

\ process the acknowledge bits in b8-15 of the rxcontrol register
\ set the corresponding word in sendbuf to 0x100 indicating we are ready to receive another byte
\
\ accessing chchannel offest 0, inc 4 * 8 = 20, dec 20

		mov	_treg5	, # 100
		mov	_treg1	, __3rxcontrol
		mov	_treg6	, # 8
__Flp
		test	_treg1	, # 100 wz
	if_nz	wrword	_treg5	, _sttos
		shr	_treg1	, # 1
		add	_sttos	, # 4
		djnz	_treg6	, # __Flp
		sub	_sttos , # 20

\ process the received data in rxdata0 and rxdata1, if the corresponding receive channel bits in b8-15 of the rxcontrol register
\ if the corresponding word in recbuf is 0x100 indicating we are ready to receive another byte, write the byte
\ 
\
\ accessing comrecbuf
		add	_sttos	, # 20
		mov	_treg5	, # 2
		mov	_treg4	, __1rxdata0
__Elp
		mov	_treg6	, # 4
__Flp
			mov	_treg3	, _treg4
			shr	_treg4	, # 8
			shr	__3rxcontrol , # 1 wc	
	if_c		rdword	_treg1	, _sttos
			and	_treg3	, # FF
			test	_treg1	, # 100 wz
	if_c_and_nz	wrword	_treg3	, _sttos
			add	_sttos	, # 2
			djnz	_treg6	, # __Flp
		mov	_treg4	, __2rxdata1
		djnz	_treg5	, # __Elp
	
		sub	_sttos	, # 30


\ and finally
\
\ move the character to the destination specified by the emit pointer, or if it is zero,
\ toss it into the bit bucket
\
\ process the state of the received characters in recbuf and send back the corresponding acknowledge bits
\ state 100 - ready to receive a byte
\ state 0xx - a valid bytes
\ state 400 - the byte has been read, but no acknowledge bit has been sent
\ state 200 - the acknowledge bit has been sent
\ *** only one state change at a time in this routine please


\ accessing chchannel + 2
	mov	__5txdata1 , _sttos
	add	__5txdata1 , # 2
	mov	_treg4	, # 7
	shl	_treg4	, # 8
\
\ accessing comrecbuf	
		add	_sttos	, # 20
		mov	__3rxcontrol , # 0
		mov	_treg5	, # 100
		mov	__1rxdata0 , # 100
		mov	__2rxdata1 , __1rxdata0
		shl	__2rxdata1 , # 1
		mov	__4txdata0 , __2rxdata1
		shl	__4txdata0 , # 1

		mov	_treg6	, # 8
__Flp
		rdword	_treg3	, _sttos

\ move the character to the destination specified by the emit pointer, or if it is zero,
\ toss it into the bit bucket
	test	_treg3	, _treg4 wz
 if_nz	jmp	# __Dnochar
	rdword	_treg2	, __5txdata1 wz
 if_z	mov	_treg3	, __4txdata0
 if_z	jmp	# __Dnochar
	rdword	_treg1	, _treg2
	test	_treg1	, __1rxdata0 wz
 if_nz	wrword	_treg3	, _treg2
 if_nz	mov	_treg3	, __4txdata0
__Dnochar

\ process the flags
\ 200 -> 100
		test	_treg3	, __2rxdata1 wz
	if_nz	wrword	__1rxdata0 , _sttos
\ 400 -> 200 + flag
		test	_treg3	, __4txdata0 wz
	if_nz	wrword	__2rxdata1 , _sttos
	if_nz	or	__3rxcontrol , _treg5
		shl	_treg5	, # 1
		add	__5txdata1 , # 4
		add	_sttos	, # 2
		djnz	_treg6	, # __Flp
		sub	_sttos	, # 30

__Ctxrxret
		ret




 
a_mastercom
__Flp
		jmpret	__Aloadregsret , # __9loadregs
		mov	_treg1 , # 1 wz
		muxz	outa , v_pinout
		waitpne	v_pinin , v_pinin
		jmpret	__Ctxrxret , # __Btxrx
		jmp	# __Flp

a_slavecom
__Flp
		jmpret	__Aloadregsret , # __9loadregs
		mov	_treg1 , # 1 wz
		waitpne	v_pinin , v_pinin
		muxz	outa , v_pinout
		jmpret	__Ctxrxret , # __Btxrx
		jmp	# __Flp



;asm


}

...
