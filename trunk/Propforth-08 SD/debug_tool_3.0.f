fl

: value dup .byte space ;
0 _crf W!

0 constant _sd_cs
1 constant _sd_di        \ connected SD's di
2 constant _sd_clk
3 constant _sd_do        \ connected SD's do

wvariable tmp
wvariable sdhc
wvariable ccs
wvariable sd_buf

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

: card_alive?_debug            
     _sd_cs_out_l
     49 sd_shift_out                    \ CMD9    get csd
     0 4 0 do dup sd_shift_out loop drop
     1 sd_shift_out
     dummy
     0 tmp W!

     ." get CSD-response to check card_alive " cr ." [ "  
     begin sd_shift_in value 0= 
          tmp W@ 64 > if drop 1 else tmp dup W@ 1+ swap W! then           
     until
     ."  ]" 
     tmp W@ 64 > 
     if
          ."  abort" cr
          ." This SD-CARD is not initialized or no card. " cr 
          _sd_cs_out_h

     else      
          dummy
          begin sd_shift_in fe = until       \ start-byte for data token
          10 0 do sd_shift_in drop loop      \ data block
          
          begin sd_shift_in ff = until      \ drop crc
          
          dummy
          _sd_cs_out_h
          ." It's ok." cr
          ." This SD-CARD is already initialized. " cr 
     then
     cr
; 

: sd_init_debug
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
." response for CMD0 [ "                  
begin sd_shift_in value 1 = if 1 
                      else tmp dup W@ 1+ swap W! tmp W@ 100 = if ." .. ] abort" cr ." error: no card" cr cr exit 
                                                              else 0 
                                                              then 
                      then 
until
." ]" cr
dummy

48 sd_shift_out                    \ CMD8
0 2 0 do dup sd_shift_out loop drop
1 sd_shift_out
aa sd_shift_out
87 sd_shift_out

\ Response for CMD8
." response for CMD8 [ " 
begin sd_shift_in value dup 1 = if drop 1 
                                else 5 = if ." ] CMD8 reject" cr begin
                                               ." CMD55 issue" cr 
                                               77 sd_shift_out                    \ CMD55
                                               0 4 0 do dup sd_shift_out loop drop
                                               1 sd_shift_out
                                               3 0 do sd_shift_in drop loop        \ skip response
                                               dummy
                                               ." ACMD41 issue" cr
                                               69 sd_shift_out                    \ ACMD41
                                               0 4 0 do dup sd_shift_out loop drop
                                               1 sd_shift_out
                                               ." response for ACMD41" cr ." [ " 
                                               5 0 do sd_shift_in value 0= if 4 seti 1 
                                                                                     else i 4 = if 0 then 
                                                                                     then 
                                                   loop
                                               
                                               ."  ]" cr
                                               dummy
                                            until
                                            ." SDSC initialize success" cr cr
                                            exit
                                          then
                                          0 
                                then 
until
." ]"
cr 
2 0 do sd_shift_in drop loop
sd_shift_in 
sd_shift_in 
aa = if 1 = if 1 else 0 then else drop 0 then
." accept CMD8" cr
if 
     ." CMD55 & ACMD41 issue" cr
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
          ." [ "
          5 0 do sd_shift_in value 0= if 4 seti 1 else i 4 = if 0 then then loop
          ." ]" cr
          dummy
     until
     ." CMD58 issue" cr
     7a sd_shift_out                    \ CMD58
     0 4 0 do dup sd_shift_out loop drop
     1 sd_shift_out
     ." [ "
     begin sd_shift_in value 0= until
     ." ]" cr
     ." get CardCapacityStatus of OCR [ "
     sd_shift_in dup .byte ."  ]" cr                       \ Get CardCapacityStatus of OCR
     4 0 do sd_shift_in drop loop
     dummy
     40 and 0= if 0 ccs W! else 1 ccs W! then
          
else
     ." CMD55 & ACMD41 issue" cr
     begin
          77 sd_shift_out                    \ CMD55
          0 4 0 do dup sd_shift_out loop drop
          1 sd_shift_out
          3 0 do sd_shift_in drop loop        \ skip response
          dummy

          69 sd_shift_out                    \ ACMD41
          0 4 0 do dup sd_shift_out loop drop
          1 sd_shift_out
          ." [ "
          5 0 do sd_shift_in value 0= if 4 seti 1 else i 4 = if 0 then then loop
          ." ]" cr
          dummy
     until                         

then
     ." get CSD" cr
     49 sd_shift_out                    \ CMD9
     0 4 0 do dup sd_shift_out loop drop
     1 sd_shift_out
     dummy
     ." check response for request of CSD [ "  
     begin sd_shift_in value 0= until
     ." ] It's ok" cr cr
     dummy
     ." check start-byte for data token [ "  
     begin sd_shift_in value fe = until      \ start-byte for data token
     ." ] It's ok" cr cr
     sd_shift_in ." CSD structure [ " dup .byte ."  ]" cr
     f 0 do sd_shift_in drop loop         \ data block
     begin sd_shift_in ff = until      \ drop crc          
     dummy
     40 and 40 = if 1 sdhc W! ." SDHC initialize success" cr cr else ." SDSC initialize success" cr cr then
 _sd_cs_out_h
;


: cid_debug     \ debug cid
cr
." Raw data for Card IDentification Register(CID)" cr cr
_sd_cs_out_l
     4a sd_shift_out                    \ CMD10
     0 4 0 do dup sd_shift_out loop drop
     1 sd_shift_out
     dummy
     ." check response for request of CID[ "  
     begin sd_shift_in value 0= until
     ." ] It's ok" cr cr
     dummy
     ." check start-byte for data token[ "  
     begin sd_shift_in value fe = until     \ start-byte for data token
     ." ] It's ok" cr cr
     ."  ManufactureID      "     
     sd_shift_in .byte cr
     ."  OEM/AppricationID  "
     sd_shift_in .byte space sd_shift_in .byte space cr
     ."  ProductName        "
     5 0 do sd_shift_in .byte space loop cr
     ."  ProductRev         "
     sd_shift_in .byte space cr
     ."  SerialNumber       "
     4 0 do sd_shift_in .byte space loop cr
     ."  ManufacturingDate  "
     sd_shift_in .byte space sd_shift_in .byte
     sd_shift_in drop
     begin sd_shift_in ff = until     \ drop crc
     
     dummy
_sd_cs_out_h
cr cr
;
   
: csd_debug     \ display csd
cr
." Raw data for Card Specific Data register(CSD)" cr cr
_sd_cs_out_l

     49 sd_shift_out                    \ CMD9
     0 4 0 do dup sd_shift_out loop drop
     1 sd_shift_out
     dummy
     ." check response for request of CSD[ "  
     begin sd_shift_in value 0= until
     ." ] It's ok" cr cr
     dummy
     ." check start-byte for data token[ "  
     begin sd_shift_in value fe = until      \ start-byte for data token
     ." ] It's ok" cr cr

     b 0 do sd_shift_in .byte space loop
     5 0 do sd_shift_in drop loop
     
     begin sd_shift_in ff = until      \ drop crc
          
     dummy
_sd_cs_out_h
cr  cr
; 
