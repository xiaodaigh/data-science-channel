x = Vector{Union{Missing, Float64}}(missing, 100_000_000)
x[rand(1:100_000_000, 90_000_000)] .= rand.()

using DataFrames
a = DataFrame(a=1:3)

vscodedisplay(a)

# simple and effective
@time count(ismissing, x)
@time count(ismissing, x)

using BenchmarkTools

@benchmark count($ismissing, $x)
# BenchmarkTools.Trial:
#   memory estimate:  0 bytes
#   allocs estimate:  0
#   --------------
#   minimum time:     48.468 ms (0.00% GC)
#   median time:      51.755 ms (0.00% GC)
#   mean time:        66.863 ms (0.00% GC)
#   maximum time:     91.449 ms (0.00% GC)
#   --------------
#   samples:          76
#   evals/sample:     1

function unsafe_count_missing(x::Vector{Union{Missing, T}}) where T
    @assert isbitstype(T)
    l = length(x)
    res = l

    GC.@preserve x begin
        y = unsafe_wrap(Vector{UInt8}, Ptr{UInt8}(pointer(x) + sizeof(T)*l), l)
        @inbounds for i in 1:l
            res -= y[i]
        end
    end
    res
end

@time unsafe_count_missing(x)
@time unsafe_count_missing(x)

@time count(ismissing, x) == unsafe_count_missing(x)

@benchmark unsafe_count_missing($x)
# BenchmarkTools.Trial:
#   memory estimate:  80 bytes
#   allocs estimate:  1
#   --------------
#   minimum time:     9.190 ms (0.00% GC)
#   median time:      9.718 ms (0.00% GC)
#   mean time:        9.845 ms (0.00% GC)
#   maximum time:     15.691 ms (0.00% GC)
#   --------------
#   samples:          508
#   evals/sample:     1


function count_missing(x)
    c = 0
    @inbounds for i in eachindex(x)
        c += ismissing(x[i])
    end
    return c
end

function count_nonmissing(x)
    c = 0
    @inbounds for i in eachindex(x)
        c += !ismissing(x[i])
    end
    return c
end

@assert count_missing(x) == length(x) - count_nonmissing(x) == unsafe_count_missing(x)

using BenchmarkTools

@benchmark count_missing($x)


@benchmark count_nonmissing($x)

