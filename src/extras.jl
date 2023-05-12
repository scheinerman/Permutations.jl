function _insert!(σ::Array{Int}, θ, n)::Array{Int}
    """
    Chinese restaurant process-style insertion. With probability ``θ/(θ+n)``, the element ``n`` starts a new cycle; otherwise it is inserted in one of the already existing cycles. 
    """

    if rand() > θ / ( θ + n -1 )
        idx = rand(1:n-1)
        σ[n], σ[idx] = σ[idx], σ[n]
    end
    σ
end

"""
    EwensPermutation(n::Int, theta::Real)

Generates a random, non-uniform permutation ``\\Pi`` under the Ewens distribution with parameter ``\\theta``, that is : ``\\mathbb{P}(\\Pi = \\sigma) = \\frac{\\theta^{c(\\sigma)}}{Z(\\theta)}`` where : 
- ``Z(\\theta)`` is the partition function; in this case, it is equal to ``\\Gamma(n+\\theta)/\\Gamma(\\theta)`` with ``\\Gamma`` the Gamma function
- ``c(\\sigma)`` is the number of cycles of the permutation ``\\sigma``. 

The sampling uses the [Chinese Restaurant Process](https://en.wikipedia.org/wiki/Chinese_restaurant_process) insertion. 
"""
function EwensPermutation(n::Int, θ::Real)::Permutation
    θ ≥ 0 || throw(ArgumentError("The Ewens parameter must be a positive real number. "))
    σ = collect(1:n)
    for rank in 2:n
        _insert!(σ, θ, rank)
    end
    Permutation(σ)
end