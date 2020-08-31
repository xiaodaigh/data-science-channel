reduce_nunique(a) = reduce(unique_count_reduce_inner, a; init = (1, a[1]))[1]

using ThreadsX
treduce_nunique(a) = ThreadsX.reduce(unique_count_reduce_inner, a; init = (1, a[1]))[1]

@time reduce_nunique(a) # 0.5
@time treduce_nunique(a) # 0.3