using Base.Test
using Permutations
p = Permutation(collect(7:-1:1))
i = Permutation(7)
@test p*p == i
@test p == inv(p)
a =[2,3,1,6,7,8,5,4,9]
p = Permutation(a)
@test order(p) == 6
@test p^6 == Permutation(9)
@test p^-5 == p
@test array(p)==a

q = Permutation([1,5,3,9,4,8,6,7,2])
@test p*q != q*p
@test q[2] == 5

P = matrix(p)
Q = matrix(q)
@test P*Q == matrix(q*p)
@test P' == matrix(inv(p))

row = [1,3,5,2,4,6]
p = Permutation(row)
@test length(p) == 6
@test p[1] == 1
@test length(longest_increasing(p)) == 4
@test length(longest_decreasing(p)) == 2
@test length(fixed_points(p)) == 2
@test sign(p) == -1
@test hash(p) == hash(p.data)

M = two_row(p)
@test M[2,:] == row

@test Permutation(6,1) == Permutation(6)

p = RandomPermutation(10)
@test p*inv(p) == Permutation(10)
@test reverse(reverse(p)) == p
