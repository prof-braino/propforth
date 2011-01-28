fl

\
\ After getting norom, and com working the 2 together
\
\ load this file
\ run 0 onboot
\ 5 0 term
\
\
\

fswrite comnorom.f

hex

1 wconstant  build_comnorom

fsload com.f
fsload norom.f


: _ob onboot ;
: onboot
	 _ob 10 delms
	2 _finit andnC!
	_finit W@ 1 and if
\
\ different prototype setup
\		C D E F rambootnx
\		c" C D E 5 commaster" 5 cogx

		8 9 A B rambootnx
		c" 8 9 A 5 commaster" 5 cogx
		10000 0 do 7 cogio comstate@ 4 = if 2 _finit orC! leave then loop
	else
		c" 1C 1D FF 5 comslave" 5 cogx 10 delms
		10000 0 do 5 cogio comstate@ 4 = if 2 _finit orC! leave then loop
		5 0 do i 0 5 i (ioconn) loop
	then
;		


: _or onreset ;
: onreset
	_finit W@ 3 and 2 = cogid 0 4 between and if
\ if this is a slave cog 0 - 4, reconnect to the channel
		cogid 0 5 cogid (ioconn) _or
	else 
		_or
	then ;

...
