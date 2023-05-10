function _insert(σ::Array{Int}, θ)::Array{Int}
    """
    Chinese restaurant process-style insertion.
    """
    n = length(σ)
    u = rand()
    if u < θ / ( θ + n )
        π = [ σ..., n + 1]
    else
        idx = rand(1:n)
        π = [ σ..., σ[idx] ]
        π[ idx ] = n + 1
    end
    π
end

"""
    EwensPermutation(n::Int, theta::Real)

Generates a random permutation under the Ewens distribution. 
"""
function EwensPermutation(n::Int, θ::Real)::Permutation
    θ ≥ 0 || throw(ArgumentError("The Ewens parameter must be a positive real number. "))
    σ = [1]
    for i in 2:n
        σ = _insert(σ, θ)
    end
    Permutation(σ)
end