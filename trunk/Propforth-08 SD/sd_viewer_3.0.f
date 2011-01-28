\ sd_viewer_2.4 for PropForth4.0a


wvariable time_value 0 c, a c, c c, d c, f c, 14 c, 19 c, 1e c, 23 c, 28 c, 2d c, 32 c, 37 c, 3c c, 46 c, 50 c, 
wvariable time_unit 1 c, a c, 64 c, 1 c, a c, 64 c, 1 c, a c,
wvariable rate_unit 64 c, 1 c, a c, 64 c,

\ displar Block(generally 512byte)
\    ( address-value -- )  <-- SDSC
\    ( sector-number -- )  <-- SDHC on ccs=1
\    ( address-value -- )  <-- SDHC on ccs=0
\ fl
: Block     
block_read
."      " 10 0 do i . ."  " loop cr
sd_buf W@
20 0 do
     i 10 u* dup 10 < if ." 00" . else dup 100 < if ." 0" . else . then then       \ address
     dup 10 0 do dup C@ .byte space 1+ loop drop        \ data
     ."   "
     dup 10 0 do dup C@ dup 20 < if ." ." drop else dup  7e > if ." ." drop else emit then then 1+ loop drop    \ ascii
     10 +
     cr
     loop
;

\ ( n1 -- n2 ) convert n1(hex) to n2[character(1,2,3,4,5,6,7,8,9,10,11,12)]   
: month        
f and 30 + dup 39 > if dup 3a = if ." 10" drop else dup 3b = if ." 11" drop else ." 12" drop then then else emit then
;

: cid     \ ( -- ) displaty cid
." Card IDentification Register(CID)" cr
_sd_cs_out_l
     4a sd_shift_out                    \ CMD10
     0 4 0 do dup sd_shift_out loop drop
     1 sd_shift_out
     dummy
     begin sd_shift_in 0= until
     dummy  
     begin sd_shift_in fe = until     \ start-byte for data token

     ."  ManufactureID      "     
     sd_shift_in .byte cr
     ."  OEM/AppricationID  "
     sd_shift_in sd_shift_in swap emit emit cr
     ."  ProductName        "
     5 0 do sd_shift_in emit loop cr
     ."  ProductRev         "
     sd_shift_in dup 4 rshift .hex ." ." .hex cr
     ."  SerialNumber       "
     4 0 do sd_shift_in .byte loop cr
     ."  ManufacturingDate  "
 
     sd_shift_in 4 lshift sd_shift_in dup 4 rshift rot or 7d0 + to_decimal ." /" month cr
     sd_shift_in drop
     begin sd_shift_in ff = until     \ drop crc
     
     dummy
_sd_cs_out_h
;

: to_decimal_dot    \ ( n1 -- n2 ) convert hex(n1) to 4-digit(decimal)(n2) with dot
0 tmp W!
3e8 swap over
4 0 do
     i 3 = if ." ." then u/mod dup 0> if 1 tmp W! .hex else tmp W@ if 0> .hex else drop then then swap a u/ swap over
loop
3drop
;

: csd     \ ( -- ) display csd
." Card Specific Data register(CSD)" cr
_sd_cs_out_l
     49 sd_shift_out                    \ CMD9
     0 4 0 do dup sd_shift_out loop drop
     1 sd_shift_out
     dummy
     begin sd_shift_in 0= until
     dummy
     begin sd_shift_in fe = until      \ start-byte for data token

     sd_shift_in drop           \ skip
     ."  Access Time        "
     sd_shift_in dup dup 78 and 3 rshift time_value 2 + + C@     \ access time
     swap 7 and time_unit 2 + + C@ u* to_decimal_dot
     7 and dup 3 < if ." nsec" else 6 < if ." usec" else ." msec" then then cr
          
     sd_shift_in drop           \ skip
     ."  Transfer Speed     " 
     sd_shift_in dup dup 78 and 3 rshift time_value 2 + + C@     \ transfer speed
     swap 7 and rate_unit 2 + + C@ u* to_decimal_dot
     7 and 0= if ." kbit/s" else ." Mbit/s" then  cr
     
     sd_shift_in drop           \ skip
     ."  Data Block Length  " 
     sd_shift_in f and dup tmp1 W! 1 swap lshift to_decimal ." byte" cr

     sdhc W@ if sd_shift_in drop           \ skip
                sd_shift_in 3f and 10 lshift 
                sd_shift_in 8 lshift or
                sd_shift_in or        
             \   ."  Capacity           "  1+ 200 u* 400 u* 100000 u/ to_decimal ." Mbyte" cr
                ."  Capacity           "  1+ 200 u* 400 u/ to_decimal ." Mbyte" cr
             else 
                ."  Capacity           " 
                sd_shift_in 3 and a lshift          \ C_SIZE 
                sd_shift_in 2 lshift or
                sd_shift_in c0 and 6 rshift or 1 +
                
                sd_shift_in 3 and 1 lshift           \ C_SIZE_MULT
                sd_shift_in 7 rshift or 2 + 
     
                1 swap lshift u* 1 tmp1 W@ lshift u* 100000 u/ to_decimal ." Mbyte" cr 
             then        
     
     5 0 do sd_shift_in drop loop
     
     begin sd_shift_in ff = until      \ drop crc
          
     dummy
_sd_cs_out_h
; 

: conversion   \ ( n1 -- n2) convert byte(n1) to Mbyte/kbyte/byte(n2)
dup 0<> 
if
     100000 u/mod dup 0> if to_decimal ." M" drop 
                         else drop 400 u/mod dup 0> if to_decimal ." k" drop
                                                    else drop to_decimal
                                                    then
                         then
else
     drop ." 0"
then
 ." byte"         
;

: card_alive?              \ ( -- t/f )   zero if card is alive
     _sd_cs_out_l
     49 sd_shift_out                    \ CMD9    get csd
     0 4 0 do dup sd_shift_out loop drop
     1 sd_shift_out
     dummy
     0 tmp W!

     begin sd_shift_in 0= 
          tmp W@ 64 > if drop 1 else tmp dup W@ 1+ swap W! then           
     until
     tmp W@ 64 > 
     if
          _sd_cs_out_h
          1
     else      
          dummy
          begin sd_shift_in fe = until       \ start-byte for data token
          10 0 do sd_shift_in drop loop      \ data block
          
          begin sd_shift_in ff = until      \ drop crc
          
          dummy
          _sd_cs_out_h
          0
     then
;
  
: MBR     \ ( -- ) display MBR
."  MBR(Master Boot Record)" ."  Sector:0x0 " ." Address:0x0" cr cr
0 Block
;
: BTB     \ ( -- ) display BTB
."  BTB(BIOS Parameter Block)" ."  Sector:0x" first_sector L@ dup . 
." Address:0x" 
sdhc W@ if dup 200 u* . ccs W@ 0 = if 200 u* then
        else drop BTB_addr L@ dup .
        then
 cr cr Block
;
: FAT     \ ( -- ) display FAT
."  FAT(File Allocation Table)" ."  Sector:0x" first_sector L@ reserve_sector W@ + dup .
." Address:0x" 
\ sdhc W@ if dup 200 u* . ccs W@ 0 = if 200 u* then
sdhc W@ if dup byte/sector u* . ccs W@ 0 = if byte/sector u* then
        else drop FAT_addr L@ dup .
        then       
cr cr Block
;
: RDE     \ ( -- ) display RDE
."  RDE(Root Directory Entry)" ."  Sector:0x" first_sector L@ reserve_sector W@ + num_fat W@ sector/fat W@ u* + dup .
." Address:0x" 

sdhc W@ if dup byte/sector u* . ccs W@ 0 = if byte/sector u* then
        else drop RDE_addr L@ dup .
        then
cr cr Block
;

: info    \ ( -- ) display information (WORD"collect_info")
." SD-card Information"  cr
."  type               "
sdhc W@ if ." SDHC" else ." SDSC" then cr
."  firstSectorNumbers 0x" first_sector L@ . cr
."  bytePerSector      0x" byte/sector W@ . cr
."  sectorsPerCluster  0x" sector/cluster W@ . cr
."  reservedSectors    0x" reserve_sector W@ . cr
."  numberOfFATS       0x" num_fat W@ . cr
sdhc W@ if ."  rootDirCluster     0x" rootCluster L@ . cr
        else  ."  rootEntries        0x" root_entry W@ . cr              
        then
."  sectorsPerFAT      0x" sector/fat W@ . cr
."  bigTotalSectors    0x" total_sector L@ . cr

;

: disp_cluster      \ ( -- ) display first sector of cluster number
0 tmp W!
."  Input Cluster Number(hex) > "
begin
key dup 30 < if d = if tmp W@ 0> if 1 else 0 then else 0 then
             else dup 3a 40 between if drop 0
                                    else dup 47 60 between if drop 0
                                                           else dup 66 > if drop 0
                                                                         else dup emit tmp W@ 4 = if 5 0 do drop loop
                                                                                                     0 tmp W!
."  incorect input" cr                                                                                                                                                                                                           
."  Input Cluster Number(hex) > " 0                                                                                                                                                                                                                                                     
else todigit tmp dup W@ 1+ swap W! 0
then
                                                                         then
                                                           then
                                   then
             then                  
until
cr
tmp W@ 1 > if tmp W@ 1- 0 do swap i 1+ 4 u* lshift or loop then   \ convert data

dup 2 < if ." start cluster is from 2. Display Cluster 0x2 instead of 0x" dup . cr cr 2 then

." Cluster:0x" dup . ." Sector:0x" cluster_to_sector dup . ." Address:0x" byte/sector W@ u* dup . cr cr
sdhc W@ if ccs W@ if byte/sector W@ u/ then then
Block
;
   
: cluster_chain     \ (cluster-number -- ) display cluster-chain for sdsc   
dup .
begin
     sdhc W@ if 4 u* dup else 2 u* dup then   \ get offset from FAT start address
     byte/sector W@ u/ dup              \ get offset sector from FAT
     
     first_sector L@ + reserve_sector W@ +
     sdhc W@ 0= if byte/sector W@ u* then               \ get address(SDSC & SDHC[scc=0] or sector(SDHC[scc=1]
     
     block_read
     byte/sector W@ u* -                   \ get offset from target sector
     
     sdhc W@ if sd_buf W@ + L@ dup dup fffffff and fffffff = if 2drop 1 else . 0 then
             else sd_buf W@ + W@ dup dup ffff = if 2drop 1 else . 0 then
             then
until 
;

\ display characters inside LFN's entry
: disp_char         \ ( RED-entry-address charcter-number offset -- )
rot + swap 0 do dup C@ dup ff < if emit else drop then 2+ loop drop
;
  
: longname          \ ( RDE-entry-address -- ) display LFN 
begin
     20 -
     dup sd_buf W@ < if tmp W@ 2- conv_value RDE_addr L@ + block_read drop sd_buf W@ 1e0 + then     \ read out previous sector 
     dup 5 1 disp_char dup 6 e disp_char dup 2 1c disp_char
     dup C@ 40 and 40 =    
until
drop
tmp W@ 1- conv_value RDE_addr L@ + block_read    \ read original-sector

;                
      
: file_detail         \ (RDE-entry-address on sd_buf -- )  display file-detail on its entry
dup dup
\ DIR_Name
." Name                         "
c + C@ 8 and 0= if 8 bounds do i C@ dup 20 = if drop else emit then loop                 \ upper

                else 8 bounds do i C@ dup 20 = if drop else 20 or emit then loop         \ lower
                then
." ."
dup dup 8 + swap 
c + C@ 10 and 0= if 3 bounds do i C@ dup 20 = if drop else emit then loop            \ upper

                     else 3 bounds do i C@ dup 20 = if drop else 20 or emit then loop    \ lower
                     then
\ dup 6 + C@ 7e = if cr ."                        LFN:  " dup longname then        
dup dup 6 + C@ 7e = swap c + C@ 0 = or if cr ."                        LFN:  " dup longname then
cr cr
  
dup b +       \ get attribute's address
\ DIR_Attr
." Attribute                    "
C@ dup 1 and 1 = if ." READ_ONLY " then                  
dup 2 and 2 = if ." HIDDEN  " then
dup 4 and 4 = if ." SYSTEM  " then
dup 8 and 8 = if ." VOLUME_ID  " then
dup 10 and 10 = if ." DIRECTORY  " then
dup 20 and 20 = if ." ARCHIVE  " then
cr cr

." Type                         "
10 and 10 = if ." Directory" else ." File" then
cr cr

\ DIR_CrtTime
." Create Time                  "
dup e + W@
dup f800 and b rshift dup 0= if ." 00" drop 
                             else dup a < if ." 0" then to_decimal 
                             then ." :"
dup 7e0 and 5 rshift dup 0= if ." 00" drop 
                            else dup a < if ." 0" 
                            then to_decimal then ." :"
dup d + 
C@ 63 > if 1 else 0 then swap 
1f and 2 u* + dup 0= if ." 00" drop 
                    else dup a < if ." 0" 
                                 then 
                                 to_decimal 
                    then
." ." 
dup d + C@ dup 63 > if 64 - then 
to_decimal 
cr cr
 
\ DIR_CtrDate
." Create date                  "
dup 10 + W@
dup fe00 and 9 rshift 7bc + to_decimal ." /"
dup 1e0 and 5 rshift to_decimal ." /"
1f and dup 0= if ." 00" drop else to_decimal then

cr cr

\ DIR_LastAccDate
." Last Access Date             "
dup 12 + W@
dup fe00 and 9 rshift 7bc + to_decimal ." /"

dup 1e0 and 5 rshift to_decimal ." /"

1f and dup 0= if ." 00" drop else to_decimal then
cr cr

\ DIR_WrtTime
." Update Write time            "

dup 16 + W@
dup f800 and b rshift dup 0= if ." 00" drop else dup a < if ." 0" then to_decimal then ." :"

dup 7e0 and 5 rshift dup 0= if ." 00" drop else dup a < if ." 0" then to_decimal then ." :"

1f and 2 u* dup 0= if ." 00" drop else dup a < if ." 0" then to_decimal then 

cr 
cr

\ DIR_WrtDate
." Update Write date            "
dup 18 + W@
dup fe00 and 9 rshift 7bc + to_decimal ." /"
dup 1e0 and 5 rshift to_decimal ." /"
1f and dup 0= if ." 00" drop else to_decimal then
cr cr

\ DIR_FileSize
." File Size                    "
dup 1c + L@ conversion               
cr cr                                                 \ DIR_FileSize

\ DIR_FirstCluster
." Cluster chain(hex)         " 
1a + W@ dup 0>
if cluster_chain else drop then
cr cr
;


\ copy RDE-block that file's entry exist to sd_buf 
: search       \ ( n --  ) n:search file's line number
RDE_addr L@ block_read
1 tmp W!
\ tmp1          \ input line number
sd_buf W@ 
begin
     dup C@ e5 = if 20 + dup sd_buf W@ 1ff + > if drop tmp W@ conv_value RDE_addr L@ +   
                                           block_read tmp dup W@ 1+ swap W! sd_buf W@
                                        then 0
                  else dup b + C@ f <> if tmp1 W@ 1 = if file_detail 1
                 
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
      
: file    \ ( -- ) display file-list
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
                                                 dup file_name cr
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

\ tmp is input line_number+1  if 1, then no file
tmp W@ 
dup 1 > if     
cr ."  Input file number > "
0 tmp1 W!

 begin
     dup
     begin
          key dup 30 < if d = if   tmp1 W@ 0> if   1 else ."  Input file number > " 0 then else 0 then
                    else dup 39 > if drop 0
                                   else  dup emit tmp1 W@ 2 = if 3 0 do drop loop
                                                            0 tmp1 W!
                                                            ."  incorect input" cr 
                                                            ."  Input file number > " 0
                                                                                                                                                 
                                                          else  todigit tmp1 dup W@ 1+ swap W! 0 
                                                          then  
                                then  
                  then
     until
     tmp1 W@ 2 = if swap a u* + then dup tmp1 W!
     > if tmp1 W@ 0= if ."  zero is NG!!" cr ."  Input file number > " 0 tmp1 W! 0 
                     else drop 1 
                     then 
       else ."  not match" cr ."  Input file number > " 0 tmp1 W! 0 
       then         
 until
cr cr
search 
else ." no file" cr drop then
;


: address      \ ( -- ) display data-block by sd-card's address
."  Input Address(hex) > "
0 tmp W!
begin
     begin
          key dup 30 < if d = if tmp W@ 0> if 1 else 0 then else 0 then
               else dup 3a 40 between if drop 0
                    else dup 47 60 between if drop 0
                         else dup 66 > if drop 0
                              else dup emit tmp W@ 8 = if 9 0 do drop loop
          0 tmp W!
          ."  incorect input" cr 
          ."  Input Address(hex) > " 0                                                                                                                                                 
          else todigit tmp dup W@ 1+ swap W! 0
          then
          then
          then
          then
          then                  
until
tmp W@ 1 > if tmp W@ 1- 0 do swap i 1+ 4 u* lshift or loop then   \ convert data

dup 200 u/mod drop if drop 0 tmp W! ."  incorect input" cr ."  Input Address(hex) > " 0 else 1 then
until
sdhc W@ if ccs W@ 1 = if 200 u/ then then

cr cr       
Block
;
  
: menu         \ display menu
."  j             -- Display CSD" cr
."  k             -- Display CID" cr
."  l             -- Display SD-information" cr
."  h             -- memu list" cr
."  s(Address)    -- Single Block Read" cr
."  m             -- Master Boot Record" cr
."  b             -- BIOS Parameter Block" cr
."  f             -- File Allocation Table" cr
."  r             -- Root Directory Entry" cr
."  u             -- File Detail" cr
."  t             -- Display top sector of Cluster number" cr
."  q             -- Quit" cr
;
  
: viewer       \ main
card_alive?
if             \ when SD-CARD not initialize, execute initilaization for sd_viewer 
     sd_init
     tmp W@ 100 = if exit then
     collect_info 
then
cr menu cr ."  >"
begin

key dup emit cr dup
     6a = if drop csd 0 cr cr else dup
          6b = if drop cid 0 cr cr else dup
               68 = if drop cr menu 0 cr cr else dup
                    73 = if drop cr address 0 cr cr else dup
                         6d = if drop cr  MBR 0 cr cr else dup
                              62 = if drop cr  BTB 0 cr cr else dup
                                   66 = if drop cr  FAT 0 cr cr else dup
                                        72 = if drop cr  RDE  0 cr cr else dup
                                             75 = if drop cr file 0 cr cr else dup
                                                  6c = if drop cr info  0 cr cr else dup 
                                                       74 = if drop cr disp_cluster  0 cr cr else dup              
                                                            71 = if drop 1 else drop 0
                                                            then
                                                       then
                                                   then
                                             then     
                                        then
                                   then                                                                 
                              then
                         then 
                    then 
               then 
          then
     then 
."  >"                                                                   
until
;
     