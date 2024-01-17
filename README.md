# Permutations


## Introduction

This package defines a `Permutation`  type for Julia. We only
consider permutations of sets of the form `{1,2,3,...,n}` where `n` is
a positive integer.

A `Permutation` object is created from a one-dimensional array of
integers containing each of the values `1` through `n` exactly once.
```
julia> a = [4,1,3,2,6,5];
julia> p = Permutation(a)
(1,4,2)(3)(5,6)
```
Observe the `Permutation` is printed in disjoint cycle format.

The number of elements in a `Permutation` is determined using the
`length` function:
```
julia> length(p)
6
```

A `Permutation` can be converted to an array (equal to the array used
to construct the `Permutation` in the first place) or can be presented
as a two-row matrix as follows:
```
julia> p.data
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
using square bracket or parenthesis notation:
```
julia> p[2]
1
julia> p(2)
1
```
Of course, bad things happen if an inappropriate element is given:
```
julia> p[7]
ERROR: BoundsError()
 in getindex at ....
```



To get the cycle structure of a `Permutation` (not as a character string,
but as an array of arrays), use `cycles`:
```
julia> cycles(p)
3-element Array{Array{Int64,1},1}:
 [1,4,2]
 [3]
 [5,6]
```

Given a list of disjoint cycles of `1:n`, we can recover the `Permutation`:
```
julia> p = RandomPermutation(12)
(1,6,3,4,11,12,7,2,10,8,9,5)

julia> p = RandomPermutation(12)
(1,12,3,9,4,10,2,7)(5,11,8)(6)

julia> c = cycles(p)
3-element Vector{Vector{Int64}}:
 [1, 12, 3, 9, 4, 10, 2, 7]
 [5, 11, 8]
 [6]

julia> Permutation(c)
(1,12,3,9,4,10,2,7)(5,11,8)(6)
```

## Operations

### Composition 

Composition is denoted by `*`:
```
julia> q = Permutation([1,6,2,3,4,5])
(1)(2,6,5,4,3)
julia> p*q
(1,4,3)(2,5)(6)
julia> q*p
(1,3,2)(4,6)(5)
```
Repeated composition is calculated using `^`, like this: `p^n`.
The exponent may be negative.

### Inverse

The inverse of a `Permutation` is computed using `inv` or as `p'`:
```
julia> q = inv(p)
(1,2,4)(3)(5,6)
julia> p*q
(1)(2)(3)(4)(5)(6)
```

### Square Root


The `sqrt` function returns a compositional square root of the permutation.
That is, if `q=sqrt(p)` then `q*q==p`. Note that not all permutations have
square roots and square roots are not unique.
```
julia> p
(1,12,7,4)(2,8,3)(5,15,11,14)(6,10,13)(9)

julia> q = sqrt(p)
(1,5,12,15,7,11,4,14)(2,3,8)(6,13,10)(9)

julia> q*q == p
true
```

### Matrix Form


The function `Matrix` converts a permutation `p` to a square matrix
whose `i,j`-entry is `1` when `i == p[j]` and `0` otherwise.
```
julia> p = RandomPermutation(6)
(1,5,2,6)(3)(4)

julia> Matrix(p)
6×6 Array{Int64,2}:
 0  0  0  0  0  1
 0  0  0  0  1  0
 0  0  1  0  0  0
 0  0  0  1  0  0
 1  0  0  0  0  0
 0  1  0  0  0  0
```

Note that a permutation matrix `M` can be converted back to a `Permutation`
by calling `Permutation(M)`:
```
julia> p = RandomPermutation(8)
(1,4,5,2,6,8,7)(3)

julia> M = Matrix(p);

julia> q = Permutation(M)
(1,4,5,2,6,8,7)(3)
```

### Sign


The sign of a `Permutation` is `+1` for an even permutation and `-1`
for an odd permutation.
```
julia> p = Permutation([2,3,4,1])
(1,2,3,4)

julia> sign(p)
-1

julia> sign(p*p)
1
```

### Reverse

If one thinks of a permutation as a sequence, then applying `reverse`
to that permutation returns a new permutation based on the reversal of
that sequence. Here's an example:
```
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

### Extension

Permutations of different lengths cannot be composed:
```
julia> using Permutations

julia> p = RandomPermutation(8)
(1,4,2)(3,5)(6,8,7)

julia> q = RandomPermutation(10)
(1,2,9,4)(3,8,7,10)(5,6)

julia> p*q
ERROR: Cannot compose Permutations of different lengths
```

However, the `extend` function can be used to create a new `Permutation` 
that has greater length:
```
julia> p
(1,4,2)(3,5)(6,8,7)

julia> extend(p,10)
(1,4,2)(3,5)(6,8,7)(9)(10)
```

The extended `Permutation` is now able to be composed with the longer one:
```
julia> extend(p,10) * q
(1)(2,9)(3,7,10,5,8,6)(4)
```







## Additional Constructors

For convenience, identity and random permutations can be constructed
like this:
```
julia> Permutation(10)
(1)(2)(3)(4)(5)(6)(7)(8)(9)(10)

julia> RandomPermutation(10)
(1,7,6,10,3,2,8,4)(5,9)
```

In addition, we can use `Permutation(n,k)` to create the
`k`'th permutation of the set `{1,2,...,n}`. Of course,
this requires `k` to be between `1` and `n!`.
```
julia> Permutation(6,701)
(1,6,3)(2,5)(4)
```

The function `CyclePermutation` creates a permutation containing a 
single cycle of the form `(1,2,...,n)`.
```
julia> CyclePermutation(5)
(1,2,3,4,5)
```


The function `Transposition` is used to create a permutation containing
a single two-cycle. Use `Transposition(n,a,b)` to create a permutation of 
`1:n` that swaps `a` and `b`.
```
julia> p = Transposition(10,3,5)
(1)(2)(3,5)(4)(6)(7)(8)(9)(10)
```
This function requires `1 ≤ a ≠ b ≤ n`.


## Properties

### Fixed point 

A *fixed point* of a permutation `p` is a value `k` such that
`p[k]==k`. The function `fixed_points` returns a list of the fixed
points of a given permutation.
```
julia> p = RandomPermutation(20)
(1,15,10,9,11,13,12,8,5,7,18,6,2)(3)(4,16,17,19)(14)(20)

julia> fixed_points(p)
3-element Array{Int64,1}:
  3
 14
 20
```
### Longest increasing and decreasing subsequence

The function `longest_increasing` finds a subsequence of a permutation
whose elements are in increasing order. Likewise, `longest_decreasing`
finds a longest decreasing subsequence.
For example:
```
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

### Test for identity permutation

For a `Permutation`, `p`, the function `isone(p)` returns `true` exactly when 
`p` is an identity `Permutation`.

## Iteration

The function `PermGen` creates a `Permutation` iterator.

With an integer argument, `PermGen(n)` creates an iterator for all permutations of length `n`.
```
julia> for p in PermGen(3)
           println(p)
       end
(1)(2)(3)
(1)(2,3)
(1,2)(3)
(1,2,3)
(1,3,2)
(1,3)(2)
```

Alternatively, `PermGen` may be called with a dictionary of lists or list of lists argument, `d`. 
The permutations generated will have the property that the value of the permutation at argument `k` must be one of the values stored in `d[k]`. 
For example, to find all derangements of `{1,2,3,4}` we do this:
```
julia> d = [ [2,3,4], [1,3,4], [1,2,4], [1,2,3] ]
4-element Vector{Vector{Int64}}:
 [2, 3, 4]
 [1, 3, 4]
 [1, 2, 4]
 [1, 2, 3]
```
Thus `d[1]` gives all allowable values for the first position in the permutation, and so forth. We could equally well have done this:
```
julia> d = Dict{Int, Vector{Int}}();

julia> for k=1:4
           d[k] = setdiff(1:4,k)
       end

julia> d
Dict{Int64, Vector{Int64}} with 4 entries:
  4 => [1, 2, 3]
  2 => [1, 3, 4]
  3 => [1, 2, 4]
  1 => [2, 3, 4]
```

In either case, here we create the nine derangements of `{1,2,3,4}`:
```
julia> [p for p in PermGen(d)]
9-element Vector{Permutation}:
 (1,4)(2,3)
 (1,3,2,4)
 (1,2,3,4)
 (1,4,2,3)
 (1,3)(2,4)
 (1,3,4,2)
 (1,2,4,3)
 (1,4,3,2)
 (1,2)(3,4)
```

The `PermGen` iterator generates permutations one at a time. So this calculation does not use much memory:
```
julia> sum(length(fixed_points(p)) for p in PermGen(10))
3628800
```
> Aside: Notice that the answer is `10!`. It is a fun exerice to show that among all the `n!` permutations of `{1,2,...,n}`, the number of fixed points is `n!`.

We provide `DerangeGen(n)` which generates all derangements of `{1,2,...,n}`, i.e., all permutations without fixed points.
```
julia> for p in DerangeGen(4)
           println(p)
       end
(1,2)(3,4)
(1,2,3,4)
(1,2,4,3)
(1,3,4,2)
(1,3)(2,4)
(1,3,2,4)
(1,4,3,2)
(1,4,2,3)
(1,4)(2,3)
```

Thanks to [Jonah Scheinerman](https://github.com/jscheiny) for the implementation of `PermGen` for restricted permutations. 


## Conversion to a `Dict`

For a permutation `p`, calling `dict(p)` returns a dictionary that behaves
just like `p`.
```
julia> p = RandomPermutation(12)
(1,11,6)(2,8,7)(3)(4,5,9,12,10)

julia> d = dict(p)
Dict{Int64,Int64} with 12 entries:
  2  => 8
  11 => 6
  7  => 2
  9  => 12
  10 => 4
  8  => 7
  6  => 1
  4  => 5
  3  => 3
  5  => 9
  12 => 10
  1  => 11
```


## Coxeter Decomposition

Every permutation can be expressed as a product of transpositions. In
a *Coxeter decomposition* the permutation is the product of transpositions
of the form `(j,j+1)`.
Given a permutation `p`, we get this form
with `CoxeterDecomposition(p)`:
```
julia> p = Permutation([2,4,3,5,1,6,8,7])
(1,2,4,5)(3)(6)(7,8)

julia> pp = CoxeterDecomposition(p)
Permutation of 1:8: (1,2)(2,3)(3,4)(2,3)(4,5)(7,8)
```
The original permutation can be recovered like this:
```
julia> Permutation(pp)
(1,2,4,5)(3)(6)(7,8)
```

