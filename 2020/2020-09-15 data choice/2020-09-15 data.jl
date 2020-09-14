using DataFrames
using DataFramesMacros
using DataConvenience: @>, filter # or using Lazy: @> but it exports groupby
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

delay = @> flights_tbl begin
    groupby(:tailnum)
    combine(nrow => :count, :distance => mean => :dist, :arr_delay => mean => :delay)
    @where( :count .> 20, :dist .< 2000, .!ismissing.(:delay))
end
