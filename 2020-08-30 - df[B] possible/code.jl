

using Tullio

function tullio(x)
    r = Vector{Int}(undef, 1)
    xs = reshape(x, :, 1)
    @tullio r[i] = xs[j, i] != xs[j-1, i]
    r[1]
end

using BenchmarkTools
@benchmark tullio(x)

using LoopVectorization

using CUDA

x = Int32.(x)

function lv(x)
    sum(diff(cu(x)))
end

using Memoize

@memoize function fib(n)
    if n <= 1
        return BigInt(1)
    end

    return fib(n-1) + fib(n-2)
end

@time fib(40)

function fib(n, dict = Dict{Int, Int}())
    if n <= 1
        return 1
    end

    return fib(n-1) + fib(n-2)
end

@time fib(42)


function fib(n)
    if n <= 1
        return 1
    end

    return fib(n-1) + fib(n-2)
end

@time fib(100)

function collatz_length(n)
    if n == 1
        return 0
    end

    if iseven(n)
        return 1+collatz_length(div(n, 2))
    else
        return 1+collatz_length(3n+1)
    end
end

@time argmax(map(collatz_length, 1:1_000_000))


using Memoize

@memoize function collatz_length(n)
    if n == 1
        return 0
    end

    if iseven(n)
        return 1+collatz_length(div(n, 2))
    else
        return 1+collatz_length(3n+1)
    end
end

@time argmax(map(collatz_length, 1:1_000_000))



x = rand(1:1_000_000, 1_000_000_000)

using SortingLab
fsort!(x)

function unroll_loop(x)
    count = 0

    @inbounds count += x[1] != x[2]
    @inbounds count += x[2] != x[3]
    @inbounds count += x[3] != x[4]
    @inbounds count += x[4] != x[5]
    @inbounds count += x[5] != x[6]
    @inbounds count += x[6] != x[7]
    @inbounds count += x[7] != x[8]
    @inbounds count += x[8] != x[9]

    l = length(x)
    upto = 8div(l, 8) - 8

    @inbounds for i in 8:8:upto
        count += x[i+1] != x[i+2]
        count += x[i+2] != x[i+3]
        count += x[i+3] != x[i+4]
        count += x[i+4] != x[i+5]
        count += x[i+5] != x[i+6]
        count += x[i+6] != x[i+7]
        count += x[i+7] != x[i+8]
        count += x[i+8] != x[i+9]
    end

    for i in upto+1:l
        count += x[i] != x[i-1]
    end
    count
end

@benchmark unroll_loop(x)

using LoopVectorization

function nunique(x)
    count = 1

    @avx for i in 1:length(x)-1
        count += !isequal(x[i], x[i+1])
    end

    count
end

@time nunique(x)

function lo_hi_partition(n, parts = Threads.nthreads())
    part_len = div(n, parts)

    lo = collect(0:part_len:n-part_len) .+ 1
    hi = similar(lo)
    hi[1:end-1] .= lo[2:end] .- 1
    hi[end] = n
    lo, hi
end

lo_hi_partition(length(x))

function pnunique(x)
    lo, hi = lo_hi_partition(length(x))

    cnt = 1

    nt = Threads.nthreads()

    Threads.@threads for i in 1:nt
        l, h = lo[i], hi[i]
        @inbounds cnt += nunique(@view x[l:h])
    end

    for (l, h) in zip(@view(lo[2:end]), hi)
        @inbounds cnt -= isequal(x[h], x[l])
    end

    cnt
end

@benchmark pnunique(x)


@time simple_loop(x)
@benchmark simple_loop(x)







using DataFrames


df1 = DataFrame(a = repeat([1], 100), b = "a")
df2 = DataFrame(a = repeat([2], 100), b = "b")

B = Array{Bool, 2}(undef, 100, 2)

df1[B] # doesn't work

# Let's overload get index get index

function Base.getindex(df::AbstractDataFrame, B::AbstractArray{Bool, 2})
    @assert size(B) == size(df)

    res = []

    for (colnumber, Bcol) in enumerate(eachcol(B))
        res = vcat(res, df[Bcol, colnumber])
    end

    res
end

df1[B]

# How do I make assignment work? df1[B] = df2[B]
# Overload the Base.setindex! method
function Base.setindex!(df::AbstractDataFrame, vals_to_assign, B::AbstractArray{Bool, 2})
    @assert size(B) == size(df)

    idx_to_assign = findall(B)

    @assert length(idx_to_assign) == length(vals_to_assign)

    for (idx, val) in zip(idx_to_assign, vals_to_assign)
        df[idx] = val
    end

    vals_to_assign
end

# check the vaules should be 1 and "a"
df1[B]

# check the vaules should be 2 and "b"
df2[B]

df1[B] = df2[B]

# viola!
df1[B]

df1
