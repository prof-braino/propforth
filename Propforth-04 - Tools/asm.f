fl

\ Copyright (c) 2010 Sal Sanci

fswrite asm.f

hex

1 wconstant build_asm

\ .long ( n -- ) emit 8 hex digits
[if .long
: .long dup 10 rshift .word .word ; ]

\ this word needs to align with the assembler code
[if _stptr
: _stptr 5 _cv ; ] 

\ this word needs to align with the assembler code
[if _sttos
: _sttos 7 _cv ; ]

\ this word needs to align with the assembler code
[if _stbot
: _stbot e _cv ; ]

\ this word needs to align with the assembler code
[if _sttop
: _sttop 2e _cv ; ]

\ this word needs to align with the assembler code
[if _rsbot
: _rsbot _sttop ; ]

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

\ parsenw ( -- cstr ) parse and move to the next word, str ptr is zero if there is no next word
[if parsenw
: parsenw parsebl if pad>in nextword else 0 then ; ]

\ padnw ( -- t/f ) move past current word and parse the next word, true if there is a next word
[if padnw
: padnw nextword parsebl ; ]

\ padclr ( -- )
[if padclr
: padclr begin padnw 0= until ; ]


\ aallot ( n1 -- ) add n1 to coghere, allocates space in the cog or release it, n1 is # of longs
[if aallot
: aallot coghere W+! coghere W@ par >= if 8500 ERR then ; ]

\ cog, ( x -- ) allocate 1 long in the cog and copy x to that location
[if cog,
: cog, coghere W@ COG! 1 aallot ; ]


\ _ec ( cstr -1|n1 -- cstr 0 | n1 -1) 
: _ec dup -1 = if drop 0 else nip 10 lshift -1 then ;

\ oc= ( cstr1 cstr2 -- cstr1 t/f)
: oc= over cstr= ;

\ alabel ( cstr -- ) create an assembler entry at the current cog coghere
: alabel lockdict ccreate coghere W@ w, freedict ;

\ cnd1 ( cstr -- cstr -1 | cstr n1 ) process a subset of conditions 
: cnd1 c" if_always" oc= if 003C else c" if_never" oc= if 0000 else c" if_e" oc= if 0028 else c" if_ne" oc= if 0014 else
c" if_a" oc= if 0004 else c" if_b" oc= if 0030 else c" if_ae" oc= if 000C else c" if_be" oc= if 0038 else
c" if_c" oc= if 0030 else c" if_nc" oc= if 000C else c" if_z" oc= if 0028 else c" if_nz" oc= if 0014 else
c" if_c_eq_z" oc= if 0024 else c" if_c_ne_z" oc= if 0018 else c" if_c_and_z" oc= if 0020 else
c" if_c_and_nz" oc= if 0010 else -1 thens ; 

\ cnd2 ( cstr -- cstr -1 | cstr n1 ) process a subset of conditions  
: cnd2 c" if_nc_and_z" oc= if 0008 else c" if_nc_and_nz" oc= if 0004 else c" if_c_or_z" oc= if 0038 else
c" if_c_or_nz" oc= if 0034 else c" if_nc_or_z" oc= if 002C else c" if_nc_or_nz" oc= if 001C else
c" if_z_eq_c" oc= if 0024 else c" if_z_ne_c" oc= if 0018 else c" if_z_and_c" oc= if 0020 else
c" if_z_and_nc" oc= if 0008 else c" if_nz_and_c" oc= if 0010 else c" if_nz_and_nc" oc= if 0004 else
c" if_z_or_c" oc= if 0038 else c" if_z_or_nc" oc= if 002C else c" if_nz_or_c" oc= if 0034 else
c" if_nz_or_nc" oc= if 001c else -1 thens ; 

\ cnd ( cstr -- cstr 0 | n1 -1 ) process the condition statement n1 is the mask to apply id successful 
: cnd cnd1 dup -1 = if drop cnd2 then _ec ; 

\ ai1 ( cstr -- cstr -1 | cstr n1 ) process a subset of op codes 
: ai1 c" abs" oc= if A8BC else c" absneg" oc= if ACBC else c" add" oc= if 80BC else c" addabs" oc= if 88BC else
c" adds" oc= if D0BC else c" addsx"oc= if D8BC else c" addx" oc= if C8BC else c" and" oc= if 60BC else
c" andn" oc= if 64BC else c" cmp" oc= if 843C else c" cmps" oc= if C03C else c" cmpsub" oc= if E03C else
c" cmpsx" oc= if C43C else c" cmpx" oc= if CC3C else c" djnz" oc= if E4BC else c" max" oc= if 4CBC else
c" maxs" oc= if 44BC else c" min" oc= if 48BC else c" mins" oc= if 40BC else c" mov" oc= if A0BC else
c" movd" oc= if 54BC else c" movi" oc= if 58BC else -1 thens ;

\ ai2 ( cstr -- cstr -1 | cstr n1 ) process a subset of op codes  
: ai2 c" movs" oc= if 50BC else c" muxc" oc= if 70BC else c" muxnc" oc= if 74BC else c" muxnz" oc= if 7CBC else
c" muxz" oc= if 78BC else c" neg" oc= if A4BC else c" negc" oc= if B03C else c" negnc" oc= if B4BC else
c" negnz" oc= if BCBC else c" negz"oc= if B9BC else c" or" oc= if 68BC else c" rdbyte" oc= if 00BC else
c" rdlong" oc= if 08BC else c" rdword" oc= if 04BC else c" rcl" oc= if 34BC else c" rcr" oc= if 30BC else
c" rev" oc= if 3CBC else c" rol" oc= if 24BC else c" ror" oc= if 20BC else c" sar" oc= if 38BC else
c" shl" oc= if 2CBC else c" shr" oc= if 28BC else -1 thens ;

\ ai3 ( cstr -- cstr -1 | cstr n1 ) process a subset of op codes  
: ai3 c" sub" oc= if 84BC else c" subabs" oc= if 8CBC else c" subs" oc= if D4BC else c" subsx" oc= if DCBC else
c" subx" oc= if CCBC else c" sumc" oc= if 90BC else c" sumnc" oc= if 94BC else c" sumnz" oc= if 9CBC else
c" sumz" oc= if 98BC else c" test" oc= if 603C else c" tjnz" oc= if E83C else c" tjz" oc= if EC3C else
c" waitcnt" oc= if F8BC else c" waitpeq" oc= if F03C else c" waitpne" oc= if F43C else c" waitvid" oc= if FC3C else
c" wrbyte"  oc= if 003C else c" wrlong" oc= if 083C else c" wrword" oc= if 043C else c" xor" oc= if 6CBC else
c" jmpret" oc= if 5CBC else -1 thens ;

\ asminstds ( cstr -- cstr 0 | n1 -1 ) process op codes with a destination and a source
: asminstds ai1 dup -1 = if drop ai2 dup -1 = if drop ai3 then then _ec ;
 
\ asminstd ( cstr -- cstr 0 | n1 -1 ) process opcodes with a destination only 
: asminstd c" clkset"  oc= if 0C7C0000 else c" cogid" oc= if 0CFC0001 else c" coginit" oc= if 0C7C0002 else
c" cogstop" oc= if 0C7C0003 else c" lockclr" oc= if 0C7C0007 else c" locknew" oc= if 0CFC0004 else
c" lockret" oc= if 0C7C0005 else c" lockset" oc= if 0C7C0006 else 0 thens dup if nip -1 then ;

\ asminsts ( cstr -- cstr 0 | n1 -1 ) process opcodes with a source only
: asminsts c" jmp" oc= if 5C3C else c" long" oc= if 0 else -1 thens _ec ;

\ _mc ( src dst -- n) 
: _mc 9 lshift or 5CFC0000 or ;

wvariable amacroptr

: amacro
c" jnext" oc= if $C_a_next 5C7C0000 or else c" spush" oc= if $C_a_stpush $C_a_stpush_ret _mc else
c" spopt" oc= if $C_a_stpoptreg $C_a_stpoptreg_ret _mc else c" spop" oc= if $C_a_stpop $C_a_stpop_ret _mc else
c" rpush" oc= if $C_a_rspush $C_a_rspush_ret _mc else c" rpop" oc= if $C_a_rspop $C_a_rspop_ret _mc else 0 thens ;

' amacro amacroptr W!

\ asminst ( cstr -- cstr 0 | n1 -1 ) process the only opcode with no dest or source
: asminst c" nop" oc= if 1 else c" ret" oc= if 5C7C0000 else amacroptr W@ execute thens dup if dup 1 = 
if drop 0 then nip  -1 then ;

\ asmerr ( cstr cstr -- ) report an error and consume all the keys left
: asmerr .cstr .cstr cr padclr clearkeys ;

\ localLabel ( cstr -- n1 ) 0 - not a local label, otherwise 0 - F, local labels are __1 to __F
: localLabel dup c" __" npfx if 2+ 1+ 1 2dup isnumber if number dup 1 F between 0= 
if drop 0 then else 2drop 0 then else drop 0 then ;

\ asmpatch ( addr t/f -- ) addr - the cog address of the assembler instruction to patch, t/f 0 - source op, -1 dest op
: asmpatch if 9 else 0 then swap dup c rshift F and 2* tbuf + W@ dup FFFF = 
if c rshift F and drop <# #s #> c" Undefined __" asmerr drop else 1FF and rot lshift over COG@ or swap COG! then ;

\ evalop1 ( t/f cstr -- n1 ) t/f 0 - source op, -1 dest op, evaluate the operand as either as a forth word, a number,
\ or a local label
: evalop1 dup localLabel dup
\ we have a local label
if nip dup 2* tbuf + W@ dup FFFF =
\ local label undefined ( t/f label FFFF -- )
	if drop F and c lshift coghere W@ 1FF and or
\ ( t/f (label << C or'ed wwith current address)
		over if t1 else t0 then W! 0 
\ local label which is already defined
	else nip then
\ forth word 
else drop find -1 = if execute else dup C@++ isnumber if C@++ number else c" ? " asmerr 0 then then then
nip ;

\ evalop ( t/f cstr -- n1 ) t/f 0 - source op, -1 dest op, evaluate the operand as either as a forth word, a number,
\ or a local label
: evalop evalop1 1FF and ;

\ asmsrc ( n1 -- n1 ) n1 is the asm opcode, can be modified to set the immediate bit, the operand is evaluated as
\ a forth word/number
: asmsrc padnw 
if pad>in c" #" cstr= if 00400000 or padnw else -1 then if 0 pad>in evalop or 0 else -1 then
else -1 then if c" Source Operand" c"  ?" asmerr then ;

\ asmdst ( n1 -- n1 ) n1 is the asm opcode
: asmdst padnw if -1 pad>in evalop 9 lshift or 0 else -1 then if ." Dest Operand" c"  ?" asmerr then ;

\ (label) ( n1 n2 -- n3 n4 ) check to make sure the rest of the pad is empty
\ if not generate an error and set n3 = -1 & n4 = 0
: (label) padnw if pad>in c" Unexpected data after a label:" asmerr drop -1 swap then ;

\ asmopend ( n2 n1 -- n3 ) or in the update conditions
: asmopend padnw
if begin pad>in dup 1+ C@ 27 <> 
	if
		dup c" wc" cstr= if drop 01000000 or else
		dup c" wz" cstr= if drop 02000000 or else
		dup c" wr" cstr= if drop 00800000 or else
		dup c" nr" cstr= if drop FF7FFFFF and else
		c" Unexpected word " asmerr then then then then  
	else drop padclr then
	padnw 0=
until then
dup 0= if nip else FFC3FFFF and or then ;

\ asmdstsrc ( n1 -- n1 )
: asmdstsrc asmdst padnw 
if pad>in c" ," cstr= if asmsrc 0 else -1 then else -1 then
if ." Expected" c"  ," asmerr else asmopend then ;

\ asmdone ( x ... x -- )
: asmdone
begin
\  patch the source operand?
	dup FFFF and 7123 = if 10 rshift 0 asmpatch else
\ patch the dest operand?
	dup FFFF and 5712 = if 10 rshift -1 asmpatch else
	dup FFFF and 5321 = if 10 rshift lastnfa
	begin 
		dup nfa>pfa over C@ 80 and if 2+ then W@ . dup c" c_" npfx over c" v_" npfx or
		if ." wconstant " else ." asmlabel " then dup .strname cr
		nfa>lfa W@ 2dup >= 
	until 2drop
	thens
\ the end
\	dup FFFF and 1235 = if 10 rshift coghere W@ swap 
\	do i COG@ dup 0= if 30 emit else .long then ."  cog," cr loop 
\	cr -1 else 0 then
	dup FFFF and 1235 = if 10 rshift coghere W@ ." lockdict variable def_" over .word space 
	2dup .word ."  l, "  .word ."  l," cr swap 0 rot2
	do i COG@ dup 0= if drop 30 emit else .long then ."  l, " 1+ dup A >= if drop 0 cr then loop drop
	cr -1 else 0 then
until
." freedict" cr cr
;

\ asmline ( -- t/f )
: asmline

\ t0 word is used as a variable encoding a dest operand that needs to be patched if non-zero
\ t1 word is used as a variable encoding a source operand that needs to be patched if non-zero
\ tbuf word 0-F are used as the addresses for the local labels, FFFF if they are not valid

0 t0 W! 0 t1 W! parsebl dup if pad>in 1+ C@ dup 27 <> swap 5c <> and and then invert
\ not a blank line, and not a comment line
if 0 0 else
	pad>in c" c_" npfx pad>in c" v_" npfx or pad>in find -1 = rot and if execute cog, 0 0 else drop
\ if it starts with c_ or v_ we have a value, just paste it in, make sure you do not define forth
\ words which override asm words
	pad>in c" ;asm" name= 
\ assembler done
	if asmdone -1 0 else
\ we have an asmlabel leave a trail on the stack
		pad>in c" a_" npfx if pad>in alabel 0 0 (label) else

\ we have a constant label leave a trail on the stack
			pad>in c" c_" npfx pad>in c" v_" npfx or 
			if pad>in clabel 0 0 (label) else
\ we have a local label
				pad>in localLabel dup if 2* tbuf + coghere W@ swap W! 0 0 (label) else drop
\ process the condition, default to "if_always" 
					pad>in cnd if padnw if 0 swap -1 else c" Opcode" c"  ?" asmerr -1 0 then else drop 0 003C0000 -1 
thens
if pad>in asminst 
\ process in the op-code, source, dest, and update flags
	if asmopend cog, else asminsts 
		if asmsrc asmopend cog, else asminstd
			if asmdst asmopend cog, else asminstds
				if asmdstsrc cog, else 2drop 0 pad>in evalop1 cog,
thens
\ source operand needs patching leave a trail on the stack
t0 W@ dup if 10 lshift 7123 or swap else drop then
\ dest operand needs patching leave a trail on the stack
t1 W@ dup if 10 lshift 5712 or swap else drop then
;

: :asm coghere W@ 10 lshift 1235 or lastnfa 10 lshift 5321 or tbuf 20 FF fill 
begin pad padsize accept drop 0 >in W! asmline until padnw drop ;

...

