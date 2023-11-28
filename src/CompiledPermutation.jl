"""
    CompiledPermutation(p::AbstractVector{<:Integer}; zero = false)

Compiles a permutation `p` so it can be efficiently applied to multiple vectors

`cp = CompiledPermutation(p); permute!(v, cp)` is equivalent to `permute!(v, p)`
but much faster if applying the permutation multiple times.

Throws an `ArgumentError` if `p` is not a permutation. Setting `zero = true` will 
run slightly faster and zero out the input permutation.

For long vectors it is often still fastest to permute by copying with `v[p]`.

Mutating the fields of a compiled permutation may cause unsafe memory access.
"""
struct CompiledPermutation{T} <: _AbstractPermutation
    data::T
    length::Int
    function CompiledPermutation(permutation::AbstractVector{<:Integer}; zero = false)

        # Internal workings:

        # Legend:
        # swap   2-cycle
        # cycle  a cycle of length 3 or more
        # nic    nonzero input count, nic == count(nonzero, p)
        # _i     index in the output vector out
        # _j     index in the input vector p
        # p_xxx  the result of p[xxx]

        # Input: standard vector permutation
        # Output: compiled permutation listed in reverse-zero-terminated-cycle notation
        # for cycles of length ≥ 3 followed by a consecutive listing of all swaps.
        # For example,
        #
        # [3, 1, 2] -> [1, 3, 2, 0]
        # [3, 2, 1] -> [0, 1, 3]
        # [3, 4, 1, 2] -> [0, 2, 4, 1, 3]
        # [1, 2, 3, 4] -> []
        # [1, 4, 8, 2, 6, 5, 7, 3] -> [1, 2, 7, 0, 5, 6, 3, 4]

        # Exception! for input vectors of length 2, any nonempty vector signifies the swap
        # permutation while the empty vector signifies the identity permutation.
        #
        # [1, 2] -> []
        # [2, 1] -> [x] where x is arbitrary

        p = zero ? permutation : copy(permutation)
        Base.require_one_based_indexing(p)
        nic = length(p)
        if nic <= 2
            nic == 0 && return new{typeof(p)}(similar(p, 0), 0)
            nic == 1 && p[1] == 1 && return new{typeof(p)}(similar(p, 0), 1)
            nic == 2 && p[1] == 1 && p[2] == 2 && return new{typeof(p)}(similar(p, 0), 2)
            nic == 2 && p[1] == 2 && p[2] == 1 && return new{typeof(p)}(similar(p, 1), 2)
            throw(ArgumentError("Input vector p = $p is not a permutation"))
        end
        out = similar(p, nic + nic ÷ 3 + 1)
        cycle_i = 1
        swap_i = length(out)
        input_j = 1

        Base.@propagate_inbounds function read(idx)
            x = p[idx]
            p[idx] = 0
            x
        end

        @inbounds while true
            nic -= 1
            p_input_j = read(input_j) # where does the head point?
            if input_j < p_input_j <= lastindex(p) # head points valid onward
                nic -= 1
                pp_input_j = read(p_input_j) # where does the head point?
                if pp_input_j == input_j # ...back to the start
                    out[swap_i-1] = input_j # register 2-cycle
                    out[swap_i] = p_input_j
                    swap_i -= 2
                elseif input_j < pp_input_j <= lastindex(p) # ...valid onward
                    out[cycle_i] = input_j      # register the first
                    out[cycle_i+1] = p_input_j  # 3 as the start of
                    cycle_i += 2                # a cycle (including
                                                # start of loop)
                    while true
                        out[cycle_i] = pp_input_j
                        cycle_i += 1
                        nic -= 1
                        pp_input_j = read(pp_input_j) # where does the head point?
                        input_j < pp_input_j <= lastindex(p) || break # ...valid onward
                    end

                    # did we end where we started or end as invalid?
                    pp_input_j == input_j ||
                        throw(ArgumentError("Input vector p is not a permutation"))

                    out[cycle_i] = 0
                    cycle_i += 1
                else # ...invalid
                    throw(ArgumentError("Input vector p is not a permutation"))
                end
            elseif input_j != p_input_j # ...neither valid onward nor fixed point
                throw(ArgumentError("Input vector p is not a permutation"))
            end # fixed point do nothing
            nic == 0 && break
            input_j = findnext(!iszero, p, input_j+1)
        end
        if cycle_i == 1
            cycle_i = 2
            out[1] = 0
        end
        swap_len = lastindex(out) - swap_i
        swap_len != 0  && unsafe_copyto!(out, cycle_i, out, swap_i + 1, swap_len)
        resize!(out, cycle_i - 1 + swap_len)
        new{typeof(p)}(out, length(p))
    end
end

function Base.permute!(v, cp::CompiledPermutation)
    p = cp.data
    l = length(cp)
    Base.require_one_based_indexing(v)
    length(v) == l || throw(DimensionMismatch())
    l < 2 && return v
    i = length(p)
    @inbounds begin
        if l == 2
            if i != 0
                v[1], v[2] = v[2], v[1]
            end
            return v
        end

        while true # swaps
            pi = p[i]
            pi > 0 || break
            pim = p[i-1]
            v[pi], v[pim] = v[pim], v[pi]
            i -= 2
        end
        j = 1
        while j < i # cycles
            a, b, c, d = p[j], p[j+1], p[j+2], p[j+3]
            start = v[a]
            v[a] = v[b]
            v[b] = v[c]
            j += 4
            while d > 0
                v[c] = v[d]
                c = d
                d = p[j]
                j += 1
            end
            v[c] = start
        end
    end
    v
end

# TODO constructing an inverse compiled permutation can be as fast as constructing
# a standard compiled permutation and faster than compiling + inverting.
function invperm!(p::CompiledPermutation)
    length(p) <= 2 && return p
    hi = findlast(iszero, p.data)
    reverse!(view(p.data, 1:hi-1))
    p
end
Base.invperm(p::CompiledPermutation) = invperm!(deepcopy(p))
Base.length(p::CompiledPermutation) = p.length

Permutation(p::CompiledPermutation) = Permutation(permute!(collect(1:length(p)), p))
CompiledPermutation(p::Permutation) = CompiledPermutation(p.data)

function cycles(cp::CompiledPermutation{T}) where T
    out = Vector{eltype(T)}[]

    p = cp.data
    i = length(p)
    while true # swaps
        pi = p[i]
        pi > 0 || break
        pim = p[i-1]
        push!(out, [pi, pim])
        i -= 2
    end
    j = 1
    while j < i # cycles
        a, b, c, d = p[j], p[j+1], p[j+2], p[j+3]
        new = [a, b, c]
        j += 4
        while d > 0
            push!(new, d)
            d = p[j]
            j += 1
        end
        push!(out, new)
    end
    out
end
