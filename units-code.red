Red []

digit: charset "0123456789"
sci: [#"e" opt #"-" some digit]
num: [opt "-" some [digit opt "'"] opt [dot some [digit opt "'"]] opt sci]
upper: charset [#"A" - #"Z"]
lower: charset [#"a" - #"z"]
alpha: union upper lower

system/lexer/pre-load: function [src len /local n u][
	money: [copy u 3 upper #"$" copy n num (c: none f: "basic ")]
	dimensioned: [some alpha opt digit]
	compound: [dimensioned any [#"*" dimensioned]]
	related: [compound #"/" compound]
	measure: [
		copy n num copy u some alpha (c: none f: "basic ")
		opt [copy c [opt #"-" opt digit #"*" compound] (append u c)]
		opt [copy c [opt #"-" opt digit #"/" compound] (append u c)]
		opt [copy c [opt #"-" digit] (append u c)]
		opt [if (c) (f: "derive " u: rejoin ["{" u "}"])]
	]
	unit: [change [money | measure] (rejoin [#"(" f u #" " n #")"])]
	parse src [some [unit | skip]]
]

uctx: context [

	;=== local ops ====
	*=*:  :system/words/=
	*<*:  :system/words/<
	*>*:  :system/words/>
	*<=*: :system/words/<=
	*>=*: :system/words/>=
	;<> !NB ot used (i.e. long form only)
	+':   :system/words/+
	-':   :system/words/-
	*':   :system/words/*
	|':   get first find words-of system/words '/
	**':  :system/words/**
	
	;=== ops to use in DSL ===
	unit?: func [a][all [object? a a/dimension]]
	units?: func [a b][all [unit? a unit? b]]
	comparable?: func [a b][all [units? a b equal? a/dimension b/dimension]]
	comparable-symbols?: func [sym1 [word! string!] sym2 [word! string!]][
		equal? get-dimension sym1 get-dimension sym2
	]

	=:  make op! func [a b][either comparable? a b [equal? a/as b/symbol b/amount][equal? a b]]
	_<: make op! func [a b][either comparable? a b [lesser? a/as b/symbol b/amount][lesser? a b]] ;Dunno how to redefine < inside obj (i.e. without `set`)
	>:  make op! func [a b][either comparable? a b [greater? a/as b/symbol b/amount][greater? a b]]
	<=: make op! func [a b][either comparable? a b [lesser-or-equal? a/as b/symbol b/amount][lesser-or-equal? a b]]
	>=: make op! func [a b][either comparable? a b [greater-or-equal? a/as b/symbol b/amount][greater-or-equal? a b]]
	<>: make op! func [a b][either comparable? a b [not equal? a/as b/symbol b/amount][not equal? a b]]

	+: make op! func [a b][
		either comparable? a b [
			b': re-dimension a b
			b'/amount: a/amount +' b'/amount
			b'
		][a +' b]
	]
	-: make op! func [a b][
		either comparable? a b [
			b': re-dimension a b
			b'/amount: a/amount -' b'/amount
		][a -' b]
	]

	*: make op! function [a b][
		case [
			all [number? a unit? b] [
				make b compose [amount: (b/amount *' a)]
			]
			all [number? b unit? a] [
				make a compose [amount: (a/amount *' b)]
			]
			units? a b [relate a b '*]
			true [a *' b]
		]
	]
	/: make op! func [a b][
		case [
			all [number? a unit? b] [
				amount: b/amount *' 1.0 |' a
				make b compose [amount: (amount)]
			]
			all [number? b unit? a] [
				amount: a/amount *' 1.0 |' b
				make a compose [amount: (amount)]
			]
			units? a b [relate a b '/]
			true [a |' b]
		]
	]
	**: make op! function [a b][
		either all [unit? a number? b] [
			amount: a/amount **' b
			dimension: b *' copy a/dimension
			sym: make-symbol flatten a/parts dimension
			either word? sym [
				basic :sym amount
			][
				derive :sym amount
			]
		][a **' b]
	]
	relate: function [a b op][
		b': re-dimension a b
		switch op [
			* [
				amount: a/amount *' b'/amount
				dimension: a/dimension +' b/dimension
			]
			/ [	
				amount: divide a/amount *' 1.0 b'/amount
				dimension: a/dimension -' b/dimension
			]
		]
		sym: make-symbol unique append flatten a/parts flatten b'/parts dimension
		either word? sym [
			basic :sym amount
		][
			derive :sym amount
		]
	]

	;==================================
	standard: [USD kg m s A K mol cd bit]
	rise-error: func [msg][cause-error 'user 'message rejoin msg]

	seen: clear []
	resolve2: function [sym1 sym2 /with value /num n][
		n: any [n 1]
		if n *>* 20 [return false]
		value: any [value 1]
		either val: select scales/:sym1 sym2 [
			return val *' value
		][
			case [
				all [string? sym1 string? sym2] [
					obj1: derive :sym1 1
					obj2: derive :sym2 1
					obj: re-dimension obj2 obj1
					return obj/amount *' value
				]
				all [string? sym1 word? sym2][
					obj1: derive :sym1 1
					obj2: basic :sym2 1
					obj: re-dimension obj2 obj1
					return obj/amount *' value
				]
				true [
					append seen sym1
					foreach [sym val] scales/:sym1 [
						if not find seen sym [
							vals: scales/:sym
							if v: select vals sym2 [
								return v *' val *' value
							][
								append seen sym
							]
						]
					]
					foreach [sym val] scales/:sym1 [
						vals: scales/:sym 
						foreach [s v] vals [
							if not find seen s [
								return resolve2/with/num s sym2 v *' val *' value n +' 1
							]
						]
					]
				]
			]
		]
		false
	]
	resolve: func [sym1 sym2 /only][
		clear seen ; To avoid loops
		either comparable-symbols? sym1 sym2 [
			case [
				val: resolve2 sym1 sym2 [ ;First try this way..
					if not scales/:sym1 [put scales sym1 make map! copy []]
					put scales/:sym1 sym2 val 
					if not scales/:sym2 [put scales sym2 make map! copy []]
					put scales/:sym2 sym1 1.0 |' val 
				]
				val: resolve2 sym2 sym1 [ ;..and then the way around
					if not scales/:sym1 [put scales sym1 make map! copy []]
					put scales/:sym1 sym2 1.0 |' val
					if not scales/:sym2 [put scales sym2 make map! copy []]
					put scales/:sym2 sym1 val
				]
				only [false]
				true [rise-error ["Cannot compare " sym1 " with " sym2 "!"]]
			]
		][rise-error ["Cannot compare " sym1 " with " sym2 "!"]]
	]

	unit-value: function [sym obj /only][
		if not find obj/scale sym [
			either only [
				resolve/only obj/symbol sym
			][
				resolve obj/symbol sym
			]
			sync-scale obj
		]
		case [
			paren? obj/scale/:sym [
				do replace/deep copy obj/scale/:sym '_ obj/amount
			]
			true [obj/amount *' obj/scale/:sym]
		]
	]
	unit!: [
		type: 'simple
		symbol: none 
		amount: 1 
		scale: is [select scales symbol] 
		parts: none
		dimension: none
		as: func [sym /only][
			either only [
				unit-value/only sym self
			][
				unit-value sym self
			]
		]
	]

	adjust-unit: function [sym1 sym2 val dim /only][
		unless only [put scales/:sym1 sym2 val]
		if not paren? val [
			either scale: select scales sym2 [
				put scale sym1 1.0 |' val
			][
				put scales sym2 make map! reduce [sym1 1.0 |' val]
				put dimensions sym2 dim
			]
		]
	]

	as-unit: func ['sym obj][
		case [
			all [obj/scale obj/scale/:sym] [obj/as sym]
			resolve obj/symbol sym [
				sync-scale obj
				obj/as sym
			]
			true [rise-error ["Can't compare " sym " to " obj/symbol "!"]]
		]
	]
	
	to-unit2: func [sym obj][
		either string? sym [
			derive :sym obj/as :sym 
		][
			basic :sym obj/as sym 
		]
	]
	
	to-unit: func ['sym obj][
		case [
			all [obj/scale obj/scale/:sym] [to-unit2 sym obj]
			resolve obj/symbol sym [
				sync-scale obj
				to-unit2 sym obj
			]
			true [rise-error ["Can't compare " sym " to " obj/symbol "!"]]
		]
	]
	
	sync-scale: func [obj][
		if not equal? scales/(obj/symbol) obj/scale [
			obj/scale: scales/(obj/symbol)
		]
	]

	set 'set-scale function [
		"Set scales for given symbol"
		sym [any-word! string!] "Simple symbol (word!) or compound (string!)"
		spec [map!] "Pairs of comparable symbols and conversion values"
		/dim 
			d [vector!] "Vector of dimension powers"
	][
		if dim [put dimensions sym d]
		d: dimensions/:sym
		either scale: select scales sym [
			foreach [sym2 value] spec [
				adjust-unit sym sym2 value d
			]
		][
			put scales sym make map! copy spec ; is `copy` needed?
			;make-unit :sym d
			foreach [sym2 value] spec [
				adjust-unit/only sym sym2 value d
			]
		]
	]

	set 'set-scales func [
		"Set scales for given units"
		specs [block!] "Pairs of symbol and map of comparable units"
		/dim 
			d [vector!] "Vector of dimension powers"
		/only "Limit scales to given specs"
		/local sym spec
	][
		if only [scales: specs] 
		foreach [sym spec] specs [
			either dim [
				set-scale/dim sym spec d ; dim needed when first initialising given unit
			][
				set-scale sym spec ; when changing scales for unit already initialized
			]
		]
	]

	form-as: func ['sym obj /round rnd /exact][
		either exact [
			form-unit/exact to-unit :sym obj
		][
			form-unit/round to-unit :sym obj rnd
		]
	]

	form-unit: function [obj /round rnd /exact][
		val: obj/amount
		if rnd [val: system/words/round/to val rnd]
		either obj/dimension *=* dims/currency [
			either any [rnd exact] [
				rejoin [obj/symbol #"$" val]
			][
				val: system/words/round/to val .01
				parts: split form val #"."
				parts/2: pad/with parts/2 2 #"0"
				rejoin [obj/symbol #"$" parts/1 #"." parts/2]
			]
		][
			rejoin [val obj/symbol]
		]
	]

	basic: function ['sym value /dim d][
		spec: copy unit!
		spec/type: quote 'basic
		spec/symbol: to-lit-word sym
		spec/amount: value
		spec/parts: to block! sym
		spec/dimension: dimensions/:sym
		reactor spec
	]

	derive: function ['sym value /dim d][
		spec: copy unit!
		spec/type: quote 'derived
		spec/symbol: sym
		spec/amount: value
		spec/parts: make-parts sym
		spec/dimension: any [d make-dimension spec/parts]
		reactor spec
	]

	make-parts: function [sym][
		sym: split sym #"/"
		collect [
			foreach d sym [
				keep/only parse d [
					collect some [
						copy _ some alpha keep (to word! _) 
					| 	copy _ [opt #"-" digit] keep (to integer! _)
					|	#"*"
					]
				]
			]
		]
	]

	make-dimension: function [parts [block! string! word!]][
		if string? parts [parts: make-parts parts]
		if word? parts [parts: make-parts form parts]
		dim: copy base-dimension
		positive: first parts
		either block? positive [
			forall positive [
				dim: dim +' either integer? i: positive/2 [
					positive: next positive
					i *' copy dimensions/(positive/-1)
				][
					dimensions/(positive/1)
				]
			]
		][
			dim: dimensions/:positive
		]
		if negative: second parts [
			forall negative [
				dim: dim -' either integer? i: negative/2 [
					negative: next negative
					i *' copy dimensions/(negative/-1)
				][
					dimensions/(negative/1)
				]
			]
		]
		dim
	]

	get-dimension: func [sym [word! string!]][
		any [
			select dimensions sym
			dimensions/:sym: make-dimension sym
		]
	]

	flatten: function [bb] [collect [forall bb [keep bb/1]]]

	get-dims: function [dim][
		frst: clear []
		scnd: clear []
		repeat i length? dim [
			case [
				0 < p: dim/:i [
					append frst standard/:i 
					if p > 1 [append frst p]
				]
				0 > p [
					append scnd standard/:i
					if p < -1 [append scnd absolute p]
				]
			]
		]
		reduce [frst either empty? scnd [][scnd]]
	]
	
	count-dims: function [dim][
		i: 0
		forall dim [if dim/1 <> 0 [i: i + 1]]
	]
	
	compound?: func [b][
		any [
			1 <> sum dim: b/dimension
			1 < count-dims dim
		]
	]
	
	re-dimension: function [a b /repeated][
		case [
			equal? a/symbol b/symbol [b]
			all [b/scale b/scale/(sym: a/symbol)] [to-unit :sym b]
			all [word? b/symbol found: find keys-of b/scale string!][
				sym: found/1
				re-dimension/repeated a to-unit :sym b
			]
			all [word? a/symbol found: find keys-of a/scale string!][
				sym: found/1
				re: re-dimension/repeated to-unit :sym a b
				make re compose/only [symbol: (to-lit-word a/symbol) parts: (a/parts)]
			]
			;all [not repeated compound? b] [
			;	std: make b compose/only [
			;		type: 'derived
			;		parts: (p: get-dims b/dimension)
			;		symbol: (build-symbol p)
			;	]
			;	if not b/scale [put b/scale make map! copy []]
			;	put b/scale std/symbol 1
			;	re-dimension/repeated a std
			;]
			true [
				triples: collect [
					foreach e2 flatten b/parts [
						foreach e1 flatten a/parts [
							if all [
								not equal? e1 e2 
								dimensions/:e1 *=* dimensions/:e2
							][
								keep e1 keep e2 
								keep any [
									scales/:e2/:e1 
									resolve e2 e1
								]
							]
						]
					]
				]
				either empty? triples [
					b
				][
					parts: copy/deep b/parts
					either block? frst: first parts [
						val: b/amount
						foreach [e1 e2 v] triples [
							if found: find frst e2 [
								change found e1
								val: val *' either integer? i: found/2 [
									v **' i
								][	v]
							]
						]
						if scnd: second parts [
							val: 1.0 *' val
							foreach [e1 e2 v] triples [
								if found: find scnd e2 [
									change found e1
									val: val |' either integer? i: found/2 [
										v **' i
									][	v]
								]
							]
						]
						build-unit parts val
					][
						sym: first triples
						to-unit :sym b
					]
				]
			]
		]
	]

	part-rule: [
		set w word! keep (form w)
		any [part: 
			word! keep (#"*") keep (form part/1)
		|	integer! keep (form part/1)
		]
	]

	build-symbol: function [parts][
		sym: clear "" part: w: none
		bind part-rule :build-symbol ; to bind `part`-s and `w`-s
		parse parts [
			collect into sym [
				ahead block! into part-rule
				ahead block! s: [
					opt [
						if (not empty? s/1)
						keep (#"/") into part-rule
					]
				]
			]
		]
		sym
	]

	make-symbol: function [units dim][
		frst: clear []
		scnd: clear []
		repeat d length? dim [
			case [
				dim/:d *>* 0 [
					foreach u units [
						if dimensions/:u *=* dims/(2 *' d) [
							append frst u
							if (i: dim/:d) *>* 1 [append frst i]
						]
					]
				]
				dim/:d *<* 0 [
					foreach u units [
						if dimensions/:u *=* dims/(2 *' d) [
							append scnd u
							if (i: dim/:d) *<* -1 [append scnd absolute i]
						]
					]
				]
			]
		]
		either all [empty? scnd single? frst][
			frst/1
		][
			build-symbol reduce [frst scnd]
		]
	]

	build-unit: function [parts val][
		sym: build-symbol parts
		derive :sym val
	]

	amount?: func [obj][obj/amount]
	scale?:  func [obj][obj/scale]
	dim?:    func [obj][obj/dimension]
	symbol?: func [obj][obj/symbol]
	set 'units func [Units-DSL][do bind Units-DSL self]
]

()