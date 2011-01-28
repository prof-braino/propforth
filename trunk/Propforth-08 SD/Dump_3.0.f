\ fl
\ 2010/12/30 eeDump modified about display for more than address 0x10000

{ 
: .long dup 10 rshift .word .word ;
: _sttop 2e _cv ;
: _stptr 5 _cv ;  
: st? ." ST: " _stptr COG@ 2+ dup _sttop < if _sttop swap - 0 do _sttop 2- i -  COG@ .long space loop else drop then cr ;
0 _crf W!
}
wvariable _buf

\ Display contents inside HUB-ram
: ramDump       \ (address -- )
." ram address 0x" dup .word cr
."      " 10 0 do i . ."  " loop cr
dictend W@ 10 - _buf W!  

20 0 do
     i 10 u* dup 10 < if ." 00" . else dup 100 < if ." 0" . else . then then     \ address     
     10 0 do dup C@ _buf W@ i + C! 1+ loop    
     _buf W@ 10 0 do dup i + C@ .byte space loop drop   
     ."   "
     _buf W@ 10 0 do dup i + C@ dup  20 < if ." ." drop else dup  7e > if ." ." drop else emit then then loop drop    

     cr     
     loop
     drop
;
        
\ Display contents inside eeprom
: eeDump       \ (address -- )
." eeprom address 0x" dup 10000 < if dup .word else dup dup 10 rshift .hex .word then cr
."      " 10 0 do i . ."  " loop cr
dictend W@ 10 - _buf W!  

20 0 do                  
     i 10 u* dup 10 < if ." 00" . else dup 100 < if ." 0" . else . then then     \ address     
     10 0 do dup EC@ _buf W@ i + C! 1+ loop    
     _buf W@ 10 0 do dup i + C@ .byte space loop drop   
     ."   "                                                                                                                                                                                                                 
     _buf W@ 10 0 do dup i + C@ dup  20 < if ." ." drop else dup  7e > if ." ." drop else emit then then loop drop    
     cr
     
     loop
     drop
;
     
{
Display 1-Block(512bytes) on ram's contents
sample: 
 address ramDump  (address is hex)

Display 1-Block(512bytes) on eeprom's contents
sample:
 address eeDump  (address is hex)

}