function make_lists(d::Dict{Int,Vector{Int}})
    n = maximum(keys(d))
    allow = [d[k] for k = 1:n]
    return allow
end


"""
    iter_perms

This unexported method is the engine beneth `GenPerms`. The difference is this 
returns a list of vectors, where each vector is a permutation of `1:n` based 
on the table in `allow`.
"""
function iter_perms(allow::Vector{Vector{Int}}, p::Vector{Int} = Int[])
    n = length(allow)
    k = length(p)

    if n == k
        return [p]
    end

    valid_nexts = setdiff(allow[k+1], p)
    nested_its = Iterators.map((x) -> iter_perms(allow, [p; x]), valid_nexts)
    return Iterators.flatten(nested_its)
end

iter_perms(d::Dict{Int,Vector{Int}}) = iter_perms(make_lists(d))





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
function PermGen(allow::Vector{Vector{Int}})
    X = iter_perms(allow)
    return Iterators.map(Permutation, X)
end
PermGen(d::Dict{Int,Vector{Int}}) = PermGen(make_lists(d))

PermGen(n::Int) = Base.Generator(Permutation, permutations(1:n))




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

export DerangeGen

"""
    DerangeGen(n::Int)

Create an iterator for all derangements of `{1,2,...,n}`. These are 
all permutations without any fixed points. 
"""
DerangeGen(n::Int) = PermGen(deranged_allow(n))
