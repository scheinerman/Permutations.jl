# Module written by Ed Scheinerman, ers@jhu.edu
# distributed under terms of the MIT license

module Permutations

import Base: length, show, inv, reverse, ==, getindex, *, ^, sign, hash, getindex,
                Matrix, Array, AbstractMatrix, AbstractArray, Array,
                SparseMatrixCSC, AbstractSparseMatrix, AbstractSparseArray, sparse

import Combinatorics: nthperm

export Permutation, RandomPermutation
export length, getindex, array, two_row
export inv, cycles, cycle_string
export order, matrix, fixed_points
export longest_increasing, longest_decreasing, reverse, sign
export hash
export CoxeterGenerator, CoxeterDecomposition

# Defines the Permutation class. Permutations are bijections of 1:n.


abstract type AbstractPermutation end

"""
* `Permutation(list)` creates a new `Permutation`. Here `list` must be a rearrangement of `1:n`.
* `Permutation(n)` creates the identity `Permutation` of `1:n`.
* `Permutation(n,k)` creates the `k`'th `Permutation` of `1:n`.
"""
struct Permutation <: AbstractPermutation
    data::Vector{Int}
    function Permutation(dat::Vector{Int})
        n = length(dat)
        if sort(dat) != collect(1:n)
            error("Improper array: must be a permutation of 1:n")
        end
        new(dat)
    end
end

Permutation(v::AbstractVector) = Permutation(Vector{Int}(v))

# create the k'th permutation of 1:n
function Permutation(n,k)
    return Permutation(nthperm(collect(1:n),k))
end

# create the identity permutation
Permutation(n::Int) = Permutation(collect(1:n))

"""
`RandomPermutation(n)` creates a random permutation of `1:n`,
each with probability `1/factorial(n)`.
"""
RandomPermutation(n::Int) = Permutation(randperm(n))

# Returns the number of elements in the Permtuation

"""
`length(p)` is the number of elements in the `Permutation` `p`.
"""
function length(p::Permutation)
    return length(p.data)
end

# Check for equality of permutations
==(p::Permutation, q::Permutation) = p.data==q.data

# Apply the Permutation to an element: p[k]
function getindex(p::Permutation, k::Int)
    return p.data[k]
end


# Create a two-row representation of this permutation
"""
`two_row(p)` creates a two-row representation of the `Permutation` `p`
in which the first row is `1:n` and the second row are the
values `p(1), p(2), ..., p(n)`.
"""
function two_row(p::Permutation)
    n = length(p)
    return [ (1:n)'; p.data']
end

# Composition of two permutations
function *(p::Permutation, q::Permutation)
    n = length(p)
    if n != length(q)
        error("Cannot compose Permutations of different lengths")
    end
    @inbounds dat = [ p.data[q.data[k]] for k in 1:n ]
    return Permutation(dat)
end

# Inverse of a permutation
"""
`inv(p)` gives the inverse of `Permutation` `p`.
"""
function inv(p::Permutation)
    n = length(p)
    data = zeros(Int,n)
    for k=1:n
        @inbounds j = p.data[k]
        @inbounds data[j] = k
    end
    return Permutation(data)
end

# Find the cycles in a permutation
"""
`cycles(p)` returns a list of the cycles in `Permutation` `p`.
"""
function cycles(p::Permutation)
    n = length(p)
    result = Array{Int,1}[]
    todo = trues(n)
    while any(todo)
        k = find(todo)[1]
        todo[k] = false
        cycle = [k]
        j = p[k]
        while j != k
            append!(cycle,[j])
            todo[j] = false
            j = p[j]
        end
        push!(result, cycle)
    end
    return result
end

"""
`cycle_string(p)` creates a nice, prinatble string representation
from the cycle structure of the permutation `p`.
"""
function cycle_string(p::Permutation)
    if length(p)==0
        return "()"
    end
    str = ""
    cc = cycles(p)
    for c in cc
        str *= array2string(c)
    end
    return str
end

# helper function for cycle_string (not exposed). Converts an integer
# array such as [1,3,5,2] into the string "(1,3,5,2)".
function array2string(a::Array{Int,1})
    n = length(a)
    res = "("
    for k=1:n
        res *= string(a[k])
        if k<n
            res *= ","
        else
            res *= ")"
        end
    end
    return res
end

"""
`sign(p)` is `+1` is `p` is an even `Permtuation` and `-1` if p is odd.
"""
function sign(p::Permutation)
    cc = cycles(p)
    szs = [ length(c)+1 for c in cc ]
    par = sum(szs)%2
    return (par>0) ? -1 : 1
end


# When we print a permutation, it appears in disjoint cycle format.
function show(io::IO, p::Permutation)
    print(io, cycle_string(p))
end

# Find the smallest positive n such that p^n is the identity
"""
`order(p)` is the smallest positive integer `n`
such that `p^n` is the identity `Permutation`.
"""
function order(p::Permutation)
    result = 1
    clist = cycles(p)
    for c in clist
        result = lcm(result, length(c))
    end
    return result
end

# Extend p^n so negative exponents work too
function ^(p::Permutation, n::Int)
    if n==0
        return Permutation(length(p))
    end
    if n<0
        return inv(p)^(-n)
    end
    if n==1
        return p
    end

    m::Int = round(Int,floor(n/2)) # int(floor(n/2))  # m = floor(n/2)
    q::Permutation = p^m

    if n%2 == 0   # if even
        return q*q
    end

    return p*q*q
end

# Represent as a permtuation matrix.
"""
`Matrix(p)` returns the permutation matrix for the `Permutation` `p`.
"""
function Matrix{T}(p::Permutation) where T
    n = length(p)
    A = eye(T,n)   #  int(eye(n))
    return A[p.data,:]
end

Matrix(p::Permutation) = Matrix{Int}(p)
Array(p::Permutation) = Matrix(p)
AbstractMatrix(p::Permutation) = Matrix(p)
AbstractArray(p::Permutation) = Matrix(p)

Array{T}(p::Permutation) where T = Matrix{T}(p)
AbstractMatrix{T}(p::Permutation) where T = Matrix{T}(p)
AbstractArray{T}(p::Permutation) where T = Matrix{T}(p)


"""
`SparseMatrixCSC(p)` returns the permutation matrix for the `Permutation` `p`.
"""
function SparseMatrixCSC{T}(p::Permutation) where T
    n = length(p)
    A = speye(T,n)   #  int(eye(n))
    return A[p.data,:]
end

SparseMatrixCSC(p::Permutation) = SparseMatrixCSC{Int}(p)
AbstractSparseMatrix(p::Permutation) = SparseMatrixCSC{Int}(p)
AbstractSparseArray(p::Permutation) = SparseMatrixCSC{Int}(p)
AbstractSparseMatrix{T}(p::Permutation) where T = SparseMatrixCSC{T}(p)
AbstractSparseArray{T}(p::Permutation) where T = SparseMatrixCSC{T}(p)

sparse(p::Permutation) = SparseMatrixCSC(p)


# find the fixed points of a Permutation
"""
`fixed_points(p)` returns the list of values `k` for which `p(k)==k`.
"""
fixed_points(p::Permutation) = find([ p[k]==k for k in 1:length(p)])

# Find a longest monotone subsequence of p in a given direction. This
# is not exposed, but it is used by longest_increasing and
# longest_increasing.
function longest_monotone(p::Permutation, order=<)
    n = length(p)
    if n==0
        return Int[]
    end
    scores = ones(Int,n)
    scores[n] = 1

    for k=n-1:-1:1
        for i=k+1:n
            if order(p[k],p[i]) && scores[k] <= scores[i]
                scores[k] = scores[i]+1
            end
        end
    end

    seq = Int[]
    mx = maximum(scores)
    a = findfirst([s == mx for s in scores])
    push!(seq,a)

    while scores[a] > 1
        val = scores[a]-1
        idx = findfirst([scores[k]==val && order(p[a],p[k]) for k=a+1:n ])
        a += idx
        push!(seq,a)
    end

    return [p[i] for i in seq]

end

"""
Let `p` be a `Permutation`. Thinking of this as a list of values,
`longest_increasing(p)` returns a longest subsequence of values
that are in ascending order
"""
longest_increasing(p::Permutation) = longest_monotone(p,<)

"""
Let `p` be a `Permutation`. Thinking of this as a list of values,
`longest_decreasing(p)` returns a longest subsequence of values
that are in descending order
"""
longest_decreasing(p::Permutation) = longest_monotone(p,>)

"""
Let `p` be a `Permutation`. Thinking of `p` as a list of values,
`reverse(p)` creates a `Permutation` with those values in reverse
sequence.
"""
function reverse(p::Permutation)
    d = reverse(p.data)
    return Permutation(d)
end

# hash function so Permutations can be keys in dictionaries, etc.
hash(p::Permutation, h::UInt64) = hash(p.data,h)


#####
# Decomposing into Coxeter generators
#####

struct CoxeterGenerator <: AbstractPermutation
    n::Int
    i::Int
end

length(sᵢ::CoxeterGenerator) = sᵢ.n
Permutation(P::CoxeterGenerator) = Permutation([1:P.i-1; P.i+1; P.i; P.i+2:P.n])

function show(io::IO, p::CoxeterGenerator)
    print(io, "length $(p.n) permutation: s_$(p.i)")
end

struct CoxeterDecomposition <: AbstractPermutation
    terms::Vector{CoxeterGenerator} # TODO: How do you make sure this decomposition is unique?
end

Permutation(P::CoxeterDecomposition) = *(Permutation.(P.terms)...)
CoxeterDecomposition(P::Permutation) = CoxeterDecomposition!(Permutation(copy(P.data)))
CoxeterDecomposition!(P::Permutation) = CoxeterDecomposition(CoxeterGenerator.(length(P), _coxeterdecomposition!(P)))
function _coxeterdecomposition!(P::Permutation)
    n = length(P)
    data = P.data
    ret = Int[]
    while !issorted(data)
        for k=1:n-1
            if data[k] > data[k+1]
                data[k], data[k+1] =  data[k+1], data[k]
                push!(ret, k)
            end
        end
    end
    reverse!(ret)
end

==(A::CoxeterDecomposition, B::CoxeterDecomposition) = A.terms == B.terms

*(A::CoxeterGenerator, B::CoxeterGenerator) = CoxeterDecomposition([A,B])
*(A::CoxeterGenerator, B::CoxeterDecomposition) = CoxeterDecomposition([A; B.terms])
*(A::CoxeterDecomposition, B::CoxeterGenerator) = CoxeterDecomposition([A.terms; B])
*(A::CoxeterDecomposition, B::CoxeterDecomposition) = CoxeterDecomposition([A.terms; B.terms])

function show(io::IO, p::CoxeterDecomposition)
    print(io, "length $(first(p.terms).n) permutation: ")
    for s in p.terms
        print(io, "s_$(s.i)")
    end
end

@deprecate array(p::Permutation) p.data
@deprecate matrix(p::Permutation, sparse::Bool = false) sparse ? sparse(p) : Matrix(p)


end # end of module Permutations
