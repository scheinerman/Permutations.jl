# Represent as a permtuation matrix.
"""
    Matrix(p::Permutation)

Return the permutation matrix for `p`.
"""
function Matrix{T}(p::Permutation) where {T}
    n = length(p)
    A = Matrix{T}(I, n, n)     # A = eye(T,n)   #  int(eye(n))
    return A[:, p.data]
end

Matrix(p::Permutation) = Matrix{Int}(p)
Array(p::Permutation) = Matrix(p)
AbstractMatrix(p::Permutation) = Matrix(p)
AbstractArray(p::Permutation) = Matrix(p)

Array{T}(p::Permutation) where {T} = Matrix{T}(p)
AbstractMatrix{T}(p::Permutation) where {T} = Matrix{T}(p)
AbstractArray{T}(p::Permutation) where {T} = Matrix{T}(p)


function Permutation(M::Matrix)
    n, c = size(M)
    @assert n == c "Matrix must be square"
    v = [findfirst(Bool.(M[:, k])) for k = 1:n]
    return Permutation(v)
end
