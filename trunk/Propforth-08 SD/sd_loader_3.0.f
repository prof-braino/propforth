fl

: variable lockdict create $C_a_dovarl w, 0 l, forthentry freedict ; 
0 _crf W!
{
: .long dup 10 rshift .word .word ;
: _sttop 2e _cv ;
: _stptr 5 _cv ;  
: st? ." ST: " _stptr COG@ 2+ dup _sttop < if _sttop swap - 0 do _sttop 2- i -  COG@ .long space loop else drop then cr ;
}
0 constant _sd_cs
1 constant _sd_di        \ connected SD's di
2 constant _sd_clk
3 constant _sd_do        \ connected SD's do


1 _sd_cs lshift constant _sd_csm
1 _sd_di lshift constant _sd_dim 
1 _sd_clk lshift constant _sd_clkm
1 _sd_do lshift constant _sd_dom

: _sd_cs_out _sd_cs pinout ;
: _sd_di_out _sd_di pinout ;
: _sd_clk_out _sd_clk pinout ;
: _sd_do_in _sd_do pinin ;

: _sd_cs_out_l _sd_csm _maskoutlo ;
: _sd_cs_out_h _sd_csm _maskouthi ;
: _sd_di_out_l _sd_dim _maskoutlo ;
: _sd_di_out_h _sd_dim _maskouthi ;
: _sd_clk_out_l _sd_clkm _maskoutlo ;
: _sd_clk_out_h _sd_clkm _maskouthi ;

wvariable tmp
wvariable tmp1
wvariable buff_ptr
wvariable sd_buf

wvariable sdhc
wvariable ccs
variable first_sector
wvariable byte/sector
wvariable sector/cluster
wvariable reserve_sector
wvariable num_fat
wvariable root_entry
variable sector/fat
variable total_sector
variable rootCluster
 
variable BTB_addr
variable FAT_addr
variable RDE_addr
variable USER_addr
 
: sd_shift_out      \ ( n -- ) send 1byte to SD-CARD 
8 0 do
     dup 1 7 i - lshift and  
     0> if _sd_di_out_h else _sd_di_out_l then
     _sd_clk_out_l _sd_clk_out_h                      
     loop
     drop
;
: sd_shift_in       \ ( -- n) receive 1byte to SD-CARD
0
8 0 do
     _sd_clk_out_l _sd_clk_out_h                      
     ina COG@ _sd_dom and 0> if 1+ then
     1 lshift   
     loop
     1 rshift
; 

: dummy ff sd_shift_out ;          \ ( -- ) send dummy 8clock to SD-CARD

: sd_init          \ ( -- ) initialization for SD-Card
_sd_di_out _sd_di_out_h
_sd_clk_out _sd_clk_out_h
_sd_do_in
_sd_cs_out _sd_cs_out_h
0 sdhc W!  
0 ccs W!
0 tmp W!
dictend W@ 200 - sd_buf W!

4a 0 do                  \ 74 clock
     _sd_clk_out_l
     _sd_clk_out_h
     loop
_sd_cs_out_l

40 sd_shift_out                    \ CMD0
0 4 0 do dup sd_shift_out loop drop
95 sd_shift_out                    \ CRC                  
begin sd_shift_in 1 = if 1 
                      else tmp dup W@ 1+ swap W! tmp W@ 100 = if ." error: no card" cr cr exit 
                                                              else 0 
                                                              then 
                      then 
until
dummy

48 sd_shift_out                    \ CMD8
0 2 0 do dup sd_shift_out loop drop
1 sd_shift_out
aa sd_shift_out
87 sd_shift_out

\ Response for CMD8
begin sd_shift_in dup 1 = if drop 1 
else 5 = if begin
77 sd_shift_out                    \ CMD55
0 4 0 do dup sd_shift_out loop drop
1 sd_shift_out
3 0 do sd_shift_in drop loop        \ skip response
dummy
69 sd_shift_out                    \ ACMD41
0 4 0 do dup sd_shift_out loop drop
1 sd_shift_out
5 0 do sd_shift_in 0= if 4 seti 1 else i 4 = if 0 then then loop
dummy
until
." SDSC initialize success" cr cr
exit
then
0 
then 
until

cr 
2 0 do sd_shift_in drop loop
sd_shift_in 
sd_shift_in 
aa = if 1 = if 1 else 0 then else drop 0 then
if 
     begin
          77 sd_shift_out                    \ CMD55
          0 4 0 do dup sd_shift_out loop drop
          1 sd_shift_out
          3 0 do sd_shift_in drop loop        \ skip response
          dummy

          69 sd_shift_out                    \ ACMD41
          40 sd_shift_out
          0 3 0 do dup sd_shift_out loop drop
          1 sd_shift_out
          5 0 do sd_shift_in 0= if 4 seti 1 else i 4 = if 0 then then loop
          dummy
     until
     7a sd_shift_out                    \ CMD58
     0 4 0 do dup sd_shift_out loop drop
     1 sd_shift_out
     begin sd_shift_in 0= until
     sd_shift_in                        \ Get CardCapacityStatus of OCR
     4 0 do sd_shift_in drop loop
     dummy
     40 and 0= if 0 ccs W! else 1 ccs W! then
          
else
     begin
          77 sd_shift_out                    \ CMD55
          0 4 0 do dup sd_shift_out loop drop
          1 sd_shift_out
          3 0 do sd_shift_in drop loop        \ skip response
          dummy

          69 sd_shift_out                    \ ACMD41
          0 4 0 do dup sd_shift_out loop drop
          1 sd_shift_out
          5 0 do sd_shift_in 0= if 4 seti 1 else i 4 = if 0 then then loop
          dummy
     until                         

then
     49 sd_shift_out                    \ CMD9
     0 4 0 do dup sd_shift_out loop drop
     1 sd_shift_out
     dummy
     begin sd_shift_in 0= until
     dummy
     begin sd_shift_in fe = until      \ start-byte for data token
     sd_shift_in
     f 0 do sd_shift_in drop loop         \ data block
     begin sd_shift_in ff = until      \ drop crc          
     dummy
     40 and 40 = if 1 sdhc W! ." SDHC initialize success" cr cr else ." SDSC initialize success" cr cr then
 _sd_cs_out_h
;

\ set buff_ptr to top address of sd_buf
: clear_buff_ptr  sd_buf W@ buff_ptr W! ; 
\ increment buff_ptr   
: buff_ptr+1 buff_ptr W@ 1+ buff_ptr W! ;

\ get sd's block data to sd-buf's area
\    ( address-value -- )  <-- SDSC
\    ( sector-number -- )  <-- SDHC on ccs=1
\    ( address-value -- )  <-- SDHC on ccs=0
: block_read  
4 0 do dup ff and swap 8 rshift loop drop
_sd_cs_out_l
51 sd_shift_out                    \ CMD17 Single Block read
 sd_shift_out
 sd_shift_out
 sd_shift_out
 sd_shift_out
1 sd_shift_out                    \ CRC
begin sd_shift_in 0= until
dummy
begin sd_shift_in fe = until      \ start-byte for data token
clear_buff_ptr  
200 0 do sd_shift_in buff_ptr W@ C! buff_ptr+1 loop
begin sd_shift_in ff = until                          \ drop crc

dummy      
begin sd_shift_in ff = until      \ drop crc          
dummy
_sd_cs_out_h
;

: collect_info      \ ( -- ) collect sd's information  
0 block_read  
clear_buff_ptr
buff_ptr W@ 1c6 + W@ 
buff_ptr W@ 1c8 + W@ 10 lshift or dup first_sector L!

\ 200 * block_read
ccs W@ if block_read else 200 u* block_read then
clear_buff_ptr
buff_ptr W@ b + C@ buff_ptr W@ c + C@ 8 lshift or byte/sector W!
buff_ptr W@ d + C@ sector/cluster W!
buff_ptr W@ e + W@ reserve_sector W!
buff_ptr W@ 10 + C@ num_fat W!
buff_ptr W@ 11 + C@ buff_ptr W@ 12 + C@ 8 lshift or root_entry W!
sdhc W@ if buff_ptr W@ 24 + L@ sector/fat L!
        else buff_ptr W@ 16 + W@ sector/fat L!
        then
buff_ptr W@ 20 + L@ total_sector L!
buff_ptr W@ 2c + L@ rootCluster L!

sdhc W@ if
first_sector L@  BTB_addr L!
first_sector L@ reserve_sector W@ + FAT_addr L!
num_fat W@ sector/fat W@ u* FAT_addr L@ + RDE_addr L!
RDE_addr L@ USER_addr L!
ccs W@ 0 = if
BTB_addr L@ byte/sector W@ u* BTB_addr L!
FAT_addr L@ byte/sector W@ u* FAT_addr L!
RDE_addr L@ byte/sector W@ u* RDE_addr L!
RDE_addr L@ USER_addr L!
then
else
first_sector L@ byte/sector W@ u* BTB_addr L!
first_sector L@ reserve_sector W@ + byte/sector W@ u* FAT_addr L!
num_fat W@ sector/fat W@ u* byte/sector W@ u* FAT_addr L@ + RDE_addr L!
root_entry W@ 20 u* RDE_addr L@ + USER_addr L!
then        
;

: to_decimal   \ ( n1 -- n2 ) convert hex(n1) to 4-digit(decimal)(n2)
0 tmp W!
2710 swap over 
5 0 do
u/mod dup 0> if  1 tmp W! .hex 
else tmp W@ if 0> .hex 
else drop 
then                               
then                   
swap a u/ swap over
loop
3drop
;

: conv_value ccs W@ 0= if byte/sector W@ u* then ;      \ if SDSC and SDHC(ccs=0) change to address-value 

: file_name    \ display filename and extention
8 0 do dup C@ dup 20 > if emit else drop then 1+ loop
." ."
3 0 do dup C@ dup 20 > if emit else drop then 1+ loop
drop
;

: cluster_to_sector                      \ ( cluster-number --> sector-number)
2 - sector/cluster W@ u*                  \ ( (cluster_num - 2) X sector/cluster )
sdhc W@ if ccs W@ if USER_addr L@ +
else USER_addr L@ byte/sector W@ u/ + 
then  
else
USER_addr L@ byte/sector W@ u/ +   
then
;

wvariable sector_num

: sector_read      \ ( -- address)   copy sector-data to sd_buf
sector_num W@                         
ccs W@ 0= if byte/sector W@ u* then
block_read
clear_buff_ptr
sector_num dup W@ 1+ swap W!       \ prepare next sector-number   
sd_buf W@       
;

\ display characters inside LFN's entry
: disp_char         \ ( RED-entry-address charcter-number offset -- )
rot + swap 0 do dup C@ dup ff < if emit else drop then 2+ loop drop
;

: load_LFN          \ ( RDE-entry-address -- ) display LFN 
begin
     20 -
     dup sd_buf W@ < if tmp1 W@ 2- conv_value RDE_addr L@ + block_read drop sd_buf W@ 1e0 + then \ read out previous sector 
     dup 5 1 disp_char dup 6 e disp_char dup 2 1c disp_char
     dup C@ 40 and 40 =    
until
drop
tmp1 W@ 1- conv_value RDE_addr L@ + block_read    \ read original-sector
;                

: disp_file_name
dup 6 + C@ 7e = swap c + C@ 0 = or   
            if dup load_LFN \ display LFN

            else dup dup  
                 c + C@ 8 and 0= if 8 bounds do i C@ dup 20 = if drop else emit then loop \ upper
                 else 8 bounds do i C@ dup 20 = if drop else 20 or emit then loop \ lower
                 then ." ."
                 dup dup 8 + swap
                 c + C@ 10 and 0= if 3 bounds do i C@ dup 20 = if drop else emit then loop \ upper
                 else 3 bounds do i C@ dup 20 = if drop else 20 or emit then loop    \ lower
                 then
            then
;                                      

: loader_file    \ ( -- ) display file-list
RDE_addr L@ block_read
1 tmp W!        \ line number 
1 tmp1 W!

sd_buf W@ 
begin
     dup C@ e5 = if 20 + dup sd_buf W@ 1ff + > if drop tmp1 W@ conv_value RDE_addr L@ +   
                                           block_read tmp1 dup W@ 1+ swap W! sd_buf W@
                                        then 0
                 else dup C@ 0= if 1 
                         else dup b + C@ f <> if tmp dup W@ dup to_decimal ."    " 1+ swap W!                                                      
                                                 dup disp_file_name cr
                                              then  
                                              20 + dup sd_buf W@ 1ff + > if  
                                                  drop tmp1 W@ conv_value RDE_addr L@ + 
                                                  block_read tmp1 dup W@ 1+ swap W! sd_buf W@ 
                                                  then
                                              0
                             then
                 then
until
drop
;

\ sd_buf end check
: sd_buf_end? sd_buf W@ - 200 = if 1 else 0 then ;   \  (n -- t/f)  n:c-addres   t:sd_bufer end f:not end
  
: (sdread)         \ ( n --  )  n:cluster_number   copy sectors for cluster_number to sd_buf amd route to free cog
cluster_to_sector sector_num W! sector_read
begin
\ skip from "\" to 0x0d                             
     C@++ dup 5c = if drop begin C@++ over 
                                 sd_buf_end? if 2drop sector_read 0 else d = then
                           until
                           0
\ skip from "{" to "}"
                   else dup 7b  = if drop begin C@++ over sd_buf_end?                                                 
                                                if 2drop sector_read 0 
                                                else 7d = 
                                                then 
                                          until
                                          0
\ file end?                                           
                                  else dup 0= if dictend W@ 200 - here W@ - . ." b free"
                                                 1
\ character? 
                                              else dup a = if drop dup sd_buf_end?
                                                              if drop sector_read then
                                                              0
                                                           else  emit                                                                                        
                                                                dup sd_buf_end? if drop sector_read then
                                                                 0
                                                           then
                                              then             
                                  then                                                                                                                                           
                   then
until           
;

wvariable sector_num
                            
: sector_read      \ ( -- address)   copy sector-data to sd_buf
sector_num W@                         
ccs W@ 0= if byte/sector W@ u* then
block_read
clear_buff_ptr
sector_num dup W@ 1+ swap W!       \ prepare next sector-number   
sd_buf W@       
;

\ sd_buf end check
: sd_buf_end? sd_buf W@ - 200 = if 1 else 0 then ;   \  (n -- t/f)  n:c-addres   t:sd_bufer end f:not end
  
: (sdread)         \ ( n --  )  n:cluster_number   copy all sector for cluster_number to sd_buf amd route to afree cog
cluster_to_sector sector_num W! sector_read
begin
\ skip from "\" to 0x0d                             
     C@++ dup 5c = if drop begin C@++ over 
                                 sd_buf_end? if 2drop sector_read 0 else d = then
                           until
                           0
\ skip from "{" to "}"
                   else dup 7b  = if drop begin C@++ over sd_buf_end?                                                 
                                                if 2drop sector_read 0 
                                                else 7d = 
                                                then 
                                          until
                                          0
\ file end?                                           
                                  else dup 0= if dictend W@ 200 - here W@ - . ." bytes free"
                                                 1
\ character? 
                                              else dup a = if drop dup sd_buf_end?
                                                              if drop sector_read then
                                                              0
                                                           else  emit                                                                                        
                                                                dup sd_buf_end? if drop sector_read then
                                                                 0
                                                           then
                                              then             
                                  then                                                                                                                                           
                   then
until
2drop          
;

\ copy RDE-block that file's entry exist to sd_buf 
: search       \ ( n -- address ) n:search file's line number   address:RDE-entry-address on sd_buf
RDE_addr L@ block_read
1 tmp W!
tmp1 W!         \ input line number
sd_buf W@ 
begin
     dup C@ e5 = if 20 + dup sd_buf W@ 1ff + > if drop tmp W@ conv_value RDE_addr L@ +   
                                           block_read tmp dup W@ 1+ swap W! sd_buf W@
                                        then 0
                  else dup b + C@ f <> if tmp1 W@ 1 = if 1
                 
                                                     else tmp1 dup W@ 1- swap W!
                                                       20 + dup sd_buf W@ 1ff + > if
                                                                                drop tmp W@ conv_value RDE_addr L@ +
                                                                                block_read tmp dup W@ 1+ swap W! sd_buf W@
                                                                                then
                                                       0
                                                     then 
                                      else
                                             20 + dup sd_buf W@ 1ff + > if  
                                                  drop tmp W@ conv_value RDE_addr L@ + 
                                                  block_read tmp dup W@ 1+ swap W! sd_buf W@ 
                                                  then
                                             0
                                      then  
                 then
until
;

: sdls
0 _crf W! 
sd_init 
tmp W@ 100 = if exit then
collect_info ." - File list -" cr cr loader_file
tmp W@ 1 = if ." no file" cr cr exit
           else tmp W@ 1- cr  0 tmp1 W!
               begin
                      ."  Loading file number (q if quit) > "
                      begin
                           key dup 30 < if d = if tmp1 W@ 0> if 1 else ."  Loading file number > " 0 then 
                                               else 0 
                                               then
                                        else dup 30 39 between if dup emit 30 - tmp1 dup W@ 1+ swap W! 0 
                                                               else dup 71 = if emit drop cr cr exit
                                                                        else emit tmp1 W@ 0 do drop loop 0 tmp1 W!
                                                                             ."  incorect input" cr 
                                                                             ."  Input file number > " 0
                                                                        then      
                                                               then
                                        then                                                 
                      until
\ convert characters to number(hex)                      
                      0 tmp1 W@ 0 do i 0= if + swap 
                                          else i 0 do a u* loop + swap 
                                          then 
                                  loop swap  
                      0 tmp1 W!
                      dup 0=
                      if drop ."  Not zero" cr cr 0 
                      else 2dup < if ."  not march" cr cr drop 0
                                  else search 1a + W@
                                       cogid nfcog iolink (sdread) d emit d emit cogid iounlink
                                       drop cr 1
                                  then
                      then
               until
 
           then
;
