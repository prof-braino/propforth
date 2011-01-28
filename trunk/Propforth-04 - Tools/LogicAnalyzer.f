fl



fswrite LogicAnalyzer.f

hex

1 wconstant build_LogicAnalyzer

{
\ demo run on cog6

\ set crta and pin 10 to oscillate at about 700 Khz
\ set crtb and pin 11 to oscillate at about 7   Mhz

c" hex a aae60 setHza b 6ACFC0 setHzb" 5 cogx


sampleNoTrigger
sampleTrigger
sampleFourTrigger
sampleOneNoTrigger

decimal displayTriggerFrequency hex
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

\ abs ( n1 -- abs_n1 ) absolute value of n1
[if abs
: abs _execasm1>1 151 _cnip ; ]

\ waitcnt ( n1 n2 -- n1 ) \ wait until n1, add n2 to n1
[if waitcnt
: waitcnt _execasm2>1 1F1 _cnip ; ]

\ u*/mod ( u1 u2 u3 -- u4 u5 ) u5 = (u1*u2)/u3, u4 is the remainder. Uses a 64bit intermediate result.
[if u*/mod
: u*/mod rot2 um* rot um/mod ; ]

\ u*/ ( u1 u2 u3 -- u4 ) u4 = (u1*u2)/u3 Uses a 64bit intermediate result.
[if u*/
: u*/ rot2 um* rot um/mod nip ; ]

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


\ This block is low level code which sets up and manipulates the assembler necessary 

\ variable definitions and addresses for assembler routines

160 asmlabel a_triggerCycleTime
15F wconstant v_LScnt
15E wconstant v_LSz
15D wconstant v_LbufP
1EE wconstant v_sample1end
154 wconstant v_sample1
152 asmlabel a_sample
151 wconstant v_LTa
150 wconstant v_LTb
14F wconstant v_LTm

\ the assembler code which samples every 40 or more cycles to hub memory, and the routine which measures the
\ cycle time of the trigger 
lockdict
variable _def_sam2 
0169 l, 014F l,
0 l, 0 l, 0 l, 
F03EA14F l, F03EA34F l, A0BE13F2 l, A0BE15F1 l, 80BE155F l, 083E135D l, F8BE155F l, A0BE13F2 l, 80FEBA04 l, E4FEBD57 l, 5C7C0075 l,
0 l, 0 l, 0 l, 
5CFDCEE0 l, F03EA14F l, F03EA34F l, A0BE13F1 l, F03EA14F l, F03EA34F l, A0BE11F1 l, 84BE1109 l, 5C7C0075 l,
freedict

\ The logic analyzer forth code


\ _ds ( n2 n1 -- ) generates the assembler to load a sample every 4 clocks (self overwriting)
\  n1 and n2 are assembler words which wait or not for the trigger
: _ds 14F coghere W! 0 cog, 0 cog, 0 cog, cog, cog, 9A 0 do A0BC01F2 coghere W@ 9 lshift or cog, loop 5C7C0075 cog, ;

\ loads the assembler which samples every 40+ clock cylces, and teh assembler which measure trigger frequency
: def_sam2 _def_sam2 lasm ;

\ loads the assembler which samples every 4 clock cycles
: def_sam1 F03EA14F F03EA34F _ds ;

\ loads the assembler which measures every 4 clock cycles triggers on the count register
\ this is used to use 4 cogs in synch to sample very clock cycle
: def_sam0 F8FEA3FF 0 _ds ; 

\ this variable which is used to synch the 4 cogs which are doing interleaved sampling
variable _s0time

\ this variable value is the first of 4 sequential cogs used to sample every clock cycle, default to this cog 0

wvariable _s0cog 0 _s0cog W!


\ freeDictStart ( -- addr ) the start address of the unused dictionary, long aligned
: freeDictStart here W@ alignl ; 

\ freeDictEnd ( -- addr ) the end address of the unused dictionary, long aligned
: freeDictEnd dictend W@ 3 andn ; 

\ zeroFreeDict ( -- ) zeros out all the unused dictionary
: zeroFreeDict
	freeDictEnd freeDictStart 
	do 0 i L! 4 +loop ;

\ setTrigger ( n1 n2 -- )  n1 trigger pin, if n1 is negative, no trigger,  n2 0-rising, !0-falling
\ must be run after assembler routine are loaded, otherwise the trigger parameters will be 
\ overwritten
: setTrigger
	over 0<
	if 2drop 0 0 0
	else
		if >m  0 over else >m dup 0 then
	then
	v_LTb COG! v_LTa COG! v_LTm COG! ;

\ _s0 ( -- ) this is the interleaved routine used by 4 cogs to sample very clock cycle
: _s0
	0 dira COG! def_sam0 
	cogid _s0cog W@ - _s0time L@ + v_LTa COG!
	a_sample
	freeDictStart cogid _s0cog W@ - 2* 2* +
	v_sample1end v_sample1
	do i COG@ over L! 10 + loop
	drop ;

\ sample0 ( -- ) uses 4 cogs starting at _s0cog, samples at full clock, speed 636 (0x27C) samples total
: sample0
	zeroFreeDict
	clkfreq cnt COG@ + _s0time L! c" _s0" 
	dup _s0cog W@ cogx
	dup _s0cog W@ 1+ cogx
	dup _s0cog W@ 2+ cogx
	_s0cog W@ 3 + cogx
	_s0time L@ 8000 + 0 waitcnt drop
;

\ sample1 ( n1 n2 -- )  n1 trigger pin,  n2 0-rising, !0-falling , sample every 4 clocks, 159 (0x5F) samples total
: sample1
	zeroFreeDict
	def_sam1
	setTrigger
	0 dira COG! 
	a_sample
	freeDictStart v_sample1end v_sample1
	do i COG@ over L! 4 + loop drop ;

\ sample2 ( n1 n2 n3 -- )  n1 # clocks 40 decimal min, n2 trigger pin,  n3 0-rising, !0-falling 
: sample2
	zeroFreeDict
	def_sam2
	setTrigger
	32 max v_LScnt COG!
	freeDictEnd freeDictStart dup v_LbufP COG! - 2/ 2/ v_LSz COG!
	a_sample ;

\ displayPin ( n1 n2 -- ) show samples starting at position n1 for pin n2
: displayPin
	>m swap 2* 2* freeDictStart + 280 bounds 
	do
		i L@ over and if 2d else 5F then emit 4 
	+loop drop ;

\ this is the pin the logic analyzer uses as a trigger pin
wvariable triggerPin
a triggerPin W!

\ displaySamples ( n1 n2 -- ) display samples starting at position n1 for 8 pins starting at pin n2
: displaySamples
	dup 8 + swap 
	do
		crcl i <# # # #> .cstr
		dup i displayPin
		crcl
	loop drop ;

\ sampleNoTrigger ( -- ) sample every 40 clocks and display 160 samples starting from position 0
: sampleNoTrigger 
	28 -1 0 sample2
 	0 triggerPin W@ displaySamples ;

\ sampleTrigger ( -- ) sample every 40 clocks and display 160 samples starting from position 0,
\ trigger on triggerPin
: sampleTrigger
	28 triggerPin W@ 0 sample2
 	0 triggerPin W@ displaySamples  ;

\ sampleFourTrigger ( -- ) sample every 4 clocks and display 160 samplesstarting from position 0,
\ trigger on triggerPin
: sampleFourTrigger
	triggerPin W@ 0 sample1
	0 triggerPin W@ displaySamples ;

\ sampleOneNoTrigger ( -- ) sample every clock and display 160 samples starting from position 0, no trigger
: sampleOneNoTrigger
	sample0
	0 triggerPin W@ displaySamples ;

\ triggerFrequency ( -- n1 ) measure the period between 2 falling edges on triggerPin and retun 1000*freq
: triggerFrequency
	def_sam2
	triggerPin W@ dup pinin >m dup 0 v_LTb COG! v_LTa COG! v_LTm COG!
	clkfreq 3e8 um* a_triggerCycleTime um/mod nip ;

\ displayTriggerFrequency ( -- )
: displayTriggerFrequency
	triggerFrequency
	3e8 u/mod
	<# #s #> .cstr
	2e emit
	<# # # # #> .cstr
	cr ;





{
\
\ These are the assembler routines used by LogicAnalyzer
\ They are only here for reference, should not have to touch these routines
\


fl

: rh mcwcoghere W@ ;

\ this assembler routine load samples in fast by overwriting itself, every 4 clocks
:asm
\ the mask of input bits we care about
v_LTm
__D
0
v_LTb
\ the value of bits before we trigger
__E
0
\ the value of bits we trigger on
v_LTa
__F
0
a_sample
\ wait for trigger values
	waitpeq __Ev_LTb , __Dv_LTm
	waitpeq __Fv_LTa , __Dv_LTm
\
\	nop
\	waitcnt __Fv_LTa , # 1FF

v_sample1
\ get a sample and store it at this instruction's location
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina

	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina

	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina

	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina

	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina

	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina

	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina

	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina


	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina

	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
	mov	rh , ina
v_sample1end
	jnext
;asm











fl



\ this assembeler routine can read samples to hub memory every 40 clock cycles max

:asm

\ the mask of input bits we care about
v_LTm
0
\ the value of bits before we trigger
v_LTb
0
\ the value of bits we trigger on
v_LTa
0

\ a _sample ( -- )

a_sample
\ wait for trigger values
	waitpeq v_LTb , v_LTm
	waitpeq v_LTa , v_LTm
\ get the sample and set up the count for the next sample 
	mov	treg1 , ina
	mov	treg2 , cnt
	add	treg2 , __Dv_LScnt
__1
\ write out the sample
	wrlong	treg1 , __Fv_LbufP
\ wait for the next sample time
	waitcnt treg2 , __Dv_LScnt
	mov	treg1 , ina	
	add	__Fv_LbufP , # 4
	djnz	__Ev_LSz , # __1
\ we are done
	jnext
\ a pointer to the sample buffer
v_LbufP
__F
0
\ the sample buffer size
__E
v_LSz
0
\ the number of clock between samples (decimal 40 min)
__D
v_LScnt
0


\ this asssembler routine measures the time cycle time of trigger
a_triggerCycleTime
\ wait for trigger values
	jmpret ca_a_stpush_ret , # ca_a_stpush
	waitpeq v_LTb , v_LTm
	waitpeq v_LTa , v_LTm
	mov	treg1 , cnt
	waitpeq v_LTb , v_LTm
	waitpeq v_LTa , v_LTm
	mov	sttos , cnt
	sub	sttos , treg1
	jnext

;asm



\
\ End of the assembler routines used by LogicAnalyzer
\ They are only here for reference, should not have to touch these routines
\



}

...

