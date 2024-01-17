export extend
"""
    extend(p::Permutation, new_n::Integer)::Permutation

Given a `Permutation` `p` of `1:n`, create a new `Permutation` of `1:new_n`
that agrees with `p` on elements `1:n` and is the identity on the added extra
elements.

Example
=======
```
julia> p
(1)(2,9,6,7)(3,10,8,5)(4)

julia> extend(p,15)
(1)(2,9,6,7)(3,10,8,5)(4)(11)(12)(13)(14)(15)
```
"""
function extend(p::Permutation, new_n::Integer)::Permutation
    np = length(p)
    @assert new_n >= np "Requested length ($new_n) is smaller than the permutation's length ($np)"
    extras = collect(np+1:new_n)
    new_data = [p.data; extras]
    return Permutation(new_data)
end