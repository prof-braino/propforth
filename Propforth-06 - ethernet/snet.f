fl

fswrite snet.f

\ a simple terminal which interfaces to the a channel
\ term ( n1 n2 -- ) n1 - the cog, n2 - the channel number
[if term
: term over cognchan min
	." Hit CTL-F to exit comterm" cr
	>r >r cogid 0 r> r> (iolink)
	begin key dup 6 = if drop 1 else emit 0 then until
	cogid iounlink ;
]

: snet D C E100 4 startserialcog E dup pinlo dup pinout 1 delms dup pinhi pinin 10 delms 4 0 term ;


...
