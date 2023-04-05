module Permutations
using LinearAlgebra, Combinatorics

import Base:
    length,
    show,
    invperm,
    inv,
    reverse,
    ==,
    getindex,
    *,
    ^,
    sign,
    hash,
    getindex,
    Matrix,
    Array,
    AbstractMatrix,
    AbstractArray,
    Array,
    adjoint


import Combinatorics: nthperm
import Random: randperm

export Permutation, RandomPermutation
export length, getindex, array, two_row
export invpermute, cycles, cycle_string
export order, matrix, fixed_points
export longest_increasing, longest_decreasing, reverse, sign
export hash, dict, Transposition
export apply_transposition, apply_transposition!
export CoxeterDecomposition  # no reason to expose CoxeterGenerator
export CompiledPermutation

# Defines the Permutation class. Permutations are bijections of 1:n.


abstract type AbstractPermutation end

"""
    Permutation

* `Permutation(list)` creates a new `Permutation`. Here `list` must be a rearrangement of `1:n`.
* `Permutation(n)` creates the identity `Permutation` of `1:n`.
* `Permutation(n,k)` creates the `k`'th `Permutation` of `1:n`.
* `Permutation(P::Matrix{Int})` creates a `Permutation` from a permutation matrix.
* `Permutation(cycles::Vector{Vector{Int}})` creates a `Permutation` from a list of disjoint cycles.
"""
struct Permutation <: AbstractPermutation
    data::Vector{Int}
    function Permutation(dat::Vector{Int}; validate=true)
        n = length(dat)
        if validate && sort(dat) != collect(1:n)
            error("Improper array: must be a permutation of 1:n")
        end
        new(dat)
    end
end

Permutation(v::AbstractVector) = Permutation(Vector{Int}(v))

# create the k'th permutation of 1:n
function Permutation(n, k)
    return Permutation(nthperm(collect(1:n), k))
end

# create the identity permutation
Permutation(n::Int) = Permutation(collect(1:n))



"""
    Transposition(n,a,b)

Create a permutation of `1:n` swapping `a` for `b`.
"""
function Transposition(n::Int, a::Int, b::Int)::Permutation
    @assert 0 < a ≤ n && 0 < b ≤ n && a ≠ b "Require n,a,b to be positive, with 0 ≤ a ≠ b ≤ n, got n=$n, a=$a, and b=$b"
    list = collect(1:n)
    @inbounds list[a] = b
    @inbounds list[b] = a
    return Permutation(list)
end

"""
    RandomPermutation(n::Int)

Create a random permutation of `1:n`, each with probability `1/factorial(n)`.
"""
RandomPermutation(n::Int) = Permutation(randperm(n))

# Returns the number of elements in the Permtuation

"""
    length(p::Permutation)

Return the number of elements in `p`.
"""
function length(p::Permutation)::Int
    return length(p.data)
end

# Check for equality of permutations
==(p::Permutation, q::Permutation) = p.data == q.data

# Apply the Permutation to an element: p[k] or p(k)
getindex(p::Permutation, k::Int) = p.data[k]
(p::Permutation)(k::Int) = p.data[k]

# Iteration utility
Base.iterate(p::Permutation, state=1) = state > length(p) ? nothing : (p[state], state+1)


# Create a two-row representation of this permutation
"""
    two_row(p::Permutation)

Createa a two-row representation of the `Permutation` `p`
in which the first row is `1:n` and the second row are the
values `p(1), p(2), ..., p(n)`.
"""
function two_row(p::Permutation)::Matrix{Int}
    n = length(p)
    return [(1:n)'; p.data']
end

# Composition of two permutations
*(p::Permutation) = p
function *(p::Permutation, q::Permutation)
    n = length(p)
    if n != length(q)
        error("Cannot compose Permutations of different lengths")
    end
    @inbounds dat = [p.data[q.data[k]] for k = 1:n]
    return Permutation(dat)
end

# Inverse of a permutation
"""
    inv(p::Permutation)

Give the inverse of `Permutation` `p`. This may
also be computed with `p'`.
"""
inv(p::AbstractPermutation) = invperm(p)
adjoint(p::AbstractPermutation) = invperm(p)

function invperm(p::Permutation)
    n = length(p)
    data = zeros(Int, n)
    for k = 1:n
        @inbounds j = p.data[k]
        @inbounds data[j] = k
    end
    return Permutation(data)
end

"""
    invpermute(v, p::AbstractVector)
    invpermute(v, p::AbstractPermutation)

Equivalent to `v[invperm(p)]` but often more efficient and does not check if `p` is a 
permutation.
"""
Base.@propagate_inbounds function invpermute(v, p::AbstractVector)
    out = similar(v)
    out[p] = v
    out
end
function invpermute(v, p::Permutation)
    axes(v) == axes(p.data) || throw(DimensionMismatch("Data and permutation must have the same axes."))
    @inbounds invpermute(v, p.data)
end
invpermute(v, p::AbstractPermutation) = invpermute(v, Permutation(p))


# Find the cycles in a permutation
"""
    cycles(p::Permutation)

Return a list of the cycles in `Permutation` `p`.
"""
function cycles(p::Permutation)
    n = length(p)
    result = Array{Int,1}[]
    todo = trues(n)
    k = 1
    while k !== nothing
        todo[k] = false
        cycle = [k]
        j = p[k]
        while j != k
            push!(cycle, j)
            todo[j] = false
            j = p[j]
        end
        push!(result, cycle)
        k = findnext(todo, k)
    end
    return result
end

"""
    cycle_string(p::Permutation)

Create a nice, prinatble string representation
from the cycle structure of the permutation `p`.
"""
function cycle_string(p::AbstractPermutation)::String
    if length(p) == 0
        return "()"
    end
    str = ""
    cc = cycles(p)
    for c in cc
        str *= "(" * join(c, ',') * ")"
    end
    return str
end

"""
    sign(p::Permutation)

Return `+1` if`p` is an even `Permtuation` and `-1` if p is odd.
"""
function sign(p::Permutation)::Int
    n = length(p)
    result = 0
    todo = trues(n)
    while any(todo)
        k = findfirst(todo)
        todo[k] = false
        result += 1 # increment element count
        j = p[k]
        while j != k
            result += 1 # increment element count
            todo[j] = false
            j = p[j]
        end
        result += 1 # increment cycle count
    end
    return isodd(result) ? -1 : 1
end



function Permutation(cc::Vector{Vector{Int}})::Permutation
    # check the list of cycles has exactly one each from 1 to n
    elts = sort(union(cc...))
    n = length(elts)
    plist = collect(1:n)
    @assert elts == plist "Invalid list of cycles"

    for c in cc
        nc = length(c)
        for i = 1:nc
            a = c[i]
            b = c[mod1(i + 1, nc)]
            plist[a] = b
        end
    end
    return Permutation(plist)
end


# When we print a permutation, it appears in disjoint cycle format.
function show(io::IO, p::Permutation)
    print(io, cycle_string(p))
end
function show(io::IO, p::AbstractPermutation)
    print(io, length(p), "-element ", typeof(p), ": ", cycle_string(p))
end

# Find the smallest positive n such that p^n is the identity
"""
    order(p::Permutation)

Return the smallest positive integer `n`
such that `p^n` is the identity `Permutation`.
"""
function order(p::AbstractPermutation)
    result = 1
    clist = cycles(p)
    for c in clist
        result = lcm(result, length(c))
    end
    return result
end

# Extend p^n so negative exponents work too
function ^(p::Permutation, n::Int)
    if n == 0
        return Permutation(length(p))
    end
    if n < 0
        return inv(p)^(-n)
    end
    if n == 1
        return p
    end

    m::Int = round(Int, floor(n / 2)) # int(floor(n/2))  # m = floor(n/2)
    q::Permutation = p^m

    if n % 2 == 0   # if even
        return q * q
    end

    return p * q * q
end


# find the fixed points of a Permutation
"""
    fixed_points(p::Permutation)

Return the list of values `k` for which `p(k)==k`.
"""
fixed_points(p::Permutation) = findall([p[k] == k for k = 1:length(p)])

# Find a longest monotone subsequence of p in a given direction. This
# is not exposed, but it is used by longest_increasing and
# longest_increasing.
function longest_monotone(p::Permutation, order = <)::Vector{Int}
    n = length(p)
    if n == 0
        return Int[]
    end
    scores = ones(Int, n)
    scores[n] = 1

    for k = n-1:-1:1
        for i = k+1:n
            if order(p[k], p[i]) && scores[k] <= scores[i]
                scores[k] = scores[i] + 1
            end
        end
    end

    seq = Int[]
    mx = maximum(scores)
    a = findfirst([s == mx for s in scores])
    push!(seq, a)

    while scores[a] > 1
        val = scores[a] - 1
        idx = findfirst([scores[k] == val && order(p[a], p[k]) for k = a+1:n])
        a += idx
        push!(seq, a)
    end

    return [p[i] for i in seq]

end


"""
    longest_increasing(p::Permutation)

Thinking of `p` as a list of values, return a longest subsequence of values
that are in ascending order.
"""
longest_increasing(p::Permutation) = longest_monotone(p, <)

"""
    longest_decreasing(p::Permutation)

Thinking of `p` as a list of values, return a longest subsequence of values
that are in descending order.
"""
longest_decreasing(p::Permutation) = longest_monotone(p, >)

"""
    reverse(p::Permutation)

Thinking of `p` as a list of values,
return a `Permutation` with those values in reverse
sequence.
"""
function reverse(p::Permutation)::Permutation
    d = reverse(p.data)
    return Permutation(d)
end

# hash function so Permutations can be keys in dictionaries, etc.
hash(p::Permutation, h::UInt64) = hash(p.data, h)

"""
    dict(p::Permutation)

Convert a permutation into a dictionary. If `d` is the
result then `d[k]` equals `p(k)` for all `k` in the domain of the
permutation.
"""
function dict(p::Permutation)::Dict{Int,Int}
    n = length(p)
    d = Dict{Int,Int}()
    for i = 1:n
        d[i] = p(i)
    end
    return d
end

"""
    apply_transposition!(p::Permutation, i, j)

Compose a permutation `p` in-place with the transposition `(i, j)`.
"""
function apply_transposition!(p::Permutation, i::Integer, j::Integer)
    n = length(p)
    @assert 0 < i ≤ n && 0 < j ≤ n && i ≠ j
    p.data[i], p.data[j] = p.data[j], p.data[i]
end

"""
    apply_transposition(p::Permutation, i, j)

Return a new permutation obtained by composing `p` with the transposition `(i, j)`.
"""
function apply_transposition(p::Permutation, i::Integer, j::Integer)
    n = length(p)
    @assert 0 < i ≤ n && 0 < j ≤ n && i ≠ j
    data = copy(p.data)
    data[i], data[j] = data[j], data[i]
    return Permutation(data)
end

#####
# Decomposing into Coxeter generators
#####

struct CoxeterGenerator <: AbstractPermutation
    n::Int
    i::Int
    function CoxeterGenerator(n::Int, i::Int)
        1 ≤ i ≤ n - 1 || throw(ArgumentError("$i must be between 1 and $n-1"))
        new(n, i)
    end
end

length(sᵢ::CoxeterGenerator) = sᵢ.n
Permutation(P::CoxeterGenerator) = Permutation([1:P.i-1; P.i + 1; P.i; P.i+2:P.n])

function show(io::IO, p::CoxeterGenerator)
    print(io, "length $(p.n) permutation: s_$(p.i)")
end


# _coxeter_reduce reduces a product of simple transpositions using the relationships
# https://en.wikipedia.org/wiki/Symmetric_group#Generators_and_relations
# combined with a sorting for uniqueness
function _coxeter_reduce!(terms::Vector{Int})
    @label start
    for i = 1:length(terms)-1
        # sᵢ^2 = I
        if terms[i] == terms[i+1]
            deleteat!(terms, i:i+1)
            @goto start
        end
        # sort using sᵢsⱼ = sⱼsᵢ
        if terms[i+1] ≠ terms[i] - 1 && terms[i+1] ≠ terms[i] + 1 && terms[i] > terms[i+1]
            terms[i], terms[i+1] = terms[i+1], terms[i]
            @goto start
        end
    end
    # (sᵢsᵢ₊₁)^3 = I
    for i = 1:length(terms)-5
        if terms[i] + 1 ==
           terms[i+1] ==
           terms[i+2] + 1 ==
           terms[i+3] ==
           terms[i+4] + 1 ==
           terms[i+5]
            deleteat!(terms, i:i+5)
            @goto start
        end
    end

    terms
end


"""
    CoxeterDecomposition(p::Permutation)

Express the `Permutation` `p` as a
composition of transpositions of the form `(k,k+1)`.
"""
struct CoxeterDecomposition <: AbstractPermutation
    n::Int
    terms::Vector{Int}
    function CoxeterDecomposition(n::Int, terms::Vector{Int})
        for t in terms
            1 ≤ t ≤ n - 1 || throw(ArgumentError("$t must be between 1 and $n-1"))
        end
        new(n, _coxeter_reduce!(terms))
    end
end

CoxeterDecomposition(n::Int, terms::AbstractVector) =
    CoxeterDecomposition(n, Vector{Int}(terms))
CoxeterDecomposition(sᵢ::CoxeterGenerator) = CoxeterDecomposition(sᵢ.n, [sᵢ.i])

length(P::CoxeterDecomposition) = P.n

function Permutation(P::CoxeterDecomposition)
    if isempty(P.terms)
        Permutation(1:P.n)
    else
        *(Permutation.(CoxeterGenerator.(P.n, P.terms))...)
    end
end
CoxeterDecomposition(P::Permutation) = CoxeterDecomposition!(Permutation(copy(P.data)))
CoxeterDecomposition!(P::Permutation) =
    CoxeterDecomposition(length(P), _coxeterdecomposition!(P))
function _coxeterdecomposition!(P::Permutation)
    n = length(P)
    data = P.data
    ret = Int[]
    while !issorted(data)
        for k = 1:n-1
            if data[k] > data[k+1]
                data[k], data[k+1] = data[k+1], data[k]
                push!(ret, k)
            end
        end
    end
    reverse!(ret)
end

==(A::CoxeterDecomposition, B::CoxeterDecomposition) = A.terms == B.terms

function *(A::CoxeterGenerator, B::CoxeterGenerator)
    length(A) == length(B) ||
        throw(ArgumentError("Permutations must have same length to multiply"))
    CoxeterDecomposition(length(A), [A.i, B.i])
end
function *(A::CoxeterGenerator, B::CoxeterDecomposition)
    length(A) == length(B) ||
        throw(ArgumentError("Permutations must have same length to multiply"))
    CoxeterDecomposition(length(A), [A.i; B.terms])
end
function *(A::CoxeterDecomposition, B::CoxeterGenerator)
    length(A) == length(B) ||
        throw(ArgumentError("Permutations must have same length to multiply"))
    CoxeterDecomposition(length(A), [A.terms; B.i])
end
function *(A::CoxeterDecomposition, B::CoxeterDecomposition)
    length(A) == length(B) ||
        throw(ArgumentError("Permutations must have same length to multiply"))
    CoxeterDecomposition(length(A), [A.terms; B.terms])
end

invperm(A::CoxeterDecomposition) = CoxeterDecomposition(A.n, reverse(A.terms))

function show(io::IO, p::CoxeterDecomposition)
    print(io, "Permutation of 1:$(length(p)): ")
    if length(p.terms) == 0
        print(io, "()")
    end
    for i in p.terms
        # print(io, "s_$(i)")
        print(io, "($i,$(i+1))")
    end
end


# deprecations
@deprecate array(p::Permutation) p.data
@deprecate matrix(p::Permutation, sparse::Bool = false) sparse ? sparse(p) : Matrix(p)

include("matrix.jl")
include("sqrt.jl")
include("perm_gen.jl")
include("CompiledPermutation.jl")

end # end of module Permutations
