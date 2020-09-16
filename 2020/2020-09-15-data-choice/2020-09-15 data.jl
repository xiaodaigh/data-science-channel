# Recommendations for
# Data manipulation in Julia
using DataFrames
using DataFramesMeta
using DataConvenience
using Pipe


using Statistics: mean

using RCall

R"""
flights_tbl = nycflights13::flights

library(dplyr)

delay_r <- flights_tbl %>%
  group_by(tailnum) %>%
  summarise(count = n(), dist = mean(distance), delay = mean(arr_delay)) %>%
  filter(count > 20, dist < 2000, !is.na(delay)) %>%
  collect
"""

@rget flights_tbl delay_r

delay_r

# @> is from DataConvenience.jl reexporting Lazy.jl's @>
# groupby and combine are from DataFrames.jl
# @where is from DataFramesMeta.jl
delay = @> flights_tbl begin
    groupby(:tailnum)
    combine(nrow => :count, :distance => mean => :dist, :arr_delay => mean => :delay)
    @where( :count .> 20, :dist .< 2000, .!ismissing.(:delay))
end

using Pipe: @pipe
delay = @pipe flights_tbl  |>
    groupby(_, :tailnum) |>
    combine(_, nrow => :count, :distance => mean => :dist, :arr_delay => mean => :delay) |>
    @where(_, :count .> 20, :dist .< 2000, .!ismissing.(:delay))

# How do you pass results into NON-first place?
delay = @> flights_tbl begin
    groupby(:tailnum)
    combine(nrow => :count, :distance => mean => :dist, :arr_delay => mean => :delay)
    @where( :count .> 20, :dist .< 2000, .!ismissing.(:delay))
    x -> antijoin(some_other_df, x; on=some_keys)
end

# at some time in the future
delay = @pipe flights_tbl  |>
    groupby(_, :tailnum) |>
    @combine(_, count = nrow(_), dist = mean(:distance), delay = mean(:arr_delay)) |>
    @where(_, :count .> 20, :dist .< 2000, .!ismissing.(:delay))
