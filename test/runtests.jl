using Test
using Permutations

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
    @test hash(p) == hash(p.data)

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

@testset "Transposition function" begin
    p = Transposition(10, 3, 6)
    @test p == inv(p)
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
end
