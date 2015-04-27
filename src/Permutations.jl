# Module written by Ed Scheinerman, ers@jhu.edu
# distributed under terms of the MIT license

module Permutations

import Base.length, Base.show, Base.inv, Base.reverse, Base.isequal
import Base.hash, Base.isless

export Permutation, RandomPermutation
export length, getindex, array, two_row
export inv, ctranspose, cycles, cycle_string, parity
export order, matrix, fixed_points
export longest_increasing, longest_decreasing, reverse

# Defines the Permutation class. Permutations are bijections of 1:n.
immutable Permutation
    data::Array{Int,1}
    function Permutation(dat::Array{Int,1})
        n = length(dat)
        isperm(dat) || error("Improper array: must be a permutation of 1:n")
        new(dat)
    end
end

# To use Permutation objects as keys in dictionaries, etc, we need to
# be able to hash them.
function hash(P::Permutation, h::Uint64=zero(Uint64))
    return hash(P.data,h)
end

# create the k'th permutation of 1:n
function Permutation(n,k)
    return Permutation(nthperm(collect(1:n),k))
end

# create the identity permutation
Permutation(n::Int) = Permutation(collect(1:n))

RandomPermutation(n::Int) = Permutation(randperm(n))

# Returns the number of elements in the Permtuation
function length(p::Permutation)
    return length(p.data)
end

# Check for equality of permutations
==(p::Permutation, q::Permutation) = p.data==q.data
isequal(p::Permutation, q::Permutation) = p==q

# Define isless so we can sort lists of permutations
function isless(p::Permutation, q::Permutation)
    # first check no. of el'ts
    np = length(p)
    nq = length(q)
    if np < nq
        return true
    end
    if np > nq
        return false
    end

    # now step through the data
    for j=1:np
        if p.data[j] < q.data[j]
            return true
        end
        if p.data[j] > q.data[j]
            return false
        end
    end
    # if we reach this point, the permutations are equal so
    return false
end



# Apply the Permutation to an element: p[k]
function getindex(p::Permutation, k::Int)
    return p.data[k]
end

# Convert this Permutation into a one-dimensional array of integers
function array(p::Permutation)
    return collect(p.data)
end

# Create a two-row representation of this permutation
function two_row(p::Permutation)
    n = length(p)
    return [ (1:n)', p.data']
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
function inv(p::Permutation)
    n = length(p)
    data = zeros(Int,n)
    for k=1:n
        @inbounds j = p.data[k]
        @inbounds data[j] = k
    end
    return Permutation(data)
end

# Faster way to type inv(p)
ctranspose(p::Permutation) = inv(p)


# Find the cycles in a permutation
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

# Create a nice, printable string representation from the cycle
# structure of a permutation
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

# Determine the parity of this permutation (0=even, 1=odd)
function parity(p::Permutation)
    cc = cycles(p)
    szs = [ length(c)+1 for c in cc ]
    return sum(szs)%2
end

# When we print a permutation, it appears in disjoint cycle format.
function show(io::IO, p::Permutation)
    print(io, cycle_string(p))
end

# Find the smallest positive n such that p^n is the identity
function order(p::Permutation)
    result = 1
    clist = cycles(p)
    for c in clist
        result = lcm(result, length(c))
    end
    return result
end

# p is the permutation vector
# pret is the return vector
# ptmp is workspace
function permpower!{T<:Real}(p::AbstractVector{T},
                             pret::AbstractVector{T},
                             ptmp::AbstractVector{T},                           
                             n::Integer)
    onep = one(T)
    lenp = convert(T,length(p))
    n == 0 && (for i in onep:lenp pret[i] = i end; return )
    n < 0  && (permpower!(invperm(p), pret, ptmp, -n); return )
    n == 1 && (copy!(pret,p); return)
    permpower!(p, ptmp, pret,floor(Int, n/2))
    if iseven(n)
        for i in onep:lenp pret[i] = ptmp[ptmp[i]] end
    else
        for i in onep:lenp pret[i] = p[ptmp[ptmp[i]]] end
    end
end


function ^(p::Permutation, n::Integer)
    n == 0 && return Permutation(length(p))
    n == 1 && return p
    pret = similar(p.data)
    ptmp = similar(p.data)
    permpower!(p.data,pret,ptmp,n)
    return Permutation(pret)
end

# Represent as a permtuation matrix.
function matrix(p::Permutation, sparse::Bool = false)
    n = length(p)
    if sparse
        A = speye(Int,n)
    else
        A = eye(Int, n)
    end
    return A[array(p),:]
end

# find the fixed points of a Permutation
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

longest_increasing(p::Permutation) = longest_monotone(p,<)
longest_decreasing(p::Permutation) = longest_monotone(p,>)


function reverse(p::Permutation)
    d = reverse(p.data)
    return Permutation(d)
end


end # end of module Permutations
