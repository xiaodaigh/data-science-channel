using Pkg
Pkg.activate("flux-tutorial")

using Flux

using RDatasets: dataset
using DataFrames

cars = dataset("datasets", "cars")

using Plots

scatter(cars.Speed, cars.Dist, ; xlab="Speed (km/h)", ylab="Stopping Distance", label="")

using GLM

linear_model = lm(@formula(Dist~Speed), cars)

# Linear algebra
m = Matrix(hcat(ones(nrow(cars)), cars.Speed))

beta = m\cars.Dist

using Statistics: mean
# Let's solve this using Flux
a = [0.0]
b = [0.0]
p = params(a, b)

optimizer = Flux.Optimise.Descent(1/10_000)
gs = gradient(()->loss(cars.Speed, cars.Dist), p)
print(p)
print(gs[p[1]], gs[p[2]])
Flux.update!(optimizer, p, gs)
print(p)

using Random: randperm

model(speed) = a[1] .+ b[1].*speed

function loss(speed, dist)
    mean((dist .- model(speed)).^2)
end

optimizer = Flux.Optimise.Descent(1/10_000)

function trainit(n, data)
    for j in 1:n
        Flux.train!(
            loss,
            p,
            data,
            optimizer
        )
    end
end

data = [(cars.Speed, cars.Dist)]

@time trainit(100_000, data)
println(loss(cars.Speed, cars.Dist))
println(p)

@time trainit(100_000, data)
println(loss(cars.Speed, cars.Dist))
println(p)

@time trainit(100_000, data)
println(loss(cars.Speed, cars.Dist))
println(p)

linear_model
