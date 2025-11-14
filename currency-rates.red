Red [
	author: @rebolek
]

context [

api-key: make map! either exists? %api-key.red [load %api-key.red][copy []]

base-url: #[
	fixer.io:				http://data.fixer.io/api/
	openexchangerates.org:	https://openexchangerates.org/api/
	exchangeratesapi.io:	https://api.exchangeratesapi.io/
]

cache: #[
	fixer.io:				%rates-fixer.red
	openexchangerates.org:	%rates-opexr.red
	exchangeratesapi.io:	%rates-exraa.red
]

latest: #[
	fixer.io:				[%latest?access_key= api-key/:server]
	openexchangerates.org:	[%latest.json?app_id= api-key/:server]
	exchangeratesapi.io:	[%latest]
]

rate-data: none

convert-rates: func [
	currency	[any-word!]
	rates		[map!]
	/local out rate cur val
][
	out: make map! []
	rate: rates/:currency
	foreach [cur val] rates [
		out/:cur: rate / rates/:cur
	]
	out
]

set 'make-rates-table func [
	rates	[map!]
;	/local out cur val
][
	out: copy []
	foreach [cur val] rates [
		repend out [
			to set-word! cur convert-rates cur rates
		]
	]
	out
]

set 'get-rates func [
	/from
		server	[word!]
	/force
][
	server: any [server 'exchangeratesapi.io]
; -- caching
	all [
		exists? cache/:server
		not force
		probe cache/:server
		return load cache/:server
	]
; -- load current rates
	link: append copy base-url/:server latest/:server
	probe 2
	data: load-json read link
	data/base: to word! data/base
	save cache/:server data
	data
]

; -- end of context
]
