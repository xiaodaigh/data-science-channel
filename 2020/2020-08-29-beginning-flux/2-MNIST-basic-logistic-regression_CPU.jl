using Pkg
Pkg.activate("flux-tutorial")

using Flux

using Statistics
using Flux.Data: DataLoader
using Flux: onehotbatch, onecold, logitcrossentropy, throttle, @epochs
using Base.Iterators: repeated

using MLDatasets

model_cpu = Chain(
    Dense(28*28, 10)
)

model = model_cpu

# Loading Dataset
xtrain, ytrain = MLDatasets.MNIST.traindata(Float32)

# Reshape Data in order to flatten each image into a linear array
xtrain = Flux.flatten(xtrain)
#xtest = Flux.flatten(xtest)

# One-hot-encode the labels
ytrain_onehot = onehotbatch(ytrain, 0:9) |> collect .|> Float32

xtrain = Flux.flatten(xtrain)

using Flux.Optimise: Descent

opt = Descent()

function accuracy(x, y)
    predictions = model(x) |> softmax |> collect |> onecold .|> x->x-1
    mean(predictions .== y)
end

accuracy(xtrain, ytrain)

function callback_accuracy()
    @show accuracy(xtrain, ytrain)
end

function callback_loss()
    @show loss(xtrain, ytrain)
end


@time Flux.@epochs 100 Flux.train!(loss, p, [(xtrain, ytrain_onehot)], opt; cb = callback_accuracy)

