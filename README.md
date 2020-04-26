# units
Calculations with dimensional quantities

Toy implementation for calculation of unitized quantities. Beware, incomplete and not yet thoroughly tested.

Usage: 
```
do %units.red
units [<Units-DSL>]
```

Units-DSL is ordinary RED with added pseudotype for dimensioned (i.e. unitized) quantities in form `<number><units>`, e.g. `1kg`, `-200m`, `10m2`, `20e8dyn`, `5.5kg*m/s2`, `10m/s`... and currencies either in form `USD$100`, `EUR$50.35` or as other quantities `30CAD`, `1.5PLZ` or in combination with other quantities `100USD/hr`, `50EUR/m2`. 

Now also angles `10deg`, `1.5rad`, also in combination with other quantities, e.g. `1turn/hr`; and vectors with parentized literal form: `(1,2)`, `(1,2,3)` or `(1,2,3,4)` (somewhat like expected `point!` type). All vectors are expanded to 4 dimensions, but not all dimensions are always used. Vectors are used to implement complex numbers and quaternions.

Scales for quantities are defined in `%units.red`, implementation is in `%units-code.red`.

Quantities are rewritten with `pre-load` into parenthized functions
```
>> "1kg"
== "(basic kg 1)"
>> "1kg3"
== "(derive {kg3} 1)"
>> "100USD/m2"
== "(derive {USD/m2} 100)"
>> "(1,2,3,4)"
== "(vector compose [1 2 3 4])"
```

`compose` seen in last example enables composition of vectors and also of other quantities:

```
>> "(1,0,(pi / 2),1)"
== "(vector compose [1 0 (pi / 2) 1])"
>> "a: 123.456 (a / 3)kg/m2"
== "a: 123.456 (derive {kg/m2} (a / 3))"
```

Inside `units [...]`, these functions create objects with following structure:
```
probe units [1kg]
make object! [
    type: 'mass
    symbol: 'kg
    amount: 1
    scale: #(
        g: 1000
        ton: 0.001
        lb: 2.2046226218487757
    )
    parts: [kg]
    dimension: make vector! [0 1 0 0 0 0 0 0 0 0]
    vector: none
    as: func [sym /only][either only [
        unit-value/only sym self
    ] [
        unit-value sym self
    ]]
]
probe units [normalize (0,1,1,0)]
make object! [
    type: 'vector
    symbol: none
    amount: 1.0
    scale: none
    parts: none
    dimension: make vector! [1 0 0 0 0 0 0 0 0 0]
    vector: make vector! [0.0 0.7071067811865475 0.7071067811865475 0.0]
    as: none
]
```

Fields can be accessed with corresponding functions:
```
utype? <val>
symbol? <val>
amount? <val>
dim? <val>
parts? <val>
scale? <val>
vec? <val>
```

E.g.:
```
>> units [utype? (0,0,0,1) ** 0]
== vector
>> units [utype? 1kg*m/s2]
== force
>> units [utype? 100km/hr]
== velocity

>> units [scale? USD$1]
== #(
    CAD: 1.4
    EUR: 0.91
)
>> units [parts? 1kg*m/s2]
== [[kg m] [s 2]]
>> units [dim? 1N]
== make vector! [0 1 1 -2 0 0 0 0 0]
>> units [vec? 45deg]
== make vector! [0.0 0.71 0.71 0.0]
```

Quantities can be compared, added, subtracted, multiplied, divided and rised to powers. Comparisons return logic values arithmetic operations return new objects. In following `units []` are implied:
```
USD$1 < EUR$1
;== true

1km = 1000m
;== true

100m / 2s
;== make object! [
;  type: 'derived
;  symbol: "m/s"
;  amount: 50.0
;   ...

500km / 150mi/hr
;== make object! [
;  type: 'basic
;  symbol: 'hr
;  amount: 5.36448
;  scale: #(
;    mn: 60
;    ...

mass: 20kg    acceleration: 9.8m/s2    force: mass * acceleration
amount? force
;== 196.0

symbol? force
;== "kg*m/s2"

1m ** 3
;== make object! [
;    type: 'derived
;    symbol: "m3"
;    amount: 1
;    scale: none
;    parts: [[m 3]]
;   ...
```

Quantities can be converted to different units with `as-unit`, `to-unit`, `re-dimension` and `form-as`:
```
as-unit EUR PLZ$25                     ; recalculates second argument in terms of unit given as first argument
;== 5.482456140350878

form-as EUR PLZ$25                     ; forms value of second argument in terms of unit given as first argument
;== "EUR$5.48"

form-unit re-dimension 1g*mm/s2 1dyn   ; redimensions second argument in units of first argument (and `form-unit` forms it with units)
;== "10.0g*mm/s2"

to-unit dyn 1N
;== make object! [
;    type: 'basic
;    symbol: 'dyn
;    amount: 100000
;    ...
``` 

Dimensioned quanities can be vectorized:
```
amount? (100m * 30deg) + (150m * 135deg)
;== 157.2750096071349
```

Vectorized quantities can be turned, elevated and rotated:
```
p: 10m * 45deg turn p 15deg elevate p 30deg probe angle? p probe elevation? p
60.0
30.0
p: rotate 10m * 0deg (-120,1,1,1) probe angle? p elevation? p
-45.0
;== 90.0
p: rotate 10m * 0deg (120,1,1,1) probe angle? p elevation? p
90.0
;== 0.0
```
Second argument to `rotate` is either vector! type or vector quantity, where first element is rotation angle and rest determines rotation axis.

Finally, basic complex and quaternion arithmetic works:
```
vec? (1,0) * (0,1)
;== make vector! [0.0 1.0 0.0 0.0]
vec? (1,0) * ((0,1) ** 2)
;== make vector! [-1.0 0.0 0.0 0.0]
vec? (1,0) * ((0,1) ** 3)
;== make vector! [0.0 -1.0 0.0 0.0]
vec? (1,0) * ((0,1) ** 4)
;== make vector! [1.0 0.0 0.0 0.0]

vec? (1,0,0,0) * (0,0,0,1)
;== make vector! [0.0 0.0 0.0 1.0]
vec? (0,1,0,0) * (0,0,0,1)
;== make vector! [0.0 0.0 -1.0 0.0]
vec? (0,1,0,0) * (0,0,1,0)
;== make vector! [0.0 0.0 0.0 1.0]
vec? (0,1,0,0) * (0,1,0,0)
;== make vector! [-1.0 0.0 0.0 0.0]
```
>> units [vec? (0,0,0,1) ** 2]
== make vector! [-1.0 0.0 0.0 0.0]
>> units [vec? (0,0,0,1) ** 3]
== make vector! [0.0 0.0 0.0 -1.0]
>> units [vec? (0,0,0,1) ** 4]
== make vector! [1.0 0.0 0.0 0.0]
```
