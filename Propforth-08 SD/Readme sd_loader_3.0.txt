2011/1/3
sd_loader_3.0 on PropForth4.0a

Inside files
About_sd_viewer.pdf    Simplified explanation about FAT
debug_tool_3.0         debug tool for SD's troubles      (can name be SD-debug-tool?)
curcuit0010.jpg        curcuit diagram of SD I/F (does I/F mean "interface"? If so, please replace with "interface") (reference for this? What source told you how to hook up the circuit?)
DSCN8043               Photo of SD I/F
Dump_3.0.f             Dump code for ram/eeprom  (commented out "fl" because of saving on SD)
LogicAnalyzer_3.0.f    LogicAnalyzer  (commented out "fl fswrite LogicAnalyzer.f ..." becuse of saving on SD)  (need more explanaition on why things were commented out)

Readme_sd_loader_3.0   this file
sd_loader.txt          Source code for sd_loader_3.0.f
                           This file Cannot load because of overflow input-buffer. Contents is same as sd_loader_3.0.f except for extra spaces. (Pleas explain why this is here if it cannot load)
sd_loader_3.0.f        sd_loader(Loadable file)
sd_viewer_3.0.f 

                  

====================================================================================================================
Hardware
Propeller Board  Using ProtpBoard. I think sd_viewer also works demoBoard and schmartboard.

SD-CARD(SDSC,SDHC, not MMC)
  finished check 256M/512M/1G/2G/4G/16G
  If you formatted SD-CARDs by Windows, please re-format by maker's utility or device's(camera etc) menu.
  Formatting by Windows, some fundamental value is changed.
  sd_viewer may works finely or not at all.
  I don't know it.
  
SD-CARD adaptor (attached my SD-CARD-I/F's photo and curcuit diagram as sample)  (please inidcate reference)
  I think better that resistor(10kohm) and capacitor(0.1uF) connect near by SD-CARD adaptor as possible
  Connecting wires between [cs,di,do,clk] and Propeller's pin.   Wires is better to be short. ( 10cm on my I/F)

Connect wires 
current connection is below;
SD-CARD    Propeller
   CS  ---  P0
   DI  ---  P1
   CLK ---  P2
   DO  ---  P3
Please change wire-connection to fit your hardware. (please indicate location of r pins definitions in code in case pins 0-3 are not available)

====================================================================================================================

Installe PropForth.spin to eeprom and saving fs.f
Execute power-reset on propellerboard.
      
If operation is strange, check troubleshoot.
 When no reply, check next troublrshoot.
====================================================================================================================
Please 3 files(sd_viewer_3.0.f, LogicAnalizer_3.0.f, Dump_3.0.f) in blank SD-card.
Or delete all files on its SD-card.
I don't recommend formatting by Windows. 
Device's(camera, etc) format is ok.
Formatted SD-card by Windows may work or not. I don't know.

Loadable file-size is within 1 cluster-size.
How to check 1 cluster-size: Select "format" on Windows and watch "allocation unit size" on format dialog.
                             
sd_viewer_3.0.f is 21kb.So 1 cluster size need 32kb.

Power reset

 RESET Prop0 Cog6 ok

(sd_loader_3.0.f deleted spaces from sd_loader_3.0.txt to be able to load by WORD"fl". )
Loading sd_loader_3.0.f

   ..
displaying source list of sd_loader_3.0.f
   ..                          

Prop0 Cog6 ok   (using Kingston2G SDSC)
sdls

SDSC initialize success

- File list -

1   LogicAnalyzer_3.0.f
2   Dump_3.0.f
3   sd_viewer_3.0.f

 Loading file number (q if quit) > 3
      ..
displaying source list of sd_viewer_3.0.f
      ..
Prop0 Cog0 ok
     120A bytes free

Prop0 Cog6 ok
            
viewer

 -- viewer works fine --




Caution:
File inside SD-card comment out WORD"fl fswrite ...".

I write Loadable file-size is within 1 cluster-size.
But sd_loader_1.0a don't check cluster-end.   When it find out data-terminator(0x00),loading finish.
If file-size is more than 2 cluster-size, it is ok in case of continuous cluster-chain.
If save/delete is repeated, no-continuous cluster-chain cause load-trouble.
 
====================================================================================================================
 
 
Troubleshoot       (using SD is Kingston2G.) 
 
Execute power-reset  
Loading debug_tool.f.

Prop0 Cog6 ok
card_alive?_debug
get CSD-response to check card_alive
[ FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF  ] abort
This SD-CARD is not initialized or no card.

Prop0 Cog6 ok

When card_alive?_debug execute, please check your SD-CARD's hardware in case of different result.

********************************************************************************************************************

If ok, next

Prop0 Cog6 ok
sd_init_debug
response for CMD0 ( FF 01 ]
response for CMD8 [ FF 01 ]
accept CMD8
CMD55 & ACMD41 issue
[ FF 05 FF FF FF ]
[ FF 01 FF FF FF ]
[ FF 01 FF FF FF ]
[ FF 01 FF FF FF ]
[ FF 01 FF FF FF ]
[ FF 01 FF FF FF ]
[ FF 01 FF FF FF ]
[ FF 01 FF FF FF ]
[ FF 01 FF FF FF ]
[ FF 01 FF FF FF ]
[ FF 01 FF FF FF ]
[ FF 00 ]
CMD58 issue
[ FF 00 ]
get CardCapacityStatus of OCR [ 80 ]
get CSD
check response for request of CSD [ FF 00 ] It's ok

check start-byte for data token [ FE ] It's ok

CSD structure [ 00 ]
SDSC initialize success

Prop0 Cog6 ok



-------------------------------------------------------------------------------------------------------------------------------
Next check to get CSD's raw data

Prop0 Cog6 ok
csd_debug

Raw data for Card Specific Data register(CSD)

check response for request of CSD[ FF 00 ] It's ok

check start-byte for data token[ FE ] It's ok

00 2E 00 32 5B 5A 83 A9 FF FF FF

Prop0 Cog6 ok

Please read SD's specification PDF to know value's meaning 
 
-------------------------------------------------------------------------------------------------------------------------------
Next check to get CID's raw data

Prop0 Cog6 ok
cid_debug

Raw data for Card IDentification Register(CID)

check response for request of CID[ FF 00 ] It's ok

check start-byte for data token[ FE ] It's ok

 ManufactureID      02
 OEM/AppricationID  54 4D
 ProductName        53 44 30 32 47
 ProductRev         41
 SerialNumber       A3 3B C9 2F
 ManufacturingDate  00 94

Prop0 Cog6 ok

Please read SD's specification PDF to know value's meaning 
 