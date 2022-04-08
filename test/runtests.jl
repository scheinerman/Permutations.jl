using Test
using Permutations
using Random

@testset verbose = true "Permutations.jl" begin

@testset "Permutation" begin
    p = Permutation(7:-1:1)
    i = Permutation(7)
    @test p * p == i
    @test p == inv(p)
    a = [2, 3, 1, 6, 7, 8, 5, 4, 9]
    p = Permutation(a)
    @test order(p) == 6
    @test p^6 == Permutation(9)
    @test p^-5 == p
    @test p.data == a

    q = Permutation([1, 5, 3, 9, 4, 8, 6, 7, 2])
    @test p * q != q * p
    @test q[2] == 5
    @test q(2) == 5

    P = Matrix(p)
    Q = Matrix(q)
    @test P * Q == Matrix(p * q)
    @test P' == Matrix(inv(p))

    row = [1, 3, 5, 2, 4, 6]
    p = Permutation(row)
    @test length(p) == 6
    @test p[1] == 1
    @test length(longest_increasing(p)) == 4
    @test length(longest_decreasing(p)) == 2
    @test length(fixed_points(p)) == 2
    @test sign(p) == -1
    if Sys.WORD_SIZE == 32
        @test_skip hash(p) == hash(p.data)
    else
        @test hash(p) == hash(p.data)
    end

    M = two_row(p)
    @test M[2, :] == row

    @test Permutation(6, 1) == Permutation(6)

    p = RandomPermutation(10)
    @test p * inv(p) == Permutation(10)
    @test p' * p == Permutation(10)
    @test reverse(reverse(p)) == p

    a, b, c, d = Permutation([2, 1, 3, 4]),
    Permutation([1, 2, 4, 3]),
    Permutation([1, 3, 2, 4]),
    Permutation([2, 1, 3, 4])

    @test Matrix(a * b * c * d) == Matrix(a) * Matrix(b) * Matrix(c) * Matrix(d)

    p = RandomPermutation(12)
    d = dict(p)
    for k = 1:12
        @test p(k) == d[k]
    end
    for (k, x) in enumerate(p)
        @test x == d[k]
    end

    p = RandomPermutation(12)
    pp = p * p
    q = sqrt(pp)
    @test q * q == pp

end

@testset "Cycles" begin
    p = Permutation(10)
    @test length(cycles(p)) == 10
    p = Permutation([2, 3, 4, 5, 1])
    @test length(cycles(p)) == 1

    for i = 1:10
        p = RandomPermutation(20)
        cp = cycles(p)
        @test Permutation(cp) == p
    end
end

@testset "Transpositions" begin
    p = Transposition(10, 3, 6)
    @test p == inv(p)

    p1 = Permutation(1:10)
    p2 = apply_transposition(p1, 3, 7)
    @test p2.data == [1, 2, 7, 4, 5, 6, 3, 8, 9, 10]
    @test p1 == p2 * p2
    apply_transposition!(p1, 3, 7)
    @test p1 == p2
end

@testset "Matrix conversion" begin
    p = RandomPermutation(10)
    M = Matrix(p)
    q = Permutation(M)
    @test p == q
end

@testset "CoxeterDecomposition" begin
    n = 10
    p = RandomPermutation(n)
    c = CoxeterDecomposition(p)
    @test p == Permutation(c)


    @test inv(c) * c == CoxeterDecomposition(n, Int[])
    @test inv(c) == c'

    @test CoxeterDecomposition(5, [3, 4, 1]) == CoxeterDecomposition(5, [1, 3, 4])
    @test CoxeterDecomposition(5, [2, 1, 3, 4, 1]) == CoxeterDecomposition(5, [2, 3, 4])
    @test CoxeterDecomposition(5, [1, 3, 4, 3, 4, 3, 4, 1]) ==
          CoxeterDecomposition(5, Int[])

    @test Permutation(CoxeterDecomposition(5, Int[])).data ≈ 1:5
    @test Permutation(CoxeterDecomposition(5, [1])).data == [2; 1; 3:5]
    @test inv(CoxeterDecomposition(6, [1, 3, 5])) == CoxeterDecomposition(6, [1, 3, 5])
    @test CoxeterDecomposition(RandomPermutation(100)) isa CoxeterDecomposition # check for stack overflow
end


@testset "PermGen" begin
    X = PermGen(4)
    @test length(X) == factorial(4)

    d = [[2, 3, 4], [1, 3, 4], [1, 2, 4], [1, 2, 3]]
    X = PermGen(d)
    @test sum(length(fixed_points(p)) for p in X) == 0

    X = DerangeGen(5)
    @test length(collect(X)) == 44
end

@testset verbose = true "CompiledPermutation" begin

    @test_throws ArgumentError CompiledPermutation([4, 3, 3, 5, 1])        

    @testset "Construction & permute! (exhaustive)" begin
        # lots of tests because we use a complex algorithm with @inbounds
        # and don't want to risk segfaults or memory corruption

        N0, N1 = (4, 4) #Set to (5, 20) or more when actively developing CompiledPermutation
        Random.seed!(1729)
        t = @elapsed for n in vcat(0:2000)
            p = fill(0, n)
            v = rand(n)
            all = n <= N0
            for i in 1:(all ? (n+3)^n : N1)
                if all
                    digits!(p, i, base=n+3)
                    p .-= 2
                elseif i < N1 ÷ 2
                    rand!(p, -1:n+1)
                else
                    p .= 1:n
                    shuffle!(p)
                end
                if (all || i < N1 ÷ 2) && (sum(p) != sum(1:n) || sort(p) != collect(1:n))
                    @test_throws ArgumentError CompiledPermutation(p)
                else
                    @test v[p] == permute!(v, CompiledPermutation(p)) === v
                end
            end
        end
        println("Exhaustive tests took $t seconds.")
    end

    @testset "order" begin
        @test order(CompiledPermutation([2, 3, 1, 6, 7, 8, 5, 4, 9])) == 6
    end
end

end
