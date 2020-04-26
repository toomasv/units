Red []
#include %units-code.red

;const: [
;	g: 9.80665 m/s2 ;gravity
;]

;SI base-dims: length (L), mass (M), time (T), electric current (I), absolute temperature (Θ), amount of substance (N) and luminous intensity (J)

base-dimension:    make vector! [0  0  0  0  0  0  0  0  0  0]

dims: reduce [                                                ;standard unit
	;BASIC
	'angle         make vector! [1  0  0  0  0  0  0  0  0  0] ;rad  radian
	;physics                                                   ;SI
	'mass          make vector! [0  1  0  0  0  0  0  0  0  0] ;kg   kilogram
	'length        make vector! [0  0  1  0  0  0  0  0  0  0] ;m    meter
	'time          make vector! [0  0  0  1  0  0  0  0  0  0] ;s    second
	'current       make vector! [0  0  0  0  1  0  0  0  0  0] ;A    amper
	'temperature   make vector! [0  0  0  0  0  1  0  0  0  0] ;K    kelvin
	'amount        make vector! [0  0  0  0  0  0  1  0  0  0] ;mol  mole
	'intensity     make vector! [0  0  0  0  0  0  0  1  0  0] ;cd   candela
	;finance
	'currency      make vector! [0  0  0  0  0  0  0  0  1  0] ;USD
	;information
	'information   make vector! [0  0  0  0  0  0  0  0  0  1] ;bit  shannon
	
	;DERIVED
	'area          make vector! [0  0  2  0  0  0  0  0  0  0] ;m2   
	'volume        make vector! [0  0  3  0  0  0  0  0  0  0] ;m3
	'frequency     make vector! [0  0  0 -1  0  0  0  0  0  0] ;s-1
	'velocity      make vector! [0  0  1 -1  0  0  0  0  0  0] ;m/s
	'acceleration  make vector! [0  0  1 -2  0  0  0  0  0  0] ;m/s2
	'bitrate       make vector! [0  0  0 -1  0  0  0  0  0  1] ;bit/s
	'force         make vector! [0  1  1 -2  0  0  0  0  0  0] ;N    newton
	'pressure      make vector! [0  1 -1 -2  0  0  0  0  0  0] ;Pa   pascal N/m2, kg/m*s2
	'momentum      make vector! [0  1  1 -1  0  0  0  0  0  0]
	'energy        make vector! [0  1  2 -2  0  0  0  0  0  0] ;J    joule
	'power         make vector! [0  1  2 -3  0  0  0  0  0  0] ;W    watt
	'density       make vector! [0  1 -3  0  0  0  0  0  0  0] ;kg/m3
	'vorticity     make vector! [1  0  0 -1  0  0  0  0  0  0] ;rad/s
	
	'charge        make vector! [0  0  0  1  1  0  0  0  0  0] ;C    coulomb  A*s
]

dimensions: make map! []
scales: make map! []

;================
;### CURRENCY ###
;================
set-scales/dim [
	USD:    #(CAD: 1.4 EUR: 0.91)   ;US dollar
	EUR:    #(PLZ: 4.56 CZK: 27)    ;euro

	;### CRYPTO ###
	;BTC:   #(EUR: 5670.5 ETH: 0.02291829) ;bitcoin
] dims/currency

;================
;### DISTANCE ###
;================
set-scales/dim [
	;metric
	m:      #(mm: 1000 cm: 100 dm: 10 km: .001);meter
	km:     #(mi: 1.609344)
	;internamtional
	p:      #(mm: (127 / 360 * _))  ;point
	pc:     #(p: 12)                ;pica
	;imperial
	inch:   #(th: 1000 pica: 6);
	th:     #(inch: 0.001)          ;thou
	ft:     #(inch: 12)             ;foot
	yd:     #(ft: 3)                ;yard
	ch:     #(yd: 22)               ;chain
	fur:    #(ch: 10)               ;furlong
	mi:     #(fur: 8)               ;mile
	lea:    #(mi: 3)                ;league
	ftm:    #(yd: 2.02667)          ;fathom
	cb:     #(ftm: 100)             ;cable
	nm:     #(cb: 10 m: 1852)       ;nautical miles
	li:     #(inch: 7.92)           ;link
	rd:     #(li: 25)               ;rod
] dims/length

;==============
;### WEIGHT ###
;==============
set-scales/dim [
	;metric
	kg:     #(g: 1000 ton: .001)    ;kilogram
	g:      #(mg: 1000)             ;gram
	;imperial
	st:     #(lb: 14)               ;stone
	qr:     #(lb: 28)               ;quarter
	cwt:    #(lb: 112)              ;(long) hundredweight
	lton:   #(cwt: 20 lb: 2240)     ;long-ton
	;avoirdupois
	gr:     #(mg: 64.79891)         ;grain
	dr:     #(gr: (11.0 / 32 + 27 * _) carats: 8.859);dram
	oz:     #(dr: 16)               ;ounce
	lb:     #(gr: 7000 oz: 16 dr: 256 kg: 0.45359237);pound
	US-cwt: #(lb: 100)              ;US hundredweight
	ston:   #(US-cwt: 20 lb: 2000)  ;short-ton
	;Troy
	dwt:    #(gr: 24 carats: 7.776) ;pennyweight
	ozt:    #(dwt: 20)              ;troy ounce
	lbt:    #(ozt: 12 oz: 13.17)    ;troy pound
] dims/mass

;============
;### TIME ###
;============
set-scales/dim [
	s:      #(ms: 1000 ns: 1000'000);second
	mn:     #(s: 60)                ;minute
	hr:     #(mn: 60)               ;hour
	dy:     #(hr: 24)               ;day
	wk:     #(dy: 7)                ;week
	yr:     #(dy: 365.25)           ;year
	
	fortnight:  #(dy: 14)
	olympiad:   #(yr: 4)
	lustrum:    #(yr: 5)
	indiction:  #(yr: 15)
	decade:     #(yr: 10)
	century:    #(yr: 100) 
	millennium: #(yr: 1000)
] dims/time

;===================
;### TEMPERATURE ###
;===================
set-scales/dim [	
	C:    #(F: (_ * 9.0 / 5 + 32))    ;Celsius °C
	K:    #(C: (_ - 237.15))          ;Kelvin
	F:    #(C: (_ - 32 * 5.0 / 9))    ;Fahrenheit °F
	;°R:    #(°C: (_ − 491.67 * ​5 / 9));Rankine
	;°De:   #(°C: (100 − (_ * ​2 / 3))) ;Delisle
	;°N:    #(°C: (_ * ​100 / 33))      ;Newton
	;°Ré:   #(°C: (_ * ​5 / 4))         ;Réaumur
	;°Rø:   #(°C: (_ − 7.5 * ​40 / 21)) ;Rømer
] dims/temperature

;=============
;### FORCE ###
;=============
set-scales/dim [
	N:      #("kg*m/s2" 1 dyn: 100000 )
	dyn:    #("g*cm/s2" 1)
] dims/force

;===================
;### INFORMATION ###
;===================
set-scales/dim [
	byte:    #(bit: 8 B: 1)
	crumb    #(bit: 2)
	nibble:  #(bit: 4)
	bit:     #(nat: 0.6931471805599455) ;shannon
	nat:     #(nit: 1 bit: 1.442695040888963) ;nepit
	dit:     #(ban: 1 deciban: 10 bit: 3.321928094887363 nat: 2.302585092994046) ;hartley
	trit:    #(bit: 1.584962500721156)
	kbit:    #(bit: 1000)
	Mbit:    #(bit: 1000'000)
	Gbit:    #(bit: 1000'000'000)
	Tbit:    #(bit: 1000'000'000'000)
	kB:      #(B: 1000)
	MB:      #(kB: 1000)
	GB:      #(MB: 1000)
	TB:      #(GB: 1000)
	Kibit:   #(bit: 1024)
	Mibit:   #(Kibit: 1024)
	Gibit:   #(Mibit: 1024)
	Tibit:   #(Gibit: 1024)
	KiB:     #(B: 1024)
	MiB:     #(KiB: 1024)
	GiB:     #(MiB: 1024)
	TiB:     #(GiB: 1024)
] dims/information

set-scales/dim [
	bps:     #("bit/s" 1)
	Kbps:    #(bps: 1000)
	Mbps:    #(Kbps: 1000)
	Gbps:    #(Mbps: 1000)
	Tbps:    #(Gbps: 1000)
	"B/s"    #("bit/s" 8)
	"KiB/s"  #("B/s" 1024 "bit/s" 8192)
	"MiB/s"  #("KiB/s" 1024)
	"GiB/s"  #("MiB/s" 1024)
] dims/bitrate

set-scales/dim reduce [
	quote rad: make map! compose [deg: (180 / pi) turn: (.5 / pi)]
	quote deg: make map! compose [rad: (pi / 180)]
	quote turn: make map! compose [deg: 360 rad: (2 * pi)]
] dims/angle

()
