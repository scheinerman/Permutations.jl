"""
`sort_by_size(list)` returns a sorted copy of `list`
in which the elements are sorted by the `length` function
(from smallest to largest).
"""
function sort_by_size(list::Array)
    sort(list,lt=((x,y) -> length(x) < length(y)))
end

import Base.sqrt

function weave(c::Array{Int,1})::Array{Int,1}
    nc = length(c)
    if nc%2 == 0
        error("Attempting to weave $c, an even-length cycle, with itself")
    end
    half = Int((nc+1)/2)
    result = zeros(Int,nc)
    j = 1  # index into c
    jj = 1  # index into result
    while j <= nc
        result[j] = c[jj]
        j += 1
        jj = (jj+half) % nc
        if jj == 0
            jj = nc
        end
    end
    return result
end

function weave(c1::Array{Int,1}, c2::Array{Int,1})::Array{Int,1}
    n1 = length(c1)
    n2 = length(c2)
    @assert n1==n2 "Cycles $c1 and $c2 have different lengths"
    @assert n1%2==0 "Cycles must have even length to be weaved together"

    result = zeros(Int,2n1)
    for j=1:n1
        result[2j-1]=c1[j]
        result[2j]=c2[j]
    end
    return result
end
"""
`sqrt(p::Permutation)` returns a `Permutation` `q` such that
`q*q==p`. Note: There may be other square roots besides the one
returned. If `p` does not have a square root, an error is thrown.
"""
function sqrt(p::Permutation)::Permutation
    err_msg = "This permutation does not have a square root"
    n = length(p)
    clist = sort_by_size(cycles(p))
    nc = length(clist)
    result = zeros(Int,n)

    idx = 1
    while idx <= nc
        cyc = clist[idx]  # next cycle to process
        m = length(cyc)
        if m%2 == 1   # an odd cycle
            tmp = weave(cyc)
            for j=1:m-1
                result[tmp[j]] = tmp[j+1]
            end
            result[tmp[m]] = tmp[1]
            idx += 1
        else
            if idx == nc
                error(err_msg)
            end
            cyc2 = clist[idx+1]
            if length(cyc2) != length(cyc)
                error(err_msg)
            end
            tmp = weave(cyc,cyc2)
            for j=1:2m-1
                result[tmp[j]] = tmp[j+1]
            end
            result[tmp[2m]] = tmp[1]
            idx += 2
        end
    end
    return Permutation(result)
end

√(p::Permutation) = sqrt(p)
