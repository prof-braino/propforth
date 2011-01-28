fl

{

load LogicAnalyzer.f

load this file

test1

test2

}


hex



\ this pin is used to provide a trigger for LogicAnalyzer
18 wconstant w_lasync

\ IO pins which drive the W5100
F wconstant w_sen
E wconstant w_reset

D wconstant w_int
C wconstant w_cs

B wconstant w_rd
A wconstant w_wr

9 wconstant w_a1
8 wconstant w_a0


\ these variables are used to control the LogicaAnalyzer and the display
wvariable samclock 1F4 samclock W!
wvariable dispos 0 dispos W!

\ (sync) ( -- ) pulse the sync pin hi for about 45 uSec
: (sync) w_lasync pinhi 8 0 do loop w_lasync pinlo ;

\ (syncinit) ( -- ) set the sync pin to output
: (syncinit) w_lasync pinlo w_lasync pinout ;

\ (sam1) ( -- ) used by (sam) to sample
: (sam1) samclock W@ w_lasync 0 sample2 ; 

\ (sam) ( -- ) use cog 0 to sample, samclock define how many clocks between samples
: (sam) 0 cogreset 20 delms c" (sam1)" 0 cogx 100 delms ;

\ sample at 500, 200, 100 clocks, triggered by the rising edge of the w_lasync pin
: sam500 1F4 samclock W! (sam) ;
: sam200 C8 samclock W! (sam) ;
: sam100 64 samclock W! (sam) ;

\ display ( -- ) custom LogicAnalyzer display for the spinnerweb server
: display 0 dispos W! begin
\ Ansi home clear line
	1b emit 5b emit 48 emit 1b emit 5b emit 4b emit
	." a - scroll left, b - scroll right, ESC exit " dispos W@ . samclock W@ . crcl space space
	4 0 do
		dispos W@ i 28 u* +  samclock W@ u* f4240 clkfreq u*/ <# # # # # # # #> .cstr
		lasti? if ."  microSec" else 22 spaces then
	loop
	8 0 do cr ."  D" i . dispos W@ i displayPin loop
	crcl ."  A0" dispos W@ 8 displayPin
	crcl ."  A1" dispos W@ 9 displayPin
	crcl ."  WR" dispos W@ A displayPin
	crcl ."  RD" dispos W@ B displayPin
	crcl ."  CS" dispos W@ C displayPin
	crcl ." INT" dispos W@ D displayPin
	crcl ." RES" dispos W@ E displayPin
	crcl ." SEN" dispos W@ F displayPin
	crcl ." SYN" dispos W@ 18 displayPin

	crcl crcl
	key dup 61 = if dispos W@ a0 - 0 max dispos W! else
	dup 62 = if dispos W@ a0 + freeDictEnd a0 - freeDictStart - 2/ 2/ min dispos W! then then
	1B = until ;
	

\ registers in the w5100

0 wconstant w_mr
1 wconstant w_idm_ar0
2 wconstant w_idm_ar1
3 wconstant w_idm_dr


\ common mode registers
1  wconstant w_gar0	\ gateway address register
5  wconstant w_subr0	\ subnet mask register
9  wconstant w_shar0	\ source hardware address register
F  wconstant w_sipr0	\ source ip address address register


\ socket status constants
\ socksr values
0  wconstant w_sr_closed
13 wconstant w_sr_init
14 wconstant w_sr_listen
\ 17 wconstant w_sr_established
1c wconstant w_sr_close_wait
\ 22 wconstant w_sr_udp
\ 32 wconstant w_sr_ipraw
\ 42 wconstant w_sr_ipmacraw

\ socket ir values
1  wconstant w_ircon
2  wconstant w_irdiscon
4  wconstant w_irrecv
8  wconstant w_irtimeout
10 wconstant w_irsend_ok

\ sock command register values
1  wconstant w_sc_open
2  wconstant w_sc_listen
4  wconstant w_sc_connect
\ 8  wconstant w_sc_discon
10 wconstant w_sc_close
20 wconstant _sc_send
\ 21 wconstant w_sc_sendmac
22 wconstant w_sc_sendkeep
40 wconstant w_sc_recv



\ (w_dout) ( -- ) set data bus to out
: (w_dout) dira COG@ FF or dira COG! ;

\ (w_din) ( -- ) set data bus to in
: (w_din) dira COG@ FF andn dira COG! ;

\ (w_addr) ( n1 -- ) n1 - the address bits 0 - 3
: (w_addr) w_a0 over 1 and if pinhi else pinlo then w_a1 swap 2 and if pinhi else pinlo then ;

\ (w_read) ( n1 -- n2) n1 - register to read 0 - 3, n2 - the value read
: (w_read) (w_addr) (w_din) w_cs pinlo w_rd pinlo ina COG@ FF and w_rd pinhi w_cs pinhi ;

\ (w_write) ( n1 n2 -- ) n1 - data to write, n2 register to write 0 - 3
: (w_write) (w_addr) (w_dout) FF and outa COG@ or outa COG! w_cs pinlo w_wr pinlo w_wr pinhi w_cs pinhi
outa COG@ FF andn outa COG! (w_din) ;

\ (w_wridm) ( n1 -- ) n1 - a 16 bit value to write to the indirect bus address registers
: (w_wridm)  dup 8 rshift w_idm_ar0 (w_write) w_idm_ar1 (w_write) ;

\ (w_rdidm) ( -- n1 ) n1 - a 16 bit value read from the indirect bus address registers
: (w_rdidm)  w_idm_ar0 (w_read) 8 lshift  w_idm_ar1 (w_read) or ;

\ (w_rdnextreg) ( -- n1) n1 - the data read
: (w_rdnextreg) w_idm_dr (w_read) ;

\ (w_rdreg) ( n1 -- n2) n1 - the register to read, n2 the data read
: (w_rdreg) (w_wridm) (w_rdnextreg) ;

\ (w_wrnextreg) ( n1 --) n1 - the data to write
: (w_wrnextreg) w_idm_dr (w_write) ;

\ (w_wrreg) ( n1 n2 --) n1 - the data to write, n2 - the register
: (w_wrreg) (w_wridm) (w_wrnextreg) ;

\ (w_init) ( -- ) reset the w5100, set to use indirect bus interface mode, address auto-increment
: (w_init)
	w_sen pinlo
	w_reset pinlo


	w_cs pinhi

	w_rd pinhi
	w_wr pinhi

	w_a1 pinlo
	w_a0 pinlo

	w_sen pinout


	w_int pinin
	w_cs pinout

	w_rd pinout
	w_wr pinout

	w_a1 pinout
	w_a0 pinout

	(w_din)

	w_reset pinout


	8 0 do loop

	w_reset pinhi
	3 0 (w_write)
;

: w_dump_commonregs
	0 <# # # #> .cstr _ecs 0 (w_rdreg) <# # # # #> .cstr space space space
	30 1 do
		i <# # # #> .cstr _ecs (w_rdnextreg) <# # # # #> .cstr
		i 7 and 7 = if cr else space space space then
	loop cr ." IDM: " (w_rdidm) . ;

: w_dump_socketregs
	dup <# # # # # #> .cstr _ecs dup (w_rdreg) <# # # # #> .cstr space space space
	2A 1 do
		i over + <# # # # # #> .cstr _ecs (w_rdnextreg) <# # # # #> .cstr
		i 7 and 7 = if cr else space space space then
	loop cr ." IDM: " (w_rdidm) . cr drop ;

: w_dump w_dump_commonregs cr cr 4 0 do i 100 u* 400 + w_dump_socketregs cr loop ;


: test1 (syncinit) sam200 (sync) (w_init) decimal display hex ;

: test2 (syncinit) sam200 (sync) (w_init) (sync) 0 (w_rdreg) 30 0 do (w_rdnextreg) drop loop decimal display hex ;

 
