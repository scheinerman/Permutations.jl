Permutations
============

This is documentation for a `Permutation` data type for Julia. We only
consider permutations of sets of the form `{1,2,3,...,n}` where `n` is
a positive integer.

A `Permutation` object is created from a one-dimensional array of
integers containing each of the values `1` through `n` exactly once.
```julia
julia> a = [4,1,3,2,6,5];
julia> p = Permutation(a)
(1,4,2)(3)(5,6)
```
Observe that the `Permutation` is printed in disjoint cycle format.

The number of elements in a `Permutation` is determined using the
`length` function:
```julia
julia> length(p)
6
```

A `Permutation` can be converted to an array (equal to the array used
to construct the `Permutation` in the first place) or can be presented
as a two-row matrix as follows:
```julia
julia> array(p)
6-element Array{Int64,1}:
 4
 1
 3
 2
 6
 5
julia> two_row(p)
2x6 Array{Int64,2}:
 1  2  3  4  5  6
 4  1  3  2  6  5
```

The evaluation of a `Permutation` on a particular element is performed
using square bracket notation:
```julia
julia> p[2]
1
```
Of course, bad things happen if an inappropriate element is given:
```julia
julia> p[7]
ERROR: BoundsError()
 in getindex at ....
```

Operations
----------

Composition is denoted by `*`:
```julia
julia> q = Permutation([1,6,2,3,4,5])
(1)(2,6,5,4,3)
julia> p*q
(1,4,3)(2,5)(6)
julia> q*p
(1,3,2)(4,6)(5)
```
Repeated composition is calculated using `^`, like this: `p^n`.
The exponent may be negative.

The inverse of a `Permtuation` is computed using `inv`:
```julia
julia> q = inv(p)
(1,2,4)(3)(5,6)
julia> p*q
(1)(2)(3)(4)(5)(6)
```

To find the cycle structure of a `Permutation` (not as a character string,
but as an array of arrays), use `cycles`:
```julia
julia> cycles(p)
3-element Array{Array{Int64,1},1}:
 [1,4,2]
 [3]
 [5,6]
```

The function `matrix` converts a permutation `P` to a square matrix
whose `i,j`-entry is `1` when `j == P[i]` and `0` otherwise. By
default, this creates a matrix with full storage; to get a sparse
result use `matrix(p,true)`.
```julia
julia> p = RandomPermutation(6)
(1,2,6,4)(3,5)
julia> matrix(p)
6x6 Array{Int64,2}:
 0  1  0  0  0  0
 0  0  0  0  0  1
 0  0  0  0  1  0
 1  0  0  0  0  0
 0  0  1  0  0  0
 0  0  0  1  0  0
```

The parity of a `Permutation` is computed using `parity` which returns
`0` for an even permutation and `1` for an odd permutation:
```julia
julia> parity(p)
1
julia> parity(p*p)
0
```

If one thinks of a permutation as a sequence, then applying `reverse`
to that permutation returns a new permutation based on the reversal of
that sequence. Here's an example:
```julia
julia> p = RandomPermutation(8)
(1,5,8,4,6)(2,3)(7)

julia> two_row(p)
2x8 Array{Int64,2}:
 1  2  3  4  5  6  7  8
 5  3  2  6  8  1  7  4

julia> two_row(reverse(p))
2x8 Array{Int64,2}:
 1  2  3  4  5  6  7  8
 4  7  1  8  6  2  3  5
```


Additional constructors
-----------------------
For convenience, identity and random permutations may be constructed
like this:
```julia
julia> Permutation(10)
(1)(2)(3)(4)(5)(6)(7)(8)(9)(10)
julia> RandomPermutation(10)
(1,7,6,10,3,2,8,4)(5,9)
```

In addition, we may use `Permutation(n,k)` to create the
`k`'th permutation of the set `{1,2,...,n}`. Of course,
this requires `k` to be between `1` and `n!`.
```julia
julia> Permutation(6,701)
(1,6,3)(2,5)(4)
```


Properties
----------

A *fixed point* of a permutation `p` is a value `k` such that
`p[k]==k`. The function `fixed_points` returns a list of the fixed
points of a given permutation.
```julia
julia> p = RandomPermutation(20)
(1,15,10,9,11,13,12,8,5,7,18,6,2)(3)(4,16,17,19)(14)(20)

julia> fixed_points(p)
3-element Array{Int64,1}:
  3
 14
 20
```

The function `longest_increasing` finds a subsequence of a permutation
whose elements are in increasing order. Likewise, `longest_decreasing`
finds a longest decreasing subsequence.
For example:
```julia
julia> p = RandomPermutation(10)
(1,3,10)(2)(4)(5,6)(7)(8)(9)

julia> two_row(p)
2x10 Array{Int64,2}:
 1  2   3  4  5  6  7  8  9  10
 3  2  10  4  6  5  7  8  9   1

julia> longest_increasing(p)
6-element Array{Int64,1}:
 3
 4
 6
 7
 8
 9

julia> longest_decreasing(p)
4-element Array{Int64,1}:
 10
  6
  5
  1
```

Comparison
----------

We define the functions `isequal` and `isless` and so permutations can be compared using the usual operators: `<`, `<=`, `==`, and so forth. In addition, we implement the `hash` function so permutations can serve as keys in dictionaries and held as elements of `Set` containers. 