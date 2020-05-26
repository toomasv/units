Red [
	Description: "Toy system of dimensional quantities"
	Date: 18-Apr-2020
	Last: 26-May-2020
	Author: "Toomas Vooglaid"
]
;Seems to work with fast-lexer

digit: charset "0123456789"
sci: [#"e" opt #"-" some digit]
num: [opt "-" some [digit opt "'"] opt [dot some [digit opt "'"]] opt sci]
upper: charset [#"A" - #"Z"]
lower: charset [#"a" - #"z"]
alpha: union upper lower
splitter: union charset "*/" digit
;#include %../utils/replace-each.red

system/lexer/pre-load: function [src len /local n u out][
	money: [copy u 3 upper #"$" copy n num (c: none f: "basic ")]
	dimensioned: [some alpha opt digit]
	compound: [dimensioned any [#"*" dimensioned]]
	paren: [#"(" some [paren | not #")" skip] #")"]
	pair: [num #"x" num]
	vector: [
		#"(" s: collect set out [
			keep [num | paren]
			1 3 [#"," keep [paren | num]] 
			;opt [ahead [4 [#"," num] #")"] 4 [#"," keep num]]
		]	e: #")" (e: change/part s rejoin ["vector compose " #"[" out "]"] e) :e
	]
	measure: [
		copy n [num | paren] copy u some alpha (c: none f: "basic ")
		opt [copy c [opt #"-" opt digit #"*" compound] (append u c)]
		opt [copy c [opt #"-" opt digit #"/" compound] (append u c)]
		opt [copy c [opt #"-" digit] (append u c)]
		opt [if (c) (f: "derive " u: rejoin ["{" u "}"])]
	]
	unit: [change [money | measure] (rejoin [#"(" f u #" " n #")"])]
	greek: [remove "greek " s: copy gr some alpha e: (change )]
	parse src [some [pair | unit | vector | skip]]
]

uctx: context append compose [
	;=== local ops ====
	*=*:  :system/words/=
	*lt*:  :system/words/<
	*gt*:  :system/words/>
	;*<=*: :system/words/<=
	;*>=*: :system/words/>=
	;<> Not used (i.e. long form only)
	+*:   :system/words/+
	-*:   :system/words/-
	*_:   :system/words/*
	|*:   get first find words-of system/words '/
	**_:  :system/words/**
	
	;=== ops to use in DSL ===
	=:  make op! func [a b][either comparable? a b [equal? a/as b/symbol b/amount][equal? a b]]
	(to set-word! '<) make op! func [a b][either comparable? a b [lesser? a/as b/symbol b/amount][lesser? a b]]
	>:  make op! func [a b][either comparable? a b [greater? a/as b/symbol b/amount][greater? a b]]
	<=: make op! func [a b][either comparable? a b [lesser-or-equal? a/as b/symbol b/amount][lesser-or-equal? a b]]
	>=: make op! func [a b][either comparable? a b [greater-or-equal? a/as b/symbol b/amount][greater-or-equal? a b]]
	<>: make op! func [a b][either comparable? a b [not equal? a/as b/symbol b/amount][not equal? a b]]
][	
	+: make op! function [a b][
		either comparable? a b [
			b': re-dimension a b
			either any [a/vector b/vector][
				vec: case [
					angles? a b [
						b'/amount: a/amount + b'/amount
						make-projection b'/amount b'/symbol
					]
					all [a/vector b'/vector] [a/vector + b'/vector]
					a/vector [a/vector + make vector! reduce [1.0 * b'/amount 0.0]]
					b/vector [b'/vector + make vector! reduce [1.0 * a/amount 0.0]]
				]
				b'/vector: vec
				if b'/type <> 'angle [b'/amount: magnitude? vec]
			][
				b'/amount: a/amount +* b'/amount
			]
			b'
		][a +* b]
	]
	-: make op! func [a b][
		either comparable? a b [
			b': re-dimension a b
			either any [a/vector b/vector][
				vec: case [
					angles? a b [
						b'/amount: a/amount - b'/amount
						make-projection b'/amount b'/symbol
					]
					all [a/vector b'/vector] [a/vector - b'/vector]
					a/vector [a/vector - make vector! reduce [1.0 * b'/amount 0.0]]
					b/vector [b'/vector - make vector! reduce [1.0 * a/amount 0.0]]
				] 
				b'/vector: vec
				if b'/type <> 'angle [b'/amount: magnitude? vec]
			][
				b'/amount: a/amount -* b'/amount
			]
			b'
		][a -* b]
	]

	*: make op! function [a b][
		case [
			any [all [entity? a number? b] all [number? a entity? b]][
				if number? b [c: b b: a a: c]
				b: copy/deep b
				foreach field words-of b [
					if quantity? :b/:field [
						b/:field: a * b/:field 
					]
				]
				b
			]
			all [entity? a entity? b][
				fields: intersect words-of a words-of b
				object collect [
					foreach field fields [
						case [
							quantity? a/:field [
								keep to-set-word field
								keep a/:field * b/:field
							]
							field = 'type [
								keep quote type:
								keep a/type
							]
						]
					]
				]
			]
			all [number? a quantity? b] [
				c: make b compose [amount: (b/amount *_ a)]
				if c/vector [
					switch/default c/type [
						angle [c/vector: make-projection c/amount c/symbol]
					][
						c/vector: c/vector * a
					]
				]
				c
			]
			all [number? b quantity? a] [
				c: make a compose [amount: (a/amount *_ b)]
				if c/vector [
					switch/default c/type [
						angle [c/vector: make-projection c/amount c/symbol]
					][
						c/vector: c/vector * b
					]
				]
				c
			]
			quantities? a b [
				case [
					angles? a b [
						b': re-dimension a b
						a/vector * cosine b'/amount
						a/vector/4: sine b'/amount
						a
					]
					all [a/vector b/vector][
						v: qmultiply a/vector b/vector
						c: make a [vector: v]
					]
					b/vector [a/vector: a/amount * copy b/vector a]
					a/vector [b/vector: b/amount * copy a/vector b]
					true [relate a b '*]
				]
			]
			true [a *_ b]
		]
	]
	/: make op! func [a b][
		case [
			all [number? a quantity? b] [
				amount: b/amount *_ 1.0 |* a
				make b compose [amount: (amount)]
			]
			all [number? b quantity? a] [
				amount: a/amount *_ 1.0 |* b
				make a compose [amount: (amount)]
			]
			quantities? a b [relate a b '/]
			true [a |* b]
		]
	]
	**: make op! function [a b][
		case [
			all [is-vector? a integer? b][
				v: a/vector
				loop b - 1 [
					v: qmultiply v a/vector
				]
				make a [vector: v]
			]
			all [quantity? a number? b] [
				amount: a/amount **_ b
				dimension: b *_ copy a/dimension
				sym: make-symbol flatten a/parts dimension
				either word? sym [
					basic :sym amount
				][
					derive :sym amount
				]
			]
			true [a **_ b]
		]
	]
	relate: function [a b op][
		b': re-dimension a b
		vec: none
		switch op [
			* [
				dimension: a/dimension +* b/dimension
				case [
					all [a/vector b/vector][
						rise-error ["Vectors multiplication is not implemented!"]
					]
					a/vector [vec: a/vector * b/amount amount: b/amount]
					b/vector [vec: b/vector * a/amount amount: a/amount]
					true [amount: a/amount *_ b'/amount]
				]
			]
			/ [	
				amount: divide a/amount *_ 1.0 b'/amount
				dimension: a/dimension -* b/dimension
			]
		]
		sym: make-symbol unique append flatten a/parts flatten b'/parts dimension
		out: either word? sym [
			basic :sym amount
		][
			sym: copy sym
			derive :sym amount
		]
		if vec [out/vector: vec]
		out
	]
	
	;==================================
	standard: [rad kg m s A K mol cd USD bit]
	rise-error: func [msg][cause-error 'user 'message rejoin msg]

	quantity?: func [a][all [object? a a/dimension]]
	quantities?: func [a b][all [quantity? a quantity? b]]
	is-angle?: func [a][all [quantity? a a/type *=* 'angle]]
	angles?: func [a b][all [a/type *=* 'angle b/type *=* 'angle]]
	is-vector?: func [a][all [quantity? a a/type *=* 'vector]]
	vectors?: func [a b][all [is-vector? a is-vector? b]]
	entity?: func [a][all [object? a a/type = 'entity]]
	comparable?: func [a b][all [quantities? a b equal? a/dimension b/dimension]]
	comparable-symbols?: func [sym1 [word! string!] sym2 [word! string!]][
		equal? get-dimension sym1 get-dimension sym2
	]

	quantity!: [
		type: none
		symbol: none 
		amount: 1 
		scale: is [select scales symbol] 
		parts: none
		dimension: none
		vector: none
		as: func [sym /only][
			either only [
				unit-value/only sym self
			][
				unit-value sym self
			]
		]
	]

	basic: function ['sym value /dim d][
		spec: copy quantity!
		spec/symbol: to-lit-word sym
		spec/amount: value
		spec/parts: to block! sym
		spec/dimension: any [d d: dimensions/:sym]
		spec/type: to-lit-word first back find dims d
		if spec/dimension/1 > 0 [		;it is angle
			spec/vector: make-projection value sym
		]
		reactor spec
	]

	derive: function ['sym value /dim d][
		spec: copy quantity!
		spec/symbol: sym
		spec/amount: value
		spec/parts: make-parts sym
		spec/dimension: any [d d: make-dimension spec/parts]
		spec/type: either found: find dims d [
			to-lit-word first back found
		][quote 'derived]
		reactor spec
	]

	vector: function [vec [block!]][
		spec: copy quantity!
		spec/dimension: copy dims/angle
		spec/vector: vec: make-vector vec 
		spec/amount: magnitude? vec
		spec/type: quote 'vector
		spec/as: none
		object spec
	]

	entity: function [blk [block!]][
		object compose append blk [type: to-lit-word 'entity]
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
		val: case [
			paren? obj/scale/:sym [
				if obj/vector [amount: obj/amount]
				do replace/deep copy obj/scale/:sym '_ obj/amount
			]
			true [obj/amount *_ sc: obj/scale/:sym]
		]
		if obj/vector [
			if amount [sc: to-integer val / amount]
			obj/vector * sc
		]
		val
	]
	
	seen: clear []
	
	resolve2: function [sym1 sym2 /with value /num n][
		n: any [n 1]
		if n *gt* 20 [return false]
		value: any [value 1]
		either val: select scales/:sym1 sym2 [
			return val *_ value
		][
			case [
				string? sym1 [
					obj1: derive :sym1 1
					obj2: either string? sym2 [derive :sym2 1][basic :sym2 1]
					obj: re-dimension obj2 obj1
					return obj/amount *_ value
				]
				true [
					append seen sym1
					foreach [sym val] scales/:sym1 [
						if not find seen sym [
							vals: scales/:sym
							if v: select vals sym2 [
								return v *_ val *_ value
							][
								append seen sym
							]
						]
					]
					foreach [sym val] scales/:sym1 [
						vals: scales/:sym 
						foreach [s v] vals [
							if not find seen s [
								return resolve2/with/num s sym2 v *_ val *_ value n +* 1
							]
						]
					]
				]
			]
		]
		false
	]
	
	resolve: function [sym1 sym2 /only][
		msg: ["Cannot compare " sym1 " with " sym2 "!"]
		clear seen ; To avoid loops
		either comparable-symbols? sym1 sym2 [
			case [
				val: resolve2 sym1 sym2 [ ;First try this way..
					if not scales/:sym1 [put scales sym1 make map! copy []]
					put scales/:sym1 sym2 val 
					if not scales/:sym2 [put scales sym2 make map! copy []]
					put scales/:sym2 sym1 1.0 |* val 
				]
				val: resolve2 sym2 sym1 [ ;..and then the way around
					if not scales/:sym1 [put scales sym1 make map! copy []]
					put scales/:sym1 sym2 1.0 |* val
					if not scales/:sym2 [put scales sym2 make map! copy []]
					put scales/:sym2 sym1 val
				]
				only [false]
				true [rise-error msg]
			]
		][rise-error msg]
	]

	adjust-unit: function [sym1 sym2 val dim /only][
		unless only [put scales/:sym1 sym2 val]
		if not paren? val [
			either scale: select scales sym2 [
				put scale sym1 1.0 |* val
			][
				put scales sym2 make map! reduce [sym1 1.0 |* val]
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
	
	to-unit: function ['sym obj][
		case [
			all [obj/scale obj/scale/:sym] [to-unit2 sym obj]
			resolve obj/symbol sym [
				sync-scale obj
				to-unit2 sym obj
			]
			true [rise-error ["Can't compare " sym " to " obj/symbol "!"]]
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
	
	form-entity: func [ent [object!] /as 'sym][
		either entity? ent[
			object collect [
				foreach [w i] body-of ent [
					if quantity? i [
						keep w
						keep either as [form-as :sym i][form-unit i]
					]
				]
			]
		][
			rise-error "`form-entity` expects `entity` as argument"
		]
	]
	
	total-dim: func [ent dim [word! vector!] /local total][
		if word? dim [dim: dims/:dim]
		either entity? ent [
			foreach [w i] body-of ent [
				if all [quantity? i i/dimension = dim] [
					total: either total [total + i][i]
				]
			]
		][
			rise-error "`total` expects `entity` as argument"
		]
		total
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
				dim: dim +* either integer? i: positive/2 [
					positive: next positive
					i *_ copy dimensions/(positive/-1)
				][
					dimensions/(positive/1)
				]
			]
		][
			dim: dimensions/:positive
		]
		if negative: second parts [
			forall negative [
				dim: dim -* either integer? i: negative/2 [
					negative: next negative
					i *_ copy dimensions/(negative/-1)
				][
					dimensions/(negative/1)
				]
			]
		]
		dim
	]

	make-projection: function [ang sym][
		switch sym [
			rad  [x: cos 1.0 *_ ang y: sin 1.0 *_ ang]
			deg  [x: cosine ang y: sine ang]
			turn [x: cos a: 2 * pi * ang y: sin a]
		]
		;object compose [scale-x: (x) scale-y: (y)]
		make vector! reduce [0.0 x y 0.0]
	]

	make-vector: func [vec][
		forall vec [vec/1: 1.0 *_ vec/1] 
		append/dup vec 0.0 4 -* length? vec
		make vector! vec
	]

	get-dimension: func [sym [word! string!]][
		any [
			select dimensions sym
			dimensions/:sym: make-dimension sym
		]
	]

	flatten: function [bb] [collect [forall bb [keep bb/1]]]

	get-standard: function [dim][
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
		i
	]
	
	compound?: function [b][
		dim: case [
			word? b [dimensions/:b]
			quantity? b [b/dimension]
		]
		any [
			1 <> sum dim
			1 < count-dims dim
		]
	]
	
	split-up: func [sym][split form sym splitter]
	
	missing-parts?: func [a b][
		exclude split-up b/symbol split-up a/symbol
	]
	
	common-dims: function [a b][
		collect [
			repeat i length? base-dimension [
				if not any [
					zero? a/dimension/:i 
					zero? b/dimension/:i
				][
					keep dims/(i * 2 - 1)
				]
			]
		]
	]
	
	to-units: func [f][
		f: split-up f 
		forall f [
			either empty? f/1 [
				f: next f
			][
				f/1: to-word f/1
			]
		] 
		f
	]
	
	find-derivative: function [sym][
		parse body-of scales/:sym [
			some [string! quote 1 s: (return s/-2) thru end | skip]
		]
		none
	]
	
	find-dim-in-units: function [units dim][
		foreach u units [
			if compound? u [
				f: find-derivative u
				return find-dim-in-units to-units f dim
			]
			if dimensions/:u = dim [return u]
		]
		none
	]
	
	unit-of: function [
		"What unit does quantity use for this dimension?"
		dim [vector! word!] q [object!]
	][
		if word? dim [dim: dims/:dim]
		find-dim-in-units flatten q/parts dim
	]
	
	remake-derivative: function [q][
		sym: find-derivative q/symbol
		derive :sym q/amount
	]
	
	re-dimension: function [
		"Redimension b in units of a (if any)"
		a [object!] b [object!]
	][
		common: common-dims a b
		case [
			any [empty? common a/symbol = b/symbol] [copy/deep b]
			any [
				all [b/scale b/scale/(sym: a/symbol)]
				all [a/scale a/scale/(sym: b/symbol)]
			][to-unit :sym b]
			true [
				if all [word? a/symbol compound? a][
					a: remake-derivative a
				]
				if all [word? b/symbol compound? b][
					b: remake-derivative b
				]
				;foreach d common [
				;	probe reduce [a/symbol unit-of d a b/symbol unit-of d b]
				;	if (ua: unit-of d a) <> (ub: unit-of d b) [
				;		i: index? find dims d
				;		i: (to-integer i / 2) + 1
				;		either b/dimension/:i > 0 [
				;			
				;		][
				;			
				;		]
				;	]
				;]
				re-dimension2 a b
			]
		]
	]

	re-dimension2: function [a b][
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
				val0: val: b/amount
				foreach [e1 e2 v] triples [
					if found: find frst e2 [
						change found e1
						val: val *_ either integer? i: found/2 [
							v **_ i
						][	v]
					]
				]
				if scnd: second parts [
					val: 1.0 *_ val
					foreach [e1 e2 v] triples [
						if found: find scnd e2 [
							change found e1
							val: val |* either integer? i: found/2 [
								v **_ i
							][	v]
						]
					]
				]
				out: build-unit parts val
				if b/vector [out/vector: (copy b/vector) * val / val0]
				out
			][
				sym: first triples
				to-unit :sym b
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
				;d *=* 1 []
				dim/:d *gt* 0 [
					foreach u units [
						if dimensions/:u *=* dims/(2 *_ d) [
							append frst u
							if (i: dim/:d) *gt* 1 [append frst i]
						]
					]
				]
				dim/:d *lt* 0 [
					foreach u units [
						if dimensions/:u *=* dims/(2 *_ d) [
							append scnd u
							if (i: dim/:d) *lt* -1 [append scnd absolute i]
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

	sync-scale: func [obj][
		if not equal? scales/(obj/symbol) obj/scale [
			obj/scale: scales/(obj/symbol)
		]
	]
	
	round*: :system/words/round
	utype?:  func [obj][obj/type]
	symbol?: func [obj][obj/symbol]
	parts?:  func [obj][obj/parts]
	amount?: func [obj][obj/amount]
	scale?:  func [obj][obj/scale]
	dim?:    func [obj][obj/dimension]
	vec?:    function [obj /round to /precise][
		either precise [obj/vector][
			vec: copy obj/vector
			forall vec [
				vec/1: round*/to vec/1 any [to .01]
			] vec
		] 
	]
	angle?:  function [obj /rad /deg /turn /dim 'd /round to /precise][
		if obj/vector [
			ang: switch/default d [
				i [arctangent2 obj/vector/2 obj/vector/1]
				j [arctangent2 obj/vector/3 obj/vector/1]
				k [arctangent2 obj/vector/4 obj/vector/1]
				#[none][arctangent2 obj/vector/3 obj/vector/2]
			][
				rise-error ["Argument to `angle?/dim` (" d ") not reckognized!"]
			]
			case [
				any [rad all [not deg obj/parts find flatten obj/parts 'rad]][
					ang: scales/deg/rad * ang
				]
				any [turn all [not deg obj/parts find flatten obj/parts 'turn]][
					ang: scales/deg/turn * ang
				]
			]
			either precise [ang][
				round*/to ang any [to .01]
			]
		]
	]
	elevation?: function [obj /rad /deg /round to /precise][
		if obj/vector [
			either any [rad all [not deg obj/parts find flatten obj/parts 'rad]][
				ang: asin obj/vector/4 / magnitude? obj
			][	ang: arcsine obj/vector/4 / magnitude? obj]
			either precise [ang][
				round*/to ang any [to .01]
			]
		]
	]
	;re?:     function [obj][if v: obj/vector [v/1]]
	;im?:     function [obj][if v: obj/vector [next v]]

	
	magnitude?: func [a][
		vec: either vector? a [a][a/vector]
		sqrt (vec/1 ** 2) + (vec/2 ** 2) + (vec/3 ** 2) + (vec/4 ** 2)
	]
	qmultiply: function [q [integer! float! vector!] p [integer! float! vector!]][
		either all [vector? q vector? p][
			make vector! reduce [
				(q/1 * p/1) - (q/2 * p/2) - (q/3 * p/3) - (q/4 * p/4)
				(q/1 * p/2) + (q/2 * p/1) + (q/3 * p/4) - (q/4 * p/3)
				(q/1 * p/3) + (q/3 * p/1) + (q/4 * p/2) - (q/2 * p/4)
				(q/1 * p/4) + (q/4 * p/1) + (q/2 * p/3) - (q/3 * p/2)
			]
		][p * q]
	]
	negate: func [q][
		either quantity? q [
			q/amount: -1 * q/amount 
			if q/vector [q/vector * -1]
		][-1.0 * q]
	]
	conjugate: 	func [q [vector!]][
		head -1.0 * next q
	]
	norm: func [q [vector!]][
		sqrt first qmultiply q conjugate copy q
	]
	normalize: function [q][
		case [
			is-vector? q [
				n: norm q/vector
				q/vector: make vector! collect [
					foreach p q/vector [keep p / n]
				]
				q/amount: 1.0;magnitude? q/vector
				q
			]
			vector? q [
				n: norm q
				make vector! collect [forall q [keep q/1 / n]]
			]
			true [rise-error [{Argument to `normalize` should be either vector! or quantity of type `vector`!^/Type `} type?/word q {` was provided instead.}]]
		]
	]
	inverse: func [q][
		case [
			is-vector? q [
				q/vector: (conjugate q/vector) / ((norm q/vector) ** 2)
				q
			]
			vector? q [
				(conjugate q) / ((norm q) ** 2)
			]
			true [rise-error [{Argument to `inverse` should be either vector! or quantity of type `vector`!^/Type `} type?/word q {` was provided instead.}]]
		]
	]
	rotate*: function [axis q][ ; axis: [ang-degrees + normalized-vec]
		a: either is-vector? axis [axis/vector][axis]
		b: either quantity? q [q/vector][q]
		either all [vector? a vector? b][
			co: cosine .5 * a/1
			si: sine .5 * a/1
			q1: make vector! reduce [co si * a/2 si * a/3 si * a/4]
			q2: qmultiply q1 b
			q3: conjugate q1
			c:  qmultiply q2 q3
			either quantity? q [
				q/vector: c
				q
			][c]
		][]
	]
	rotate: function [
		"Rotate <quantity> by <rotator>"
		quantity "Quantity to be rotated"
		rotator "Quantity with vector composed of rotation angle (deg) and axis (will be normalized)"
	][
		if not all [quantity? quantity quantity/vector][rise-error ["<quantity> arg to `rotate` needs to be vectorized!"]]
		if not any [vector? rotator is-vector? rotator][rise-error ["<rotator> argument to `rotate` must be vector! or quantity of type 'vector!"]]
		axis: make-rotator rotator
		rotate* axis quantity
	]
	make-rotator: function [rotator][
		axis: either is-vector? rotator [rotator/vector][rotator]
		ang: first axis
		axis/1: 0.0
		axis: normalize axis
		axis/1: ang
		either is-vector? rotator [
			rotator/vector: axis
			rotator
		][axis]
	]
	turn: function [
		"Turn <quantity> on x-y plane by <angle>"
		quantity "Quantity to be turned"
		angle "Angle by which to turn (number! or angle quantity)"
		/only
	][
		if not all [quantity? quantity quantity/vector] [
			rise-error ["<quantiy> argument to `turn` must be vectorized quantity!"]
		]
		either any [number? angle is-angle? angle] [
			ang: either number? angle [1.0 * angle][as-unit deg angle]
			v: make-projection ang +* angle?/precise quantity 'deg
			v * cosine elevation? quantity
			either any [is-angle? quantity only] [
				quantity/vector/2: v/2
				quantity/vector/3: v/3
			][
				quantity/vector/2: v/2 * quantity/amount
				quantity/vector/3: v/3 * quantity/amount
			]
			quantity
		][
			rise-error ["<angle> argument to `turn` must be either number (deg) or angle quantity!"]
		]
	]
	elevate: function [
		"Turn <quantity> around axis on x-y plane perpendicular to quantitie's <angle>"
		quantity "Quantity to be elevated"
		angle "Angle by which to elevate (number! or angle quantity)"
	][
		if not all [quantity? quantity quantity/vector] [
			rise-error ["<quantiy> argument to `elevate` must be vectorized quantity!"]
		]
		either any [number? angle is-angle? angle] [
			ang: either number? angle [1.0 * angle][as-unit deg angle]
			v: qmultiply quantity/vector make vector! [0.0 0.0 0.0 1.0]
			v/1: ang v/4: 0.0
			rotate quantity v
		][
			rise-error ["<angle> argument to `elevate` must be either number (deg) or angle quantity!"]
		]
	]
	
	;GA
	gp: function [p q][
		a: either vector? p [p][p/vector]
		b: either vector? q [q][q/vector]
		make vector! reduce [
			(a/1 * b/1) + (a/2 * b/2) + (a/3 * b/3) - (a/4 * b/4)
			(a/1 * b/2) + (a/2 * b/1) + (a/4 * b/3) - (a/3 * b/4)
			(a/1 * b/3) + (a/3 * b/1) + (a/2 * b/4) - (a/4 * b/2)
			(a/1 * b/4) + (a/4 * b/1) + (a/2 * b/3) - (a/3 * b/2)
		]
	]
	
	
	;Public funcs
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
			foreach [sym2 value] spec [
				adjust-unit/only sym sym2 value d
			]
		]
	]

	set 'set-scales func [
		"Set scales for given units"
		specs [block!] "Pairs of symbol and map of comparable units"
		/dim 
			d [vector!] "Vector of dimension powers [vec M L T I Θ N J S B °]"
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

	set 'units func [Units-DSL][do bind Units-DSL self]
]
()
