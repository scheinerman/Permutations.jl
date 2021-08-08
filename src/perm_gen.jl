
function make_lists(allow::Vector{Vector{Int}})
    n = length(allow)
    ranges = Tuple(allow)
    return Base.Generator(vectorize, Iterators.product(ranges...))
end


function make_lists(d::Dict{Int,Vector{Int}})
    n = maximum(keys(d))
    allow = [d[k] for k = 1:n]
    return make_lists(allow)
end

vectorize(a::NTuple{N,Int}) where {N} = [a...]

function is_ok_perm(v::Vector{Int})
    n = length(v)
    if any(v .> n) || any(v .< 1) || length(v) != length(unique(v))
        return false
    end
    return true
end

function is_ok_perm(t::NTuple{N,Int}) where {N}
    v = [t...]
    is_ok_perm(v)
end



function RPG(allow::Dict{Int,Vector{Int}})
    return Iterators.filter(is_ok_perm, make_lists(allow))
end

function RPG(allow::Vector{Vector{Int}})
    return Iterators.filter(is_ok_perm, make_lists(allow))
end


export PermGen


"""
    PermGen

Create an iterator for permutations.
* `PermGen(n::Int)` creates an iterator for all permutations of length `n`.
* `PermGen(d::Dict{Int,Vector{Int}})` creates an iterator for all permutations in which 
   element `k` may be a value in `d[k]`. Alternatively, `d` may be a `Vector` of `Vectors`.

Examples
--------
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


julia> d = [[2,3,4], [1,3,4], [1,2,4], [1,2,3]];

julia> for p in PermGen(d)
       println(p)
       end
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
"""
PermGen(n::Int) = Base.Generator(Permutation, permutations(1:n))
PermGen(d::Dict{Int,Vector{Int}}) = Base.Generator(Permutation, RPG(d))
PermGen(d::Vector{Vector{Int}}) = Base.Generator(Permutation, RPG(d))




function deranged_allow(n::Int)
    d = Dict{Int,Vector{Int}}()
    base = collect(1:n)
    for k = 1:n
        d[k] = setdiff(base, k)
    end
    return d
end

function all_allow(n::Int)
    d = Dict{Int,Vector{Int}}()
    base = collect(1:n)
    for k = 1:n
        d[k] = base
    end
    return d
end
