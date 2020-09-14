# Fibonanci numbers

fib(n) = n <= 1 ? 1 : fib(n-1) + fib(n-2)


@time fib(10)

@time fib(20)

@time fib(30)

@time fib(40)

@time fib(50)


table = Dict{Int, Int}(0=>1, 1=>1)


function fib_memoize(n)
    if haskey(table, n)
        return table[n]
    else
        fibn = fib_memoize(n-1) + fib_memoize(n-2)
        table[n]  = fibn
        return fibn
    end
end

@time fib_memoize(10)
@time fib_memoize(50)

using Memoize

@memoize fib(n) = n <= 1 ? 1 : fib(n-1) + fib(n-2)

@time fib(50)
@time fib(100)


@memoize fib(n) = n <= 1 ? BigInt(1) : fib(n-1) + fib(n-2)
@time fib(100)

# using Memoize
# @memoize function ackerman(m, n)
#     if m == 0
#         return BigInt(n) + 1
#     elseif n == 0
#         return ackerman(m-1, 1)
#     else
#         return ackerman(m-1, ackerman(m, n-1))
#     end
# end


# @time res = [ackerman(m,n) for (m, n) in Iterators.product(0:4, 0:4)]
