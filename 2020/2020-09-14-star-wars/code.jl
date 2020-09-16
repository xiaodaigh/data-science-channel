# waiting for @combine to be implemented in

using DataFrames
using DataFramesMeta
using DataConvenience: @>, filter, sample

using RCall

R"""
starwars = dplyr::starwars
"""

@rget starwars


# starwars %>% filter(skin_color == "light", eye_color == "brown")

filter(row->row.skin_color == "light" && row.eye_color == "brown", starwars)


filter(filter(starwars, :skin_color => ==("light")), :eye_color => ==("brown"))


filter(starwars, [:skin_color, :eye_color] => (sc, ec) -> (sc .== "light") .& (ec .== "brown"))

# faster
@> starwars begin
    @where(:skin_color .== "light",  :eye_color .== "brown")
end

# starwars %>% arrange(height, mass)
@> starwars @orderby(:height, :mass)

# starwars %>% arrange(desc(height))
@> starwars sort(order(:height, rev=true))

#starwars %>% slice(5:10)
@> starwars getindex(5:10, :)

#starwars %>% slice_head(n=3)
@> starwars first(3)

#starwars %>% slice_tail(n=3)
@> starwars last(3)

#starwars %>% slice_sample(n=5)
@> starwars sample(5)

# starwars %>% slice_sample(prop = 0.1)
@> starwars sample(0.1)

# starwars %>%
#   filter(!is.na(height)) %>%
#   slice_max(height, n = 3)

@> starwars begin
    @where .!ismissing.(:height)
    @where partialsortperm(:height, 1:3; rev=true)
end


#starwars %>% select(hair_color, skin_color, eye_color)
@> starwars select(:hair_color, :skin_color, :eye_color)


# starwars %>% select(hair_color:eye_color)
@> starwars select(Between(:hair_color, :eye_color))


# starwars %>% select(!(hair_color:eye_color))
@> starwars select(Not(Between(:hair_color, :eye_color)))


#starwars %>% select(ends_with("color"))
@> starwars select(r"color$")

n = filter(endswith("color"), names(starwars))
@> starwars select(n)

# starwars %>% select(home_world = homeworld)
@> starwars select(:homeworld => :home_world)

# using DataFramesMeta.@select
@> starwars @select(home_world = :homeworld)


# starwars %>% rename(home_world = homeworld)
@> starwars rename(:homeworld => :home_world)

# starwars %>% mutate(height_m = height / 100)
@> starwars transform(:height => h -> h ./100 => :height_m)

# using DataFramesMeta.jl
@> starwars @transform(height_m = :height ./ 100)

# starwars %>%
#   mutate(height_m = height / 100) %>%
#   select(height_m, height, everything())
@> starwars begin
    @transform(height_m = :height ./ 100)
    select(:height_m, :height, :)
end

# starwars %>%
#   mutate(
#     height_m = height / 100,
#     BMI = mass / (height_m^2)
#   ) %>%
#   select(BMI, everything())
@> starwars begin
    @transform(height_m = :height ./ 100)
    @transform(BMI = :mass ./ (:height_m.^2))
    select(:BMI, :)
end

# starwars %>%
#   transmute(
#     height_m = height / 100,
#     BMI = mass / (height_m^2)
#   )
@> starwars begin
    @transform(height_m = :height ./ 100)
    @transform(BMI = :mass ./ (:height_m .^ 2))
    select!(:height_m, :BMI)
end

# starwars %>% relocate(sex:homeworld, .before = height)
@> starwars select(1:columnindex(starwars, :height)-1, Between(:sex, :homeworld), :)

# starwars %>% summarise(height = mean(height, na.rm = TRUE))
using Statistics: mean
@> starwars combine(:height => mean ∘ skipmissing => :height)

using PairAsPipe
@> starwars combine(@pap mean(:height |> skipmissing))
@> starwars combine(@pap mean(skipmissing(:height)))
@> starwars combine(@pap (mean∘skipmissing)(:height))

# starwars %>%
#   group_by(species, sex) %>%
#   select(height, mass) %>%
#   summarise(
#     height = mean(height, na.rm = TRUE),
#     mass = mean(mass, na.rm = TRUE)
#   )
@> starwars begin
    groupby([:species, :sex])
    select(:height, :mass)
    combine(
        :height => mean∘skipmissing => :height,
        :mass => mean ∘ skipmissing => :mass
    )
end


# select(starwars, name)
# select(starwars, 1)
select(starwars, :name)
select(starwars, 1)

# height <- 5
# select(starwars, height) # still refers to heigh not column 5
height = 5
select(starwars, height)
select(starwars, :height)


# name <- "color"
# select(starwars, ends_with(name))
name = "color"
n = filter(endswith(name), names(starwars))
select(starwars, n)


# name <- 5
# select(starwars, name, identity(name))
name = 5
select(starwars, :name, name)

# vars <- c("name", "height")
# select(starwars, all_of(vars), "mass")

vars = ["name", "height"]
select(starwars, vars, "mass")

# df <- starwars %>% select(name, height, mass)
df = @> starwars select(:name, :height, :mass)

# mutate(df, "height", 2)
@> df begin
    @transform(col1 = fill("height", nrow(df)), col2 = fill(2, nrow(df)))
    rename!(:col1 => "\"height\"", :col2 => "2")
end

@> df begin
    x -> (x.col1 = "height"; x)
    x -> (x.col2 = 2; x)
    rename(:col1 => "\"height\"", :col2 => "2")
end


# mutate(df, height + 10)
transform(df, :height => h -> h .+ 10)
@> @transform(df, tmp = :height .+ 10) rename(:tmp => ":height .+ 10")


# var <- seq(1, nrow(df))
# mutate(df, new = var)
var = 1:nrow(df)
@transform(df, new = var)

transform(df, [] => (() -> var) => :new)
setindex!(df, var, :new)

#group_by(starwars, sex)
groupby(starwars, :sex)


#group_by(starwars, sex = as.factor(sex))
@> starwars begin
    @transform(sex = categorical(:sex))
    groupby(:sex)
end


# group_by(starwars, height_binned = cut(height, 3))

if false
    # Ideally, but the `cut`
    using CategoricalArrays: cut
    @> starwars begin
        @transform(height_binned = cut(:height, 3; allowmissing=true))
        #groupby(:height_binned)
    end
end

# define a function ourselves
function cut_allow_missing(arr::AbstractArray{Union{Missing, T}, N}, ngroups::Integer) where {T, N}
    pos_missing = findall(ismissing, arr)
    pos_nonmissing = findall(elem->!ismissing(elem), arr)

    tmp = cut(@view(arr[pos_nonmissing]), 3)

    res = vcat(tmp, [missing for i in 1:length(pos_missing)])

    res[pos_nonmissing] .= tmp
    res[pos_missing] .= missing

    res
end

@> starwars begin
    @transform(height_binned = cut_allow_missing(:height, 3))
    groupby(:height_binned)
end


# group_by(df, "month")
groupby(@transform(df, month = fill("month", nrow(df))), "month")
